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
}
