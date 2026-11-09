@testable import BudgetPilot
import Foundation
import SwiftData
import Testing

@MainActor
struct ExpenseListTests {
    @Test
    func listsOnlyMatchingExpensesFromThisMonth() throws {
        let context = try makeContext()
        let lastMonth = try #require(Calendar.current.date(byAdding: .month, value: -1, to: .now))
        context.insert(Expense(title: "Coop", amount: 20, category: .groceries, date: .now))
        context.insert(Expense(title: "SBB", amount: 12, category: .transport, date: .now))
        context.insert(Expense(title: "Coop", amount: 99, category: .groceries, date: lastMonth))
        try context.save()

        let reply = try AssistantModel().handle(.getExpenses(match: "Coop"), in: context)

        #expect(reply.text.hasPrefix("Coop, "))
        #expect(reply.text.hasSuffix(", CHF 20"))
        #expect(!reply.text.contains("SBB"))
        #expect(!reply.text.contains("CHF 99"))
        #expect(reply.proposal == nil)
    }

    @Test
    func listsAtMostTenExpenses() throws {
        let context = try makeContext()
        for amount in 1 ... 12 {
            context.insert(Expense(title: "Kafi", amount: Decimal(amount), category: .leisure, date: .now))
        }
        try context.save()

        let reply = try AssistantModel().handle(.getExpenses(match: nil), in: context)

        #expect(reply.text.split(separator: "\n").count == 10)
    }

    @Test
    func repliesWhenThereAreNoExpensesToList() throws {
        let context = try makeContext()
        let assistant = AssistantModel()

        #expect(try assistant.handle(.getExpenses(match: nil), in: context).text
            == "You have no expenses this month yet.")
        #expect(try assistant.handle(.getExpenses(match: "Coop"), in: context).text
            == "I couldn't find an expense called \"Coop\" this month.")
    }

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContext(ModelContainer(for: Expense.self, configurations: config))
    }
}
