import Foundation

/// The expenses of one period, with their total and count.
struct ExpenseHistory {
    let expenses: [Expense]
    let period: ExpensePeriod
    let now: Date

    var expensesInPeriod: [Expense] {
        expenses.filter {
            Calendar.current.isDate($0.date, equalTo: now, toGranularity: period.granularity)
        }
    }

    var total: Decimal {
        expensesInPeriod.reduce(0) { $0 + $1.amount }
    }

    var count: Int {
        expensesInPeriod.count
    }
}
