import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

final class AssistantModel {
    private var session: ChatSession?

    func respond(to text: String) async throws -> String {
        if session == nil {
            let container = try await #huggingFaceLoadModelContainer(
                configuration: LLMRegistry.gemma4_e2b_it_4bit
            )
            session = ChatSession(container)
        }
        return try await session!.respond(to: text)
    }
}
