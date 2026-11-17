import Foundation

/// Expenses shown together under one heading, such as "This week".
struct ExpenseGroup: Identifiable {
    let title: String
    let expenses: [Expense]

    var id: String {
        title
    }
}
