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

        /// Loading at app start has to refuse in the Simulator too, before
        /// anything is downloaded.
        @MainActor
        @Test
        func loadThrowsInSimulator() async {
            let model = AssistantModel()
            await #expect(throws: AssistantError.simulatorUnsupported) {
                try await model.load()
            }
            #expect(!model.isLoaded)
            #expect(model.loadProgress == 0)
        }
    #endif
}
