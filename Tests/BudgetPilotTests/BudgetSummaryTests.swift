@testable import BudgetPilot
import Foundation
import Testing

struct BudgetSummaryTests {
    let now = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 15))!
    let lastMonth = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 30))!

    @Test
    func spentCountsOnlyThisMonth() {
        let expenses = [
            Expense(title: "Coop", amount: 23.50, category: .groceries, date: now),
            Expense(title: "Kino", amount: 21, category: .leisure, date: lastMonth),
        ]

        let summary = BudgetSummary(income: 5000, fixedCosts: 2000, expenses: expenses, now: now)

        #expect(summary.spent == 23.50)
    }

    @Test
    func availableSubtractsFixedCostsAndSpent() {
        let expense = Expense(title: "Wocheneinkauf Coop", amount: 500, category: .groceries, date: now)
        let summary = BudgetSummary(income: 5000, fixedCosts: 2000, expenses: [expense], now: now)

        #expect(summary.available == 2500)
    }

    @Test
    func spentPercentIsZeroWithoutBudget() {
        let expense = Expense(title: "Apotheke", amount: 50, category: .health, date: now)
        let summary = BudgetSummary(income: 0, fixedCosts: 0, expenses: [expense], now: now)

        #expect(summary.spentPercent == 0)
    }

    @Test
    func spentPercentDividesSpentByBudget() {
        let expense = Expense(title: "Computer", amount: 1500, category: .leisure, date: now)
        let summary = BudgetSummary(income: 5000, fixedCosts: 2000, expenses: [expense], now: now)

        #expect(summary.spentPercent == 0.5)
    }

    @Test
    func usesTheStoredIncomeAndFixedCosts() throws {
        let suiteName = "BudgetSummaryTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let stored = IncomeData(defaults: defaults)
        stored.monthlyIncome = 5000
        stored.monthlyFixedCosts = 2000
        let expense = Expense(title: "Computer", amount: 1500, category: .leisure, date: now)

        let summary = BudgetSummary(stored: stored, expenses: [expense], now: now)

        #expect(summary.fixedCosts == 2000)
        #expect(summary.available == 1500)
        #expect(summary.spentPercent == 0.5)
    }

    @Test
    func countsMissingAmountsAsZero() throws {
        let suiteName = "BudgetSummaryTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let summary = BudgetSummary(stored: IncomeData(defaults: defaults), expenses: [], now: now)

        #expect(summary.income == 0)
        #expect(summary.fixedCosts == 0)
    }
}
