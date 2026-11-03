import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.systemImage)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(expense.category.color, in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(expense.category.title)
                    Text("·")
                    Text(expense.date, format: .dateTime.day().month())
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(expense.amount, format: .number.precision(.fractionLength(2)))
                .font(.headline)
        }
    }
}

#Preview {
    ExpenseRow(expense: Expense(title: "Halbtax", amount: 190, category: .transport, date: .now))
        .padding()
}
