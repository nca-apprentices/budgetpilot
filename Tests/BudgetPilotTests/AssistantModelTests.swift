@testable import BudgetPilot
import Testing

struct AssistantModelTests {
    #if targetEnvironment(simulator)
        /// MLX crashes in the Simulator, so the model has to refuse up front
        /// instead of downloading and loading it.
        @MainActor
        @Test
        func respondThrowsInSimulator() async {
            let model = AssistantModel()
            await #expect(throws: AssistantError.simulatorUnsupported) {
                try await model.respond(to: "Hi")
            }
            #expect(!model.isLoaded)
        }
    #endif
}
