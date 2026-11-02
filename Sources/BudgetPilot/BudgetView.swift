import SwiftData
import SwiftUI

struct BudgetView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    private var summary: BudgetSummary {
        BudgetSummary(income: IncomeData().monthlyIncome ?? 0, fixedCosts: 100, expenses: expenses, now: .now)
    }

    var body: some View {
        ZStack {
            AppBackground()
            Text(summary.available, format: .currency(code: "CHF"))
        }
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: Expense.self, inMemory: true)
}
