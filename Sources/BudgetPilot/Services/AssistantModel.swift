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
    private let incomeData: IncomeData

    /// Download and load progress from 0 to 1, shown while the app starts.
    private(set) var loadProgress: Double = 0

    /// Free memory needed to load E2B. Loading peaks at about 3.64 GB on the Mac.
    private let requiredMemory = 3_800_000_000

    private let instructions = """
    You are the budget assistant in the BudgetPilot app.
    When the user tells you about something they bought, call add_expense.
    When the user tells you their monthly income or salary, call set_income.
    When the user asks what their income is, call get_income.
    When the user wants to change an expense they saved, call edit_expense.
    Only use amounts the user wrote. If the amount is missing, ask for it.
    Otherwise answer briefly, in the language the user writes in. The currency is CHF.
    """

    private let parameters = GenerateParameters(
        maxTokens: 256, // short replies, stops runaway output
        maxKVSize: 4096, // caps how much history is kept on device
        temperature: 0.2, // steadier tool-call arguments
        topP: 0.95,
        topK: 64
    )

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

    func respond(to text: String, in context: SwiftData.ModelContext) async throws -> ChatMessage {
        #if targetEnvironment(simulator)
            // MLX aborts in the Simulator: its Metal device has no
            // architecture name. Fail before downloading the model.
            throw AssistantError.simulatorUnsupported
        #else
            let session = try await currentSession()

            var reply = ""
            // No toolDispatch: the call comes back to us instead of being run.
            for try await generation in session.streamDetails(to: text) {
                if let call = generation.toolCall {
                    let arguments = call.function.arguments.mapValues(\.anyValue)
                    guard let intent = BudgetIntent(name: call.function.name, arguments: arguments),
                          intent.isBacked(by: text)
                    else { return Self.reply("Sorry, I could not read the amount. How much was it?") }
                    return try handle(intent, in: context)
                }
                reply += generation.chunk ?? ""
            }
            return Self.reply(reply)
        #endif
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
            instructions: instructions,
            generateParameters: parameters,
            additionalContext: ["enable_thinking": true],
            tools: BudgetIntent.tools
        )
        self.session = session
        return session
    }

    private func latestExpense(matching match: String, in context: SwiftData.ModelContext) throws -> Expense? {
        let descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(descriptor).first { $0.title.localizedStandardContains(match) }
    }

    private static func reply(_ text: String) -> ChatMessage {
        ChatMessage(text: text, isFromUser: false)
    }
}
