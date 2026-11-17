import SwiftData
import SwiftUI

struct AllExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var period: ExpensePeriod = .month
    @State private var selectedExpense: Expense?
    @State private var lastDeleted: DeletedExpense?

    private var history: ExpenseHistory {
        ExpenseHistory(expenses: expenses, period: period, now: .now)
    }

    private var periodLabel: String {
        switch period {
        case .week: "This week"
        case .month: Date.now.formatted(.dateTime.month(.wide).year())
        case .year: Date.now.formatted(.dateTime.year())
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Picker("Period", selection: $period) {
                    ForEach(ExpensePeriod.allCases, id: \.self) { period in
                        Text(period.title)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text(periodLabel)
                        .foregroundStyle(.secondary)

                    Text(history.total, format: .currency(code: "CHF"))
                        .font(.system(size: 35, weight: .bold))

                    Text("spent · \(history.count) expenses")
                        .foregroundStyle(.secondary)
                }

                if history.groups.isEmpty {
                    Text("No expenses in this period")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(history.groups) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.title)
                                .foregroundStyle(.secondary)

                            VStack(spacing: 12) {
                                ForEach(group.expenses) { expense in
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
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseDetailView(expense: expense) {
                selectedExpense = nil
                withAnimation {
                    lastDeleted = DeletedExpense(expense)
                    modelContext.delete(expense)
                }
            }
            .presentationDetents([.fraction(0.75)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.appOffWhite)
        }
        .overlay(alignment: .bottom) {
            if lastDeleted != nil {
                UndoToast(message: "Expense deleted") {
                    withAnimation {
                        lastDeleted?.restore(in: modelContext)
                        lastDeleted = nil
                    }
                }
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task(id: lastDeleted) {
            guard lastDeleted != nil else { return }
            do {
                try await Task.sleep(for: .seconds(6))
            } catch {
                // Cancelled because another expense was deleted; keep its toast.
                return
            }
            withAnimation {
                lastDeleted = nil
            }
        }
        .navigationTitle("Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .background { AppBackground() }
    }
}

#Preview {
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(
        for: Expense.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now)!
    }

    let examples = [
        Expense(title: "Sony WH-1000XM5", amount: 299, category: .leisure, date: .now),
        Expense(title: "Wocheneinkauf Migros", amount: 86.40, category: .groceries, date: .now),
        Expense(title: "Halbtax", amount: 190, category: .transport, date: daysAgo(8)),
        Expense(title: "Pizzeria Da Mario", amount: 48.50, category: .leisure, date: daysAgo(8)),
        Expense(title: "Coop Pronto", amount: 23.80, category: .groceries, date: daysAgo(15)),
        Expense(title: "Netflix", amount: 18.90, category: .subscriptions, date: daysAgo(40)),
    ]

    for expense in examples {
        container.mainContext.insert(expense)
    }

    return ZStack {
        AppBackground()
        AllExpensesView()
    }
    .modelContainer(container)
}
