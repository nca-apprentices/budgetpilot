import Foundation
import SwiftData

/// Editable copy of an expense. Changes reach the store only through `apply`,
/// so dropping the draft is how Cancel keeps the old values.
struct ExpenseDraft: Equatable {
    var title: String
    var amount: Decimal
    var category: ExpenseCategory
    var date: Date
    var paymentMethod: PaymentMethod?
    var note: String

    init(_ expense: Expense) {
        title = expense.title
        amount = expense.amount
        category = expense.category
        date = expense.date
        paymentMethod = expense.paymentMethod
        note = expense.note ?? ""
    }

    var hasValidAmount: Bool {
        amount > 0
    }

    var canSave: Bool {
        hasValidAmount && !trimmedTitle.isEmpty
    }

    func apply(to expense: Expense, in context: ModelContext) throws {
        guard hasValidAmount else { throw ExpenseDraftError.invalidAmount }
        guard !trimmedTitle.isEmpty else { throw ExpenseDraftError.emptyTitle }

        expense.title = trimmedTitle
        expense.amount = amount
        expense.category = category
        expense.date = date
        expense.paymentMethod = paymentMethod
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        expense.note = trimmedNote.isEmpty ? nil : trimmedNote
        // A person checked the values, as with a confirmed assistant edit.
        expense.isCorrected = true
        try context.save()
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ExpenseDraftError: LocalizedError {
    case invalidAmount
    case emptyTitle

    var errorDescription: String? {
        switch self {
        case .invalidAmount: "The amount must be more than zero."
        case .emptyTitle: "The title can't be empty."
        }
    }
}
