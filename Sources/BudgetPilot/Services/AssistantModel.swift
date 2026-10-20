import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// On-device budget assistant. Loads Gemma 4 with MLX on the first message
/// and keeps one ChatSession across messages, so the model sees earlier turns.
/// Call `reset()` to start a new conversation without reloading the model.
@MainActor
final class AssistantModel {
    private var container: ModelContainer?
    private var session: ChatSession?
    private let incomeData: IncomeData

    private let instructions = """
    You are the budget assistant in the BudgetPilot app.
    When the user tells you about something they bought, call add_expense.
    When the user tells you their monthly income or salary, call set_income.
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

    /// Starts a new conversation. The loaded model is kept.
    func reset() {
        session = nil
    }

    func respond(to text: String) async throws -> String {
        let session = try await currentSession()

        var reply = ""
        // No toolDispatch: the call comes back to us instead of being run.
        for try await generation in session.streamDetails(to: text) {
            if let call = generation.toolCall {
                let arguments = call.function.arguments.mapValues(\.anyValue)
                guard let intent = BudgetIntent(name: call.function.name, arguments: arguments),
                      intent.isBacked(by: text)
                else { return "Sorry, I could not read the amount. How much was it?" }
                return handle(intent)
            }
            reply += generation.chunk ?? ""
        }
        return reply
    }

    /// Runs what can run right away and replies with text written by the
    /// app from checked values, never by the model.
    func handle(_ intent: BudgetIntent) -> String {
        switch intent {
        case let .addExpense(title, amount, category):
            return "Add: \(title), CHF \(amount), \(category.title)? (not saved yet)"
        case let .setIncome(amount):
            incomeData.monthlyIncome = amount
            return "Saved your monthly income: CHF \(amount)."
        }
    }

    // MARK: - Private

    /// Creates the session on the first message, then reuses it.
    private func currentSession() async throws -> ChatSession {
        if let session {
            return session
        }

        if container == nil {
            container = try await #huggingFaceLoadModelContainer(
                configuration: LLMRegistry.gemma4_e2b_it_4bit
            )
        }

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
}
