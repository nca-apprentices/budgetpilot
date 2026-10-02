@testable import BudgetPilot
import Testing

struct ChatViewTests {
    @Test
    func bodyRendersAppBackground() {
        let view = ChatView()
        #expect(type(of: view.body) == AppBackground.self)
    }
}
