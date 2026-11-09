enum AnswerMode: CaseIterable {
    case fast, aiAnalysis, deepAnalysis

    var title: String {
        switch self {
        case .fast: "Fast"
        case .aiAnalysis: "AI analysis"
        case .deepAnalysis: "Deep analysis"
        }
    }

    var subtitle: String {
        switch self {
        case .fast: "Short, direct answers"
        case .aiAnalysis: "Thinks more thoroughly"
        case .deepAnalysis: "Detailed budget report"
        }
    }

    var systemImage: String {
        switch self {
        case .fast: "bolt"
        case .aiAnalysis: "brain"
        case .deepAnalysis: "doc.text.magnifyingglass"
        }
    }
}
