import Foundation

struct BudgetSummary {
    let income: Decimal
    let fixedCosts: Decimal
    let expenses: [Expense]
    let now: Date

    var spent: Decimal {
        expenses.filter {
            Calendar.current.isDate($0.date, equalTo: now, toGranularity: .month)
        }.reduce(0) { $0 + $1.amount }
    }

    var available: Decimal {
        income - fixedCosts - spent
    }

    var spentPercent: Double {
        let budget = income - fixedCosts
        guard budget > 0 else { return 0 }
        return NSDecimalNumber(decimal: spent / budget).doubleValue
    }
}
