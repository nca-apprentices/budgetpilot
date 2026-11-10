import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    /// Set when the assistant proposes something the user has to confirm.
    var proposal: Proposal?
    var isConfirmed = false
    /// Products found by price search, shown under the text.
    var offers: [PriceOffer] = []
}

enum Proposal: Equatable {
    case add(ProposedExpense)
    case edit(ExpenseEdit)
    case delete(ExpenseDeletion)

    var confirmTitle: String {
        switch self {
        case .add: "Save"
        case .edit: "Apply"
        case .delete: "Delete"
        }
    }

    var doneTitle: String {
        switch self {
        case .add: "Saved"
        case .edit: "Changed"
        case .delete: "Deleted"
        }
    }
}
