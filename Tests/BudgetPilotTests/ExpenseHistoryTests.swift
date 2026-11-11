@testable import BudgetPilot
import Foundation
import Testing

struct ExpenseHistoryTests {
    let now = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 15))!
    let yesterday = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 14))!
    let twoWeeksAgo = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 1))!
    let lastMonth = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 30))!
    let january = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 15))!
    let lastYear = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 15))!

    @Test
    func monthCountsOnlyThisMonth() {
        let expenses = [
            Expense(title: "Coop", amount: 23.50, category: .groceries, date: now),
            Expense(title: "Kino", amount: 21, category: .leisure, date: lastMonth),
        ]

        let history = ExpenseHistory(expenses: expenses, period: .month, now: now)

        #expect(history.count == 1)
    }

    @Test
    func weekCountsOnlyThisWeek() {
        let expenses = [
            Expense(title: "Coop", amount: 23.50, category: .groceries, date: now),
            Expense(title: "Kino", amount: 21, category: .leisure, date: twoWeeksAgo),
        ]

        let history = ExpenseHistory(expenses: expenses, period: .week, now: now)

        #expect(history.count == 1)
    }

    @Test
    func yearCountsTheWholeYear() {
        let expenses = [
            Expense(title: "Coop", amount: 23.50, category: .groceries, date: now),
            Expense(title: "Kino", amount: 21, category: .leisure, date: january),
            Expense(title: "Kino", amount: 21, category: .leisure, date: lastYear),
        ]

        let history = ExpenseHistory(expenses: expenses, period: .year, now: now)

        #expect(history.count == 2)
    }

    @Test
    func totalAddsUpThePeriod() {
        let expenses = [
            Expense(title: "Coop", amount: 23.50, category: .groceries, date: now),
            Expense(title: "Kino", amount: 21, category: .leisure, date: yesterday),
            Expense(title: "Kino", amount: 21, category: .leisure, date: lastMonth),
        ]

        let history = ExpenseHistory(expenses: expenses, period: .month, now: now)

        #expect(history.total == 44.50)
    }
}
