enum AppTab: CaseIterable {
    case chat, budget

    var title: String {
        switch self {
        case .chat: "Chat"
        case .budget: "Budget"
        }
    }
}
