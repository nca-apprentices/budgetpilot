import Foundation
import SwiftData

/// The values of a deleted expense, so "Undo" can bring it back.
struct DeletedExpense: Equatable {
    let title: String
    let amount: Decimal
    let category: ExpenseCategory
    let date: Date
    let paymentMethod: PaymentMethod?
    let note: String?
    let isCorrected: Bool

    init(_ expense: Expense) {
        title = expense.title
        amount = expense.amount
        category = expense.category
        date = expense.date
        paymentMethod = expense.paymentMethod
        note = expense.note
        isCorrected = expense.isCorrected
    }

    func restore(in context: ModelContext) {
        context.insert(Expense(
            title: title,
            amount: amount,
            category: category,
            date: date,
            paymentMethod: paymentMethod,
            note: note,
            isCorrected: isCorrected
        ))
    }
}
