@testable import BudgetPilot
import SwiftUI
import XCTest

final class ContentViewTests: XCTestCase {
    func testContentViewHasBody() {
        let view = ContentView()
        XCTAssertNotNil(view.body)
    }
}
