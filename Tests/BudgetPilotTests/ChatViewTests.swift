@testable import BudgetPilot
import Testing

struct ChatViewTests {
    /// Smoke test: body has to build without trapping. Asserting on rendered
    /// output would need snapshot testing, which the project does not have yet.
    @Test
    func chatViewBuilds() {
        _ = ChatView().body
    }

    @Test
    func bodyContainsAppBackground() {
        let view = ChatView()
        let typeName = String(describing: type(of: view.body))
        #expect(typeName.contains("AppBackground"))
    }
}
