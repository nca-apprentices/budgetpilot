import Foundation

/// The time span the "Expenses" screen shows.
enum ExpensePeriod: CaseIterable {
    case week, month, year

    var title: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }

    /// The unit `Calendar` compares dates by to find the expenses of this period.
    var granularity: Calendar.Component {
        switch self {
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }
}
