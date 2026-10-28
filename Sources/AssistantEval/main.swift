import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

// Scores the assistant's prompt and tools against Gemma 4 E2B on this Mac's
// GPU, the way AssistantModel.respond reads the model: every tool call in the
// reply, or one written as text, checked by BudgetIntent.checked.
//
//   AssistantEval [--config overrides.json] [--runs N] [--only id,id] [--out transcripts.jsonl]
//   AssistantEval --chat [--config overrides.json]   one message per stdin line, /reset starts over
//   AssistantEval --dump-config    prints what the app ships, as a starting point for overrides

struct Overrides: Decodable {
    var instructions: String?
    var maxTokens: Int?
    var maxKVSize: Int?
    var temperature: Float?
    var topP: Float?
    var topK: Int?
    var enableThinking: Bool?
}

struct Call: Encodable {
    var name: String
    var arguments: [String: String]
    /// Written into the reply as text instead of made as a call.
    var written = false
}

struct Turn: Encodable {
    var message: String
    var calls: [Call] = []
    var reply: String
    var seconds: Double

    /// The first call is the one the scored cases look at.
    var tool: String? {
        calls.first?.name
    }

    var arguments: [String: String]? {
        calls.first?.arguments
    }
}

struct Transcript: Encodable {
    var id: String
    var run: Int
    var passed: Bool
    var problems: [String]
    var turns: [Turn]
}

func option(_ name: String) -> String? {
    let arguments = CommandLine.arguments
    guard let index = arguments.firstIndex(of: name), index + 1 < arguments.count else { return nil }
    return arguments[index + 1]
}

/// JSON gives Foundation types; ToolSpec wants Sendable Swift values.
func sendable(_ value: Any) -> any Sendable {
    switch value {
    case let dictionary as [String: Any]: dictionary.mapValues(sendable)
    case let array as [Any]: array.map(sendable)
    case let number as NSNumber where CFGetTypeID(number) == CFBooleanGetTypeID(): number.boolValue
    case let number as NSNumber: number.doubleValue
    case let string as String: string
    default: "\(value)"
    }
}

func replyProblems(with turn: Turn) -> [String] {
    var found: [String] = []
    // A call the app rejects ends in the app asking, which is fine here.
    for call in turn.calls where verdict(on: call, in: turn.message) == nil {
        found.append("called \(call.name), expected a reply")
    }
    if turn.tool == nil, turn.reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        found.append("empty reply")
    }
    if turn.reply.contains("<channel|>") {
        found.append("thinking leaked into the reply")
    }
    return found
}

func problems(with turn: Turn, expected: Expected) -> [String] {
    switch expected {
    case .reply:
        return replyProblems(with: turn)
    case let .calls(names):
        let got = turn.calls.map(\.name)
        return got == names ? [] : ["called \(got), expected \(names)"]
    case let .call(name, checks):
        guard turn.tool == name else { return ["called \(turn.tool ?? "nothing"), expected \(name)"] }
        let arguments = turn.arguments ?? [:]
        var found: [String] = []
        for (key, want) in checks.sorted(by: { $0.key < $1.key }) {
            let got = arguments[key]?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
            let options = want.split(separator: "|").map { String($0) }
            let good = switch key {
            case "amount": Double(got) != nil && Double(got) == Double(want)
            case "title", "new_title": options.contains { got.contains($0) }
            default: options.contains(got)
            }
            if !good {
                found.append("\(key)=\"\(got)\", expected \(want)")
            }
        }
        return found
    }
}

if CommandLine.arguments.contains("--dump-config") {
    let config: [String: Any] = [
        "instructions": AssistantSetup.instructions,
        "maxTokens": AssistantSetup.parameters.maxTokens ?? 0,
        "maxKVSize": AssistantSetup.parameters.maxKVSize ?? 0,
        "temperature": AssistantSetup.parameters.temperature,
        "topP": AssistantSetup.parameters.topP,
        "topK": AssistantSetup.parameters.topK,
        "enableThinking": AssistantSetup.additionalContext["enable_thinking"] as? Bool ?? false,
        "tools": BudgetIntent.tools,
    ]
    let data = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
    print(String(data: data, encoding: .utf8) ?? "")
    exit(0)
}

var overrides = Overrides()
var tools = BudgetIntent.tools
if let path = option("--config") {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    overrides = try JSONDecoder().decode(Overrides.self, from: data)
    // Tool schemas may be overridden too, to try other descriptions. The app
    // still reads the calls with BudgetIntent, so names and arguments stay.
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    if let custom = json?["tools"] as? [[String: Any]] {
        tools = custom.map { $0.mapValues(sendable) }
    }
}

let shipped = AssistantSetup.parameters
let parameters = GenerateParameters(
    maxTokens: overrides.maxTokens ?? shipped.maxTokens,
    maxKVSize: overrides.maxKVSize ?? shipped.maxKVSize,
    temperature: overrides.temperature ?? shipped.temperature,
    topP: overrides.topP ?? shipped.topP,
    topK: overrides.topK ?? shipped.topK
)
let instructions = overrides.instructions ?? AssistantSetup.instructions
var context = AssistantSetup.additionalContext
if let thinking = overrides.enableThinking {
    context["enable_thinking"] = thinking
}

let runs = option("--runs").flatMap(Int.init) ?? 1
let only = option("--only").map { Set($0.split(separator: ",").map(String.init)) }
let selected = cases.filter { only?.contains($0.id) ?? true }

var output: FileHandle?
if let path = option("--out") {
    FileManager.default.createFile(atPath: path, contents: nil)
    output = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
}

let encoder = JSONEncoder()
encoder.outputFormatting = .sortedKeys

let container = try await #huggingFaceLoadModelContainer(configuration: LLMRegistry.gemma4_e2b_it_4bit)

/// The last tool calls and the app's replies to them, sent ahead of the next
/// message the way AssistantModel does.
var pendingResults: [(outcome: String, tool: String)] = []

@MainActor
func newSession() -> ChatSession {
    pendingResults = []
    return ChatSession(
        container, instructions: instructions, generateParameters: parameters, additionalContext: context, tools: tools
    )
}

@MainActor
func send(_ message: String, to session: ChatSession) async throws -> Turn {
    let start = Date()
    var turn = Turn(message: message, reply: "", seconds: 0)
    let stream = if pendingResults.isEmpty {
        session.streamDetails(to: message)
    } else {
        session.streamDetails(to: pendingResults.map { .tool($0.outcome, name: $0.tool) } + [.user(message)])
    }
    pendingResults = []
    for try await generation in stream {
        if let call = generation.toolCall {
            turn.calls.append(Call(name: call.function.name, arguments: call.function.arguments.mapValues {
                "\($0.anyValue)"
            }))
        } else if turn.calls.isEmpty {
            turn.reply += generation.chunk ?? ""
        }
    }
    turn.seconds = Date().timeIntervalSince(start)
    if turn.calls.isEmpty, let written = WrittenToolCall(turn.reply) {
        turn.calls = [Call(name: written.name, arguments: written.arguments.mapValues { "\($0)" }, written: true)]
    } else {
        pendingResults = turn.calls.map { (appReply(to: $0, in: message), $0.name) }
    }
    return turn
}

func checked(_ call: Call, in message: String) -> Result<BudgetIntent, CallRejection> {
    let arguments = call.arguments.mapValues { Double($0) ?? $0 as Any }
    return BudgetIntent.checked(name: call.name, arguments: arguments, message: message)
}

/// Roughly what AssistantModel replies, with no saved data to look at.
func appReply(to call: Call, in message: String) -> String {
    switch checked(call, in: message) {
    case let .failure(rejection): rejection.question
    case let .success(.addExpense(title, amount, category)): "Add: \(title), CHF \(amount), \(category.title)?"
    case let .success(.setIncome(amount)): "Saved your monthly income: CHF \(amount)."
    case .success(.getIncome): "I don't know your monthly income yet. How much is it?"
    case let .success(.editExpense(match, _, _, _)): "Change \(match)?"
    case .success(.deleteExpense): "I can't delete expenses yet."
    case .success(.setFixedCosts): "I can't save fixed costs yet."
    case .success(.getBudget): "I can't show what is left yet."
    }
}

/// Why the app won't act on a call, or nil if it does.
func verdict(on call: Call, in message: String) -> String? {
    if case let .failure(rejection) = checked(call, in: message) {
        "app rejects: \(rejection)"
    } else {
        nil
    }
}

if CommandLine.arguments.contains("--chat") {
    var session = newSession()
    while let line = readLine() {
        let message = line.trimmingCharacters(in: .whitespaces)
        if message.isEmpty {
            continue
        }
        if message == "/reset" {
            session = newSession()
            print("--- new conversation")
            continue
        }
        let turn = try await send(message, to: session)
        print("> \(message)")
        for call in turn.calls {
            let written = call.written ? " (written as text)" : ""
            let outcome = verdict(on: call, in: message) ?? "app accepts"
            print("  tool \(call.name) \(call.arguments)\(written)  [\(outcome)]")
        }
        if turn.calls.isEmpty {
            print("  reply \(turn.reply.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        print("  (\(String(format: "%.1f", turn.seconds))s)")
        fflush(stdout)
    }
    exit(0)
}

var passed = 0
for run in 1 ... runs {
    for item in selected {
        // A fresh session per case, like a new conversation in the app.
        let session = newSession()
        var turns: [Turn] = []
        for message in item.turns {
            try await turns.append(send(message, to: session))
        }

        let last = turns[turns.count - 1]
        var found = problems(with: last, expected: item.expected)
        switch item.expected {
        case .reply: break
        case .call, .calls:
            if found.isEmpty {
                found += last.calls.compactMap { verdict(on: $0, in: last.message) }
            }
        }
        if found.isEmpty {
            passed += 1
        }

        let seconds = turns.map(\.seconds).reduce(0, +)
        let shown = last.calls.isEmpty
            ? String(last.reply.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
            : last.calls.map { "\($0.name) \($0.arguments)" }.joined(separator: " + ")
        let mark = found.isEmpty ? "PASS" : "FAIL"
        let paddedID = item.id.padding(toLength: 14, withPad: " ", startingAt: 0)
        print("\(mark) \(paddedID) \(String(format: "%4.1f", seconds))s  \(found.joined(separator: "; "))  | \(shown)")

        let transcript = Transcript(id: item.id, run: run, passed: found.isEmpty, problems: found, turns: turns)
        try output?.write(contentsOf: encoder.encode(transcript) + Data("\n".utf8))
    }
}

try output?.close()

let total = selected.count * runs
print("\n\(passed)/\(total) passed")
exit(passed == total ? 0 : 1)
