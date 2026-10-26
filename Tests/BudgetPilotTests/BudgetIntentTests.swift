@testable import BudgetPilot
import Foundation
import Testing

struct BudgetIntentTests {
    /// Phrases and the tool call the model should make for each. The test only
    /// checks our side; scoring the model against them needs a device run.
    static let phrases: [(String, [String: Any])] = [
        ("Sony WH-1000XM5 headphones for 299", ["title": "Sony headphones", "amount": 299, "category": "leisure"]),
        ("Coop 45.80", ["title": "Coop", "amount": 45.8, "category": "groceries"]),
        ("Halbtax 190", ["title": "Halbtax", "amount": 190, "category": "transport"]),
    ]

    @Test
    func expectedCallsAreReadAndBacked() throws {
        for (phrase, arguments) in Self.phrases {
            let intent = try #require(BudgetIntent(name: "add_expense", arguments: arguments))
            #expect(intent.isBacked(by: phrase), "\(phrase)")
        }
    }

    @Test
    func rejectsAnInventedAmount() throws {
        let intent = try #require(BudgetIntent(
            name: "add_expense", arguments: ["title": "Lunch", "amount": 15, "category": "leisure"]
        ))
        #expect(!intent.isBacked(by: "lunch yesterday"))
    }

    @Test
    func rejectsUnknownToolsAndCategories() {
        #expect(BudgetIntent(name: "book_flight", arguments: [:]) == nil)
        #expect(BudgetIntent(name: "add_expense", arguments: ["title": "x", "amount": 5, "category": "food"]) == nil)
    }

    @Test
    func readsABackedIncome() throws {
        let intent = try #require(BudgetIntent(name: "set_income", arguments: ["amount": 6500]))
        #expect(intent == .setIncome(amount: 6500))
        #expect(intent.isBacked(by: "I earn 6500 a month"))
        #expect(!intent.isBacked(by: "I earn about six thousand"))
    }

    @Test
    func rejectsAMissingOrZeroIncome() {
        #expect(BudgetIntent(name: "set_income", arguments: [:]) == nil)
        #expect(BudgetIntent(name: "set_income", arguments: ["amount": 0]) == nil)
    }

    @Test @MainActor
    func savesTheIncome() throws {
        let suiteName = "BudgetIntentTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let incomeData = IncomeData(defaults: defaults)

        let reply = AssistantModel(incomeData: incomeData).handle(.setIncome(amount: 6500))

        #expect(incomeData.monthlyIncome == 6500)
        #expect(reply.text == "Saved your monthly income: CHF 6500.")
    }

    @Test
    func readsAnIncomeQuestion() throws {
        let intent = try #require(BudgetIntent(name: "get_income", arguments: [:]))
        #expect(intent == .getIncome)
        #expect(intent.isBacked(by: "What is my income?"))
    }

    @Test @MainActor
    func repliesWithTheSavedIncome() throws {
        let suiteName = "BudgetIntentTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let incomeData = IncomeData(defaults: defaults)
        let assistant = AssistantModel(incomeData: incomeData)

        #expect(assistant.handle(.getIncome).text == "I don't know your monthly income yet. How much is it?")

        incomeData.monthlyIncome = 6500
        #expect(assistant.handle(.getIncome).text == "Your monthly income is CHF 6500.")
    }

    @Test @MainActor
    func proposesAnExpenseWithoutSavingIt() {
        let reply = AssistantModel().handle(.addExpense(title: "Halbtax", amount: 190, category: .transport))

        #expect(reply.text == "Add: Halbtax, CHF 190, Transport?")
        #expect(reply.proposedExpense == ProposedExpense(title: "Halbtax", amount: 190, category: .transport))
        #expect(!reply.isSaved)
    }
}
