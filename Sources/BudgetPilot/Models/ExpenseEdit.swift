import Foundation
import SwiftData

/// A change to a saved expense. Applied only when the user confirms it.
struct ExpenseEdit: Equatable {
    let expenseID: PersistentIdentifier
    let title: String?
    let amount: Decimal?
    let category: ExpenseCategory?

    func apply(in context: ModelContext) throws {
        let id = expenseID
        let descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.persistentModelID == id })
        guard let expense = try context.fetch(descriptor).first else { throw ExpenseEditError.expenseGone }

        if let title {
            expense.title = title
        }
        if let amount {
            expense.amount = amount
        }
        if let category {
            expense.category = category
        }
        expense.isCorrected = true
        try context.save()
    }
}

enum ExpenseEditError: LocalizedError {
    case expenseGone

    var errorDescription: String? {
        "This expense no longer exists."
    }
}
