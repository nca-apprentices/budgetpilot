import SwiftData
import SwiftUI

@main
struct BudgetPilotApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
        }.modelContainer(for: Expense.self)
    }
}
