import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// On-device budget assistant. Loads Gemma 4 with MLX on the first message
/// and keeps one chat session, so later replies remember the conversation.
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
    - Every expense has exactly one of these categories:
      - housing: rent, utilities, electricity, internet, furniture
      - groceries: supermarket, bakery, coffee and snacks
      - transport: public transport tickets and passes (GA, Halbtax), fuel, taxi, parking
      - leisure: hobbies, going out, restaurants, sports, electronics, travel
      - health: doctor, dentist, pharmacy, health insurance
      - subscriptions: streaming, apps, software, memberships
      - other: anything that fits none of the above
    - Choose the category by what the money is for, not by how often it is paid.
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
