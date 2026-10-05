@testable import BudgetPilot
import Testing

struct ChatViewTests {
    @Test
    func bodyContainsAppBackground() {
        let view = ChatView()
        let typeName = String(describing: type(of: view.body))
        #expect(typeName.contains("AppBackground"))
    }
}
