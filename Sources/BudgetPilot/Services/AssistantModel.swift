import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

final class AssistantModel {
    private var session: ChatSession?
    private let instructions = """
    You are the budget assistant in the BudgetPilot app.
    Help the user track expenses and understand their budget.

    Rules:
    - Answer briefly, in the language the user writes in.
    - The currency is CHF.
    - Only use amounts the user wrote. Never invent or estimate numbers.
    - If the amount is missing, ask for it.
    - Every expense has one of these categories: housing, groceries,
      transport, leisure, health, subscriptions, other
    """
    func respond(to text: String) async throws -> String {
        if session == nil {
            let container = try await #huggingFaceLoadModelContainer(
                configuration: LLMRegistry.gemma4_e2b_it_4bit
            )
            session = ChatSession(container, instructions: instructions)
        }
        return try await session!.respond(to: text)
    }
}
