@testable import BudgetPilot
import Foundation
import SwiftData
import Testing

struct DeletedExpenseTests {
    @Test
    func restoresAllValues() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Expense.self, configurations: config)
        let context = ModelContext(container)

        let date = Date.now
        let expense = Expense(
            title: "Halbtax",
            amount: 190,
            category: .transport,
            date: date,
            paymentMethod: .card,
            note: "Via chat"
        )
        context.insert(expense)
        try context.save()

        let deleted = DeletedExpense(expense)
        context.delete(expense)
        try context.save()

        deleted.restore(in: context)
        try context.save()

        let expenses = try context.fetch(FetchDescriptor<Expense>())
        let restored = expenses.first

        #expect(expenses.count == 1)
        #expect(restored?.title == "Halbtax")
        #expect(restored?.amount == 190)
        #expect(restored?.category == .transport)
        #expect(restored?.date == date)
        #expect(restored?.paymentMethod == .card)
        #expect(restored?.note == "Via chat")
    }

    @Test
    func restoresWithoutOptionalValues() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Expense.self, configurations: config)
        let context = ModelContext(container)

        let date = Date.now
        let expense = Expense(
            title: "Halbtax",
            amount: 190,
            category: .transport,
            date: date
        )
        context.insert(expense)
        try context.save()

        let deleted = DeletedExpense(expense)
        context.delete(expense)
        try context.save()

        deleted.restore(in: context)
        try context.save()

        let expenses = try context.fetch(FetchDescriptor<Expense>())
        let restored = expenses.first

        #expect(expenses.count == 1)
        #expect(restored?.title == "Halbtax")
        #expect(restored?.amount == 190)
        #expect(restored?.category == .transport)
        #expect(restored?.date == date)
        #expect(restored?.paymentMethod == nil)
        #expect(restored?.note == nil)
    }
}
