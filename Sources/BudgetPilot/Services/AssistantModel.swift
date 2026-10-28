import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Observation
import os
import SwiftData
import Tokenizers

enum AssistantError: LocalizedError {
    case simulatorUnsupported
    case notEnoughMemory

    var errorDescription: String? {
        switch self {
        case .simulatorUnsupported:
            "The on-device assistant needs a physical device; MLX doesn't run in the Simulator."
        case .notEnoughMemory:
            "Not enough free memory to load the assistant. Close other apps and try again."
        }
    }
}

/// On-device budget assistant. Loads Gemma 4 with MLX when the app starts
/// and keeps one ChatSession across messages, so the model sees earlier turns.
/// Call `reset()` to start a new conversation without reloading the model.
@Observable
@MainActor
final class AssistantModel {
    private var container: MLXLMCommon.ModelContainer?
    private var session: ChatSession?
    /// The last tool calls and the app's replies to them, sent as tool
    /// results ahead of the next message, so the model knows what happened.
    private var pendingToolResults: [(tool: String, reply: String)] = []
    private let incomeData: IncomeData

    /// Download and load progress from 0 to 1, shown while the app starts.
    private(set) var loadProgress: Double = 0

    /// Free memory needed to load E2B. Loading peaks at about 3.64 GB on the Mac.
    private let requiredMemory = 3_800_000_000

    init(incomeData: IncomeData = IncomeData()) {
        self.incomeData = incomeData
    }

    /// Whether the model is in memory. Until then the first reply has to
    /// download and load several GB, which takes minutes.
    var isLoaded: Bool {
        container != nil
    }

    /// Starts a new conversation. The loaded model is kept.
    func reset() {
        session = nil
        pendingToolResults = []
    }

    /// Whether there's enough free memory to load the model. 0 means there's
    /// no per-app limit, e.g. on the Mac.
    nonisolated static func hasEnoughMemory(available: Int, required: Int) -> Bool {
        available == 0 || available >= required
    }

    /// Downloads and loads the model. Does nothing if it's already loaded.
    func load() async throws {
        #if targetEnvironment(simulator)
            // MLX aborts in the Simulator: its Metal device has no
            // architecture name. Fail before downloading the model.
            throw AssistantError.simulatorUnsupported
        #else
            guard container == nil else { return }
            // Running out of memory kills the app instead of throwing, so check first.
            let availableMemory = os_proc_available_memory()
            if !Self.hasEnoughMemory(available: availableMemory, required: requiredMemory) {
                throw AssistantError.notEnoughMemory
            }
            container = try await #huggingFaceLoadModelContainer(
                configuration: LLMRegistry.gemma4_e2b_it_4bit,
                progressHandler: { progress in
                    Task { @MainActor in
                        self.loadProgress = progress.fractionCompleted
                    }
                }
            )
        #endif
    }

    func respond(to text: String, in context: SwiftData.ModelContext) async throws -> [ChatMessage] {
        #if targetEnvironment(simulator)
            // MLX aborts in the Simulator: its Metal device has no
            // architecture name. Fail before downloading the model.
            throw AssistantError.simulatorUnsupported
        #else
            let session = try await currentSession()

            let stream = if pendingToolResults.isEmpty {
                session.streamDetails(to: text)
            } else {
                session.streamDetails(to: pendingToolResults.map { .tool($0.reply, name: $0.tool) } + [.user(text)])
            }
            pendingToolResults = []

            var answer = ""
            var calls: [(name: String, arguments: [String: Any])] = []
            // No toolDispatch: the calls come back to us instead of being run.
            // Read to the end: stopping early makes ChatSession drop the turn,
            // and the model then can't tell what "the lunch" refers to.
            for try await generation in stream {
                if let call = generation.toolCall {
                    calls.append((call.function.name, call.function.arguments.mapValues(\.anyValue)))
                } else if calls.isEmpty {
                    answer += generation.chunk ?? ""
                }
            }
            if calls.isEmpty, let written = WrittenToolCall(answer) {
                return try [reply(toCall: written.name, arguments: written.arguments, from: text, in: context)]
            }
            guard !calls.isEmpty else { return [Self.reply(answer)] }

            // "Coop 30 and SBB 12" comes as two calls: one proposal each.
            return try calls.map { call in
                let message = try reply(toCall: call.name, arguments: call.arguments, from: text, in: context)
                pendingToolResults.append((call.name, message.text))
                return message
            }
        #endif
    }

    /// Checks a call against the user's message, then handles it, or asks
    /// the user when the app won't act on it.
    func reply(
        toCall name: String, arguments: [String: Any], from text: String, in context: SwiftData.ModelContext
    ) throws -> ChatMessage {
        switch BudgetIntent.checked(name: name, arguments: arguments, message: text) {
        case let .success(intent): try handle(intent, in: context)
        case let .failure(rejection): Self.reply(rejection.question)
        }
    }

    /// Runs what can run right away and replies with text written by the
    /// app from checked values, never by the model. Expenses and edits come
    /// back as a proposal on the message and run only when the user confirms.
    func handle(_ intent: BudgetIntent, in context: SwiftData.ModelContext) throws -> ChatMessage {
        switch intent {
        case let .addExpense(title, amount, category):
            return ChatMessage(
                text: "Add: \(title), CHF \(amount), \(category.title)?",
                isFromUser: false,
                proposal: .add(ProposedExpense(title: title, amount: amount, category: category))
            )
        case let .setIncome(amount):
            incomeData.monthlyIncome = amount
            return Self.reply("Saved your monthly income: CHF \(amount).")
        case .getIncome:
            if let income = incomeData.monthlyIncome {
                return Self.reply("Your monthly income is CHF \(income).")
            }
            return Self.reply("I don't know your monthly income yet. How much is it?")
        case let .editExpense(match, title, amount, category):
            return try proposeEdit(of: match, title: title, amount: amount, category: category, in: context)
        // The model understands these already (issue 57); the app can't act on them yet.
        case .deleteExpense:
            return Self.reply("I can't delete expenses yet.")
        case .setFixedCosts:
            return Self.reply("I can't save fixed costs yet.")
        case .getBudget:
            return Self.reply("I can't show what is left yet.")
        }
    }

    // MARK: - Private

    /// Creates the session on the first message, then reuses it.
    private func currentSession() async throws -> ChatSession {
        if let session {
            return session
        }

        try await load()

        let session = ChatSession(
            container!,
            instructions: AssistantSetup.instructions,
            generateParameters: AssistantSetup.parameters,
            additionalContext: AssistantSetup.additionalContext,
            tools: BudgetIntent.tools
        )
        self.session = session
        return session
    }

    /// Finds the newest expense matching the user's words and proposes the change.
    private func proposeEdit(
        of match: String, title: String?, amount: Decimal?, category: ExpenseCategory?,
        in context: SwiftData.ModelContext
    ) throws -> ChatMessage {
        guard let expense = try latestExpense(matching: match, in: context) else {
            return Self.reply("I couldn't find an expense called \"\(match)\".")
        }
        var changes: [String] = []
        if let title {
            changes.append("\(expense.title) → \(title)")
        }
        if let amount {
            changes.append("CHF \(expense.amount) → CHF \(amount)")
        }
        if let category {
            changes.append("\(expense.category.title) → \(category.title)")
        }
        let day = expense.date.formatted(.dateTime.day().month())
        return ChatMessage(
            text: "Change \(expense.title) (\(day)): \(changes.joined(separator: ", "))?",
            isFromUser: false,
            proposal: .edit(ExpenseEdit(
                expenseID: expense.persistentModelID, title: title, amount: amount, category: category
            ))
        )
    }

    private func latestExpense(matching match: String, in context: SwiftData.ModelContext) throws -> Expense? {
        let descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        // Either way round, so "cinema tickets" also finds "Cinema" and
        // "Coop Einkauf" finds "Coop": the model often keeps extra words.
        return try context.fetch(descriptor).first {
            $0.title.localizedStandardContains(match) || match.localizedStandardContains($0.title)
        }
    }

    private static func reply(_ text: String) -> ChatMessage {
        ChatMessage(text: text, isFromUser: false)
    }
}
