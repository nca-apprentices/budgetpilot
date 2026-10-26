import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    /// Set when the assistant proposes an expense the user can save.
    var proposedExpense: ProposedExpense?
    var isSaved = false
}
