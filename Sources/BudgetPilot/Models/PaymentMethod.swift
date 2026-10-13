enum PaymentMethod: String, Codable, CaseIterable {
    case card, cash

    var title: String {
        switch self {
        case .card: "Card"
        case .cash: "Cash"
        }
    }
}
