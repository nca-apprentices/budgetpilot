import Foundation

/// The monthly amounts the budget is based on, stored on the device.
struct IncomeData {
    private static let monthlyIncomeKey = "monthlyIncome"
    private static let monthlyFixedCostsKey = "monthlyFixedCosts"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var monthlyIncome: Decimal? {
        get { decimal(forKey: Self.monthlyIncomeKey) }
        nonmutating set { set(newValue, forKey: Self.monthlyIncomeKey) }
    }

    var monthlyFixedCosts: Decimal? {
        get { decimal(forKey: Self.monthlyFixedCostsKey) }
        nonmutating set { set(newValue, forKey: Self.monthlyFixedCostsKey) }
    }

    /// Stored as text: a Double would turn 1920.35 into 1920.3499999.
    private func decimal(forKey key: String) -> Decimal? {
        defaults.string(forKey: key).flatMap { Decimal(string: $0) }
    }

    private func set(_ value: Decimal?, forKey key: String) {
        if let value {
            defaults.set(value.description, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
