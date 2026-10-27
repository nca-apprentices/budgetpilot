@testable import BudgetPilot
import SwiftData
import Testing

struct AssistantModelTests {
    #if targetEnvironment(simulator)
        /// MLX crashes in the Simulator, so the model has to refuse up front
        /// instead of downloading and loading it.
        @MainActor
        @Test
        func respondThrowsInSimulator() async throws {
            let model = AssistantModel()
            let container = try ModelContainer(
                for: Expense.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            await #expect(throws: AssistantError.simulatorUnsupported) {
                try await model.respond(to: "Hi", in: container.mainContext)
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

    /// On the Mac there's no per-app limit, so loading is always allowed.
    @Test
    func hasEnoughMemoryWithoutLimit() {
        #expect(AssistantModel.hasEnoughMemory(available: 0, required: 3_800_000_000))
    }

    /// With more free memory than the model needs, loading goes ahead.
    @Test
    func hasEnoughMemoryWithEnoughFree() {
        #expect(AssistantModel.hasEnoughMemory(available: 5_000_000_000, required: 3_800_000_000))
    }

    /// With too little free memory, loading is refused instead of crashing.
    @Test
    func hasEnoughMemoryWithTooLittleFree() {
        #expect(!AssistantModel.hasEnoughMemory(available: 2_000_000_000, required: 3_800_000_000))
    }
}
