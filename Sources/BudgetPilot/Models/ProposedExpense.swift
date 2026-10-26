import Foundation
import SwiftData

/// An expense the assistant read from a message. Nothing is stored until the
/// user confirms it with `save(in:)`.
struct ProposedExpense: Equatable {
    let title: String
    let amount: Decimal
    let category: ExpenseCategory

    @discardableResult
    func save(in context: ModelContext, date: Date = .now) throws -> Expense {
        let expense = Expense(title: title, amount: amount, category: category, date: date)
        context.insert(expense)
        try context.save()
        return expense
    }
}
