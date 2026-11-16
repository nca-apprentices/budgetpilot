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

extension BudgetSummary {
    /// What the overview shows. Amounts that aren't set yet count as 0.
    init(stored: IncomeData, expenses: [Expense], now: Date) {
        self.init(
            income: stored.monthlyIncome ?? 0,
            fixedCosts: stored.monthlyFixedCosts ?? 0,
            expenses: expenses,
            now: now
        )
    }
}
