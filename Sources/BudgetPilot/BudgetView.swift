import SwiftData
import SwiftUI

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \Wish.addedAt, order: .reverse) private var wishes: [Wish]
    @State private var selectedExpense: Expense?
    private var summary: BudgetSummary {
        BudgetSummary(income: IncomeData().monthlyIncome ?? 0, fixedCosts: 0, expenses: expenses, now: .now)
    }

    private var freePercent: Double {
        max(1 - summary.spentPercent, 0)
    }

    var body: some View {
        // Scrolls because the wishlist shows every wish and can get long.
        ScrollView(showsIndicators: false) {
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
                            Button {
                                selectedExpense = expense
                            } label: {
                                ExpenseRow(expense: expense)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .glassEffect(.regular, in: .rect(cornerRadius: 25))
                }

                wishlist
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseDetailView(expense: expense)
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.appOffWhite)
        }
    }

    private var wishlist: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Wishlist")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    if !wishes.isEmpty {
                        Text(Wishlist.total(of: wishes), format: .currency(code: "CHF"))
                            .font(.headline)
                    }
                }
                if !wishes.isEmpty {
                    let shortfall = Wishlist.shortfall(of: wishes, available: summary.available)
                    Group {
                        if shortfall > 0 {
                            Text("\(shortfall, format: .currency(code: "CHF")) more than your available budget")
                        } else {
                            Text("Fits in your available budget")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

            if wishes.isEmpty {
                Text("No wishes yet. Save one from a price search.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(wishes) { wish in
                        WishRow(wish: wish) {
                            withAnimation { modelContext.delete(wish) }
                        }
                    }
                }
                .padding(16)
                .glassEffect(.regular, in: .rect(cornerRadius: 25))
            }
        }

    }
}

#Preview {
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(
        for: Expense.self, Wish.self,
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

    container.mainContext.insert(Wish(offer: PriceOffer(
        title: "SONY Playstation 5 Slim Digital Edition",
        price: 549,
        offerCount: 14,
        url: URL(string: "https://www.toppreise.ch/preisvergleich/PS5-p867338")!
    )))

    return ZStack {
        AppBackground()
        BudgetView()
    }
    .modelContainer(container)
}
