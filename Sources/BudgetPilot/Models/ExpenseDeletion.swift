import Foundation
import SwiftData

/// Removes a saved expense. Runs only when the user confirms it.
struct ExpenseDeletion: Equatable {
    let expenseID: PersistentIdentifier

    func apply(in context: ModelContext) throws {
        let id = expenseID
        let descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.persistentModelID == id })
        guard let expense = try context.fetch(descriptor).first else { throw ExpenseEditError.expenseGone }

        context.delete(expense)
        try context.save()
    }
}
