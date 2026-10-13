@testable import BudgetPilot
import Foundation
import SwiftData
import Testing

struct ExpenseTests {
    @Test
    func savesAndReadsAnExpense() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Expense.self, configurations: config)
        let context = ModelContext(container)

        let expense = Expense(title: "Halbtax", amount: 190, category: .transport, date: .now)
        context.insert(expense)
        try context.save()

        let expenses = try context.fetch(FetchDescriptor<Expense>())

        #expect(expenses.count == 1)
        #expect(expenses.first?.title == "Halbtax")
        #expect(expenses.first?.amount == 190)
        #expect(expenses.first?.category == .transport)
    }
}
