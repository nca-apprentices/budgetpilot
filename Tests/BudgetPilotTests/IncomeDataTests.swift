@testable import BudgetPilot
import Foundation
import Testing

struct IncomeDataTests {
    /// A store of its own per test, removed afterwards.
    private func withStore(_ body: (IncomeData) throws -> Void) throws {
        let suiteName = "IncomeDataTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        try body(IncomeData(defaults: defaults))
    }

    @Test
    func fixedCostsAreUnsetAtFirst() throws {
        try withStore { #expect($0.monthlyFixedCosts == nil) }
    }

    @Test
    func storesAndReadsFixedCosts() throws {
        try withStore { store in
            store.monthlyFixedCosts = 1920
            #expect(store.monthlyFixedCosts == 1920)
        }
    }

    @Test
    func keepsCentsExactly() throws {
        try withStore { store in
            store.monthlyFixedCosts = Decimal(string: "2100.35")
            #expect(store.monthlyFixedCosts == Decimal(string: "2100.35"))
        }
    }

    @Test
    func clearingRemovesFixedCosts() throws {
        try withStore { store in
            store.monthlyFixedCosts = 1920
            store.monthlyFixedCosts = nil
            #expect(store.monthlyFixedCosts == nil)
        }
    }

    @Test
    func fixedCostsAndIncomeAreStoredApart() throws {
        try withStore { store in
            store.monthlyIncome = 6500
            store.monthlyFixedCosts = 1920
            #expect(store.monthlyIncome == 6500)
            #expect(store.monthlyFixedCosts == 1920)
        }
    }

    /// BudgetView creates a new IncomeData on every redraw.
    @Test
    func keepsTheStoredValueAcrossInstances() throws {
        let suiteName = "IncomeDataTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        IncomeData(defaults: defaults).monthlyFixedCosts = 1920
        #expect(IncomeData(defaults: defaults).monthlyFixedCosts == 1920)
    }
}
