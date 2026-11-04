enum InputMode: CaseIterable {
    case addWithAI, priceSearch

    var title: String {
        switch self {
        case .addWithAI: "Add with AI"
        case .priceSearch: "Price search"
        }
    }

    var subtitle: String {
        switch self {
        case .addWithAI: "Log expenses via chat"
        case .priceSearch: "Find the cheapest offers"
        }
    }

    var systemImage: String {
        switch self {
        case .addWithAI: "sparkles"
        case .priceSearch: "magnifyingglass"
        }
    }

    var placeholder: String {
        switch self {
        case .addWithAI: "What did you buy?"
        case .priceSearch: "What are you looking for?"
        }
    }
}
