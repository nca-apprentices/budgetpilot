import SwiftData
import SwiftUI

struct BudgetView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    private var summary: BudgetSummary {
        BudgetSummary(income: IncomeData().monthlyIncome ?? 0, fixedCosts: 100, expenses: expenses, now: .now)
    }

    private var freePercent: Double {
        max(1 - summary.spentPercent, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("Available budget ·")
                    Text(Date.now, format: .dateTime.month(.wide).year())
                }
                .foregroundStyle(.secondary)

                Text(summary.available, format: .currency(code: "CHF"))
                    .font(.system(size: 44, weight: .bold))

                ProgressView(value: min(summary.spentPercent, 1))
                    .tint(Color.appAccent)
                    .scaleEffect(x: 1, y: 2)

                HStack(spacing: 4) {
                    Text("Spent")
                    Text(summary.spentPercent, format: .percent.precision(.fractionLength(0)))
                    Text("·")
                    Text("Free")
                    Text(freePercent, format: .percent.precision(.fractionLength(0)))
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                BudgetTile(title: "Income", amount: summary.income)
                BudgetTile(title: "Fixed costs", amount: summary.fixedCosts)
                BudgetTile(title: "Expenses", amount: summary.spent)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: Expense.self, inMemory: true)
}
