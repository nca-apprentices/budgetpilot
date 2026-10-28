import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    /// Set when the assistant proposes something the user has to confirm.
    var proposal: Proposal?
    var isConfirmed = false
}

enum Proposal: Equatable {
    case add(ProposedExpense)
    case edit(ExpenseEdit)

    var confirmTitle: String {
        switch self {
        case .add: "Save"
        case .edit: "Apply"
        }
    }

    var doneTitle: String {
        switch self {
        case .add: "Saved"
        case .edit: "Changed"
        }
    }
}
