import SwiftData
import SwiftUI

struct ExpenseEditView: View {
    let expense: Expense
    @State private var draft: ExpenseDraft
    @State private var errorMessage: String?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(expense: Expense) {
        self.expense = expense
        _draft = State(initialValue: ExpenseDraft(expense))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    field(systemImage: "textformat", color: .appDetailTitle) {
                        TextField("Title", text: $draft.title)
                    }
                    field(systemImage: "banknote", color: .appDetailAmount) {
                        TextField("Amount", value: $draft.amount, format: .currency(code: "CHF"))
                            .keyboardType(.decimalPad)
                    }
                } footer: {
                    if !draft.hasValidAmount {
                        Text("The amount must be more than zero.")
                            .foregroundStyle(Color.appDestructive)
                    }
                }
                Section {
                    field(systemImage: "tag", color: .appDetailCategory) {
                        Picker("Category", selection: $draft.category) {
                            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                Label(category.title, systemImage: category.systemImage).tag(category)
                            }
                        }
                    }
                    field(systemImage: "calendar", color: .appDetailDate) {
                        DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                    }
                    field(systemImage: "creditcard", color: .appDetailPayment) {
                        Picker("Payment", selection: $draft.paymentMethod) {
                            Text("None").tag(PaymentMethod?.none)
                            ForEach(PaymentMethod.allCases, id: \.self) { method in
                                Text(method.title).tag(Optional(method))
                            }
                        }
                    }
                }
                Section {
                    field(systemImage: "doc.text", color: .appDetailNote) {
                        TextField("Note", text: $draft.note, axis: .vertical)
                            .lineLimit(3...)
                    }
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!draft.canSave)
                }
            }
            .alert("Couldn't save", isPresented: isShowingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func field(
        systemImage: String,
        color: Color,
        @ViewBuilder content: () -> some View
    ) -> some View {
        HStack(spacing: 12) {
            DetailIcon(systemImage: systemImage, color: color)
            content()
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: {
                if !$0 {
                    errorMessage = nil
                }
            }
        )
    }

    private func save() {
        do {
            try draft.apply(to: expense, in: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ExpenseEditView(expense: Expense(
        title: "Sony WH-1000XM5",
        amount: 299,
        category: .leisure,
        date: .now,
        paymentMethod: .card,
        note: "Via chat"
    ))
    .modelContainer(for: Expense.self, inMemory: true)
}
