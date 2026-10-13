import SwiftUI

enum ExpenseCategory: String, Codable, CaseIterable {
    case housing, groceries, transport, leisure, health, subscriptions, other

    var title: String {
        switch self {
        case .housing: "Housing"
        case .groceries: "Groceries"
        case .transport: "Transport"
        case .leisure: "Leisure"
        case .health: "Health"
        case .subscriptions: "Subscriptions"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .housing: "house"
        case .groceries: "cart"
        case .transport: "tram"
        case .leisure: "headphones"
        case .health: "cross.case"
        case .subscriptions: "repeat"
        case .other: "ellipsis"
        }
    }

    var color: Color {
        switch self {
        case .housing: .appCategoryHousing
        case .groceries: .appCategoryGroceries
        case .transport: .appCategoryTransport
        case .leisure: .appCategoryLeisure
        case .health: .appCategoryHealth
        case .subscriptions: .appCategorySubscriptions
        case .other: .appCategoryOther
        }
    }
}
