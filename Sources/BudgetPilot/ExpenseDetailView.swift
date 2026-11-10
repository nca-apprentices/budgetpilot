import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: expense.category.systemImage)
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                            .frame(width: 70, height: 70)
                            .background(expense.category.color, in: .rect(cornerRadius: 18))
                        Text(expense.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(expense.amount, format: .currency(code: "CHF"))
                            .font(.system(size: 36, weight: .bold))
                    }
                    VStack(spacing: 12) {
                        DetailRow(systemImage: "tag",
                                  color: .appDetailCategory,
                                  title: "Category",
                                  value: expense.category.title)
                        DetailRow(systemImage: "calendar",
                                  color: .appDetailDate,
                                  title: "Date",
                                  value: expense.date.formatted(date: .abbreviated, time: .omitted))
                        DetailRow(systemImage: "creditcard",
                                  color: .appDetailPayment,
                                  title: "Payment",
                                  value: expense.paymentMethod?.title ?? "None")
                        DetailRow(systemImage: "doc.text",
                                  color: .appDetailNote,
                                  title: "Note",
                                  value: expense.note ?? "None")
                    }
                    .padding(16)
                    .glassEffect(.regular, in: .rect(cornerRadius: 25))
                }
                .padding(16)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button {} label: {
                        Text("Edit").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    Button(role: .destructive) {} label: {
                        Text("Delete")
                            .foregroundStyle(Color.appDestructive)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                }
                .controlSize(.large)
                .padding(16)
            }
            .navigationTitle("Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ExpenseDetailView(expense: Expense(
        title: "Sony WH-1000XM5",
        amount: 299,
        category: .leisure,
        date: .now,
        paymentMethod: .card,
        note: "Via chat"
    ))
}
