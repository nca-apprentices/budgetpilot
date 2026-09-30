@testable import BudgetPilot
import SwiftUI
import XCTest

final class ChatViewTests: XCTestCase {
    func testChatViewHasBody() {
        let view = ChatView()
        XCTAssertNotNil(view.body)
    }
}
