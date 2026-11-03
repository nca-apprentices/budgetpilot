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

            Text("Recent expenses")
                .font(.title2)
                .fontWeight(.semibold)

            if expenses.isEmpty {
                Text("No expenses yet")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(expenses.prefix(5)) { expense in
                        ExpenseRow(expense: expense)
                    }
                }
                .padding(16)
                .glassEffect(.regular, in: .rect(cornerRadius: 25))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(
        for: Expense.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let examples = [
        Expense(title: "Kaffee", amount: 5, category: .groceries, date: .now),
        Expense(title: "Sony WH-1000XM5", amount: 299, category: .leisure, date: .now),
        Expense(title: "Wocheneinkauf Migros", amount: 86.40, category: .groceries, date: .now),
        Expense(title: "Pizzeria", amount: 48.50, category: .leisure, date: .now),
    ]

    for expense in examples {
        container.mainContext.insert(expense)
    }

    return ZStack {
        AppBackground()
        BudgetView()
    }
    .modelContainer(container)
}
