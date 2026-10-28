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

    @Test
    func readsAnExpenseAfterRestart() throws {
        let url = URL.temporaryDirectory.appending(path: "\(UUID()).store")
        let config = ModelConfiguration(url: url)

        let container = try ModelContainer(for: Expense.self, configurations: config)
        let context = ModelContext(container)

        let expense = Expense(title: "Halbtax", amount: 190, category: .transport, date: .now)
        context.insert(expense)
        try context.save()

        let container2 = try ModelContainer(for: Expense.self, configurations: config)
        let context2 = ModelContext(container2)

        let expenses = try context2.fetch(FetchDescriptor<Expense>())

        #expect(expenses.count == 1)
        #expect(expenses.first?.title == "Halbtax")
        #expect(expenses.first?.amount == 190)
        #expect(expenses.first?.category == .transport)
    }

    @Test
    func savesAProposedExpense() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Expense.self, configurations: config)
        let context = ModelContext(container)
        let date = Date(timeIntervalSince1970: 1_800_000_000)

        try ProposedExpense(title: "Halbtax", amount: 190, category: .transport).save(in: context, date: date)

        let expenses = try context.fetch(FetchDescriptor<Expense>())
        #expect(expenses.count == 1)
        #expect(expenses.first?.title == "Halbtax")
        #expect(expenses.first?.amount == 190)
        #expect(expenses.first?.category == .transport)
        #expect(expenses.first?.date == date)
        #expect(expenses.first?.isCorrected == false)
    }

    @Test
    func appliesAnEdit() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Expense.self, configurations: config)
        let context = ModelContext(container)
        let expense = Expense(title: "Coop", amount: 45, category: .groceries, date: .now)
        context.insert(expense)
        try context.save()

        try ExpenseEdit(expenseID: expense.persistentModelID, title: nil, amount: 48, category: nil).apply(in: context)

        let saved = try #require(context.fetch(FetchDescriptor<Expense>()).first)
        #expect(saved.title == "Coop")
        #expect(saved.amount == 48)
        #expect(saved.category == .groceries)
        #expect(saved.isCorrected)
    }

    @Test
    func failsToEditADeletedExpense() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Expense.self, configurations: config)
        let context = ModelContext(container)
        let expense = Expense(title: "Coop", amount: 45, category: .groceries, date: .now)
        context.insert(expense)
        try context.save()
        let edit = ExpenseEdit(expenseID: expense.persistentModelID, title: nil, amount: 48, category: nil)
        context.delete(expense)
        try context.save()

        #expect(throws: ExpenseEditError.expenseGone) {
            try edit.apply(in: context)
        }
    }
}
