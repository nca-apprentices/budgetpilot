import Foundation

struct IncomeData {
    private static let monthlyIncomeKey = "monthlyIncome"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var monthlyIncome: Decimal? {
        get {
            defaults.string(forKey: Self.monthlyIncomeKey).flatMap { Decimal(string: $0) }
        }
        nonmutating set {
            if let newValue {
                defaults.set(newValue.description, forKey: Self.monthlyIncomeKey)
            } else {
                defaults.removeObject(forKey: Self.monthlyIncomeKey)
            }
        }
    }
}
