@testable import BudgetPilot
import Foundation
import SwiftData
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
    func filesAnExpenseWithoutCategoryUnderOther() throws {
        let intent = try #require(BudgetIntent(name: "add_expense", arguments: ["title": "Shoes", "amount": 120]))
        #expect(intent == .addExpense(title: "Shoes", amount: 120, category: .other))
    }

    @Test
    func rejectsAnExpenseWithoutAmount() {
        // The model writes 0 when the user didn't say how much.
        #expect(BudgetIntent(name: "add_expense", arguments: ["title": "Dentist", "amount": 0]) == nil)
    }

    @Test
    func backsAnAmountThatIsNotExactInBinary() throws {
        // NSNumber(9.8).stringValue is 9.800000000000001.
        let intent = try #require(BudgetIntent(
            name: "add_expense", arguments: ["title": "Coffee", "amount": 9.8, "category": "leisure"]
        ))
        let amount = try #require(Decimal(string: "9.8"))
        #expect(intent == .addExpense(title: "Coffee", amount: amount, category: .leisure))
        #expect(intent.isBacked(by: "I bought 2 coffees for 9.80"))
    }

    @Test
    func backsSwissThousandsSeparators() {
        #expect(BudgetIntent.setIncome(amount: 6500).isBacked(by: "Mein Lohn ist 6'500 CHF"))
        #expect(BudgetIntent.setIncome(amount: 6500).isBacked(by: "Mein Lohn ist 6’500 CHF"))
        #expect(BudgetIntent.setIncome(amount: 1_000_000).isBacked(by: "1'000'000 im Jahr"))
        #expect(!BudgetIntent.setIncome(amount: 6500).isBacked(by: "6'50 CHF"))
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

        let reply = try AssistantModel(incomeData: incomeData).handle(.setIncome(amount: 6500), in: makeContext())

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
        let context = try makeContext()

        let unknown = try assistant.handle(.getIncome, in: context)
        #expect(unknown.text == "I don't know your monthly income yet. How much is it?")

        incomeData.monthlyIncome = 6500
        #expect(try assistant.handle(.getIncome, in: context).text == "Your monthly income is CHF 6500.")
    }

    @Test @MainActor
    func proposesAnExpenseWithoutSavingIt() throws {
        let context = try makeContext()
        let reply = try AssistantModel().handle(
            .addExpense(title: "Halbtax", amount: 190, category: .transport), in: context
        )

        #expect(reply.text == "Add: Halbtax, CHF 190, Transport?")
        #expect(reply.proposal == .add(ProposedExpense(title: "Halbtax", amount: 190, category: .transport)))
        #expect(!reply.isConfirmed)
        #expect(try context.fetch(FetchDescriptor<Expense>()).isEmpty)
    }

    @Test
    func readsASingleEdit() throws {
        let intent = try #require(BudgetIntent(name: "edit_expense", arguments: ["match": "Coop", "amount": 48]))
        #expect(intent == .editExpense(match: "Coop", title: nil, amount: 48, category: nil))
    }

    @Test
    func readsAllEditsTogether() throws {
        let intent = try #require(BudgetIntent(
            name: "edit_expense",
            arguments: ["match": " Coop ", "new_title": "Migros", "amount": 48, "category": "groceries"]
        ))
        #expect(intent == .editExpense(match: "Coop", title: "Migros", amount: 48, category: .groceries))
    }

    @Test
    func rejectsInvalidEdits() {
        #expect(BudgetIntent(name: "edit_expense", arguments: ["amount": 48]) == nil)
        #expect(BudgetIntent(name: "edit_expense", arguments: ["match": " ", "amount": 48]) == nil)
        #expect(BudgetIntent(name: "edit_expense", arguments: ["match": "Coop"]) == nil)
        #expect(BudgetIntent(name: "edit_expense", arguments: ["match": "Coop", "amount": 0]) == nil)
        #expect(BudgetIntent(name: "edit_expense", arguments: ["match": "Coop", "category": "food"]) == nil)
    }

    @Test
    func checksTheAmountOfAnEdit() throws {
        let amount = try #require(Decimal(string: "48.50"))
        let edit = BudgetIntent.editExpense(match: "Coop", title: nil, amount: amount, category: nil)
        #expect(edit.isBacked(by: "Coop was actually 48.50"))
        #expect(!edit.isBacked(by: "Coop was more"))

        let recategorized = BudgetIntent.editExpense(match: "Coop", title: nil, amount: nil, category: .leisure)
        #expect(recategorized.isBacked(by: "Coop was leisure"))
    }

    @Test @MainActor
    func proposesAnEditToTheNewestMatch() throws {
        let context = try makeContext()
        let older = Expense(
            title: "Coop", amount: 30, category: .groceries, date: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let newer = Expense(
            title: "Coop City", amount: 45, category: .groceries, date: Date(timeIntervalSince1970: 1_800_100_000)
        )
        context.insert(older)
        context.insert(newer)
        try context.save()

        let reply = try AssistantModel().handle(
            .editExpense(match: "coop", title: nil, amount: 48, category: nil), in: context
        )

        #expect(reply.text.hasPrefix("Change Coop City ("))
        #expect(reply.text.hasSuffix("): CHF 45 → CHF 48?"))
        #expect(reply.proposal == .edit(ExpenseEdit(
            expenseID: newer.persistentModelID, title: nil, amount: 48, category: nil
        )))
        #expect(newer.amount == 45)
    }

    @Test @MainActor
    func findsAnExpenseWhenTheModelKeepsExtraWords() throws {
        let context = try makeContext()
        let coop = Expense(title: "Coop", amount: 30, category: .groceries, date: .now)
        context.insert(coop)
        try context.save()

        let reply = try AssistantModel().handle(
            .editExpense(match: "Coop Einkauf", title: nil, amount: 48, category: nil), in: context
        )

        #expect(reply.proposal == .edit(ExpenseEdit(
            expenseID: coop.persistentModelID, title: nil, amount: 48, category: nil
        )))
    }

    @Test @MainActor
    func repliesWhenNoExpenseMatches() throws {
        let context = try makeContext()
        context.insert(Expense(title: "Halbtax", amount: 190, category: .transport, date: .now))
        try context.save()

        let reply = try AssistantModel().handle(
            .editExpense(match: "Coop", title: nil, amount: 48, category: nil), in: context
        )

        #expect(reply.text == "I couldn't find an expense called \"Coop\".")
        #expect(reply.proposal == nil)
    }

    @Test
    func readsADelete() throws {
        let intent = try #require(BudgetIntent(name: "delete_expense", arguments: ["match": " lunch "]))
        #expect(intent == .deleteExpense(match: "lunch"))
        #expect(intent.isBacked(by: "delete yesterday's lunch"))
        #expect(BudgetIntent(name: "delete_expense", arguments: ["match": " "]) == nil)
        #expect(BudgetIntent(name: "delete_expense", arguments: [:]) == nil)
    }

    @Test
    func readsBackedFixedCosts() throws {
        let intent = try #require(BudgetIntent(name: "set_fixed_costs", arguments: ["amount": 1920]))
        #expect(intent == .setFixedCosts(amount: 1920))
        #expect(intent.isBacked(by: "my fixed costs are 1920"))
        #expect(!intent.isBacked(by: "my fixed costs are about two thousand"))
        #expect(BudgetIntent(name: "set_fixed_costs", arguments: ["amount": 0]) == nil)
    }

    @Test
    func readsABudgetQuestion() throws {
        let intent = try #require(BudgetIntent(name: "get_budget", arguments: [:]))
        #expect(intent == .getBudget)
        #expect(intent.isBacked(by: "how much is left?"))
    }

    /// The model understands these already; the app can't act on them yet.
    @Test @MainActor
    func repliesThatDeleteFixedCostsAndBudgetAreNotThereYet() throws {
        let context = try makeContext()
        let assistant = AssistantModel()
        #expect(try assistant.handle(.deleteExpense(match: "lunch"), in: context).proposal == nil)
        #expect(try assistant.handle(.setFixedCosts(amount: 1920), in: context).text == "I can't save fixed costs yet.")
        #expect(try assistant.handle(.getBudget, in: context).text == "I can't show what is left yet.")
    }

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContext(ModelContainer(for: Expense.self, configurations: config))
    }
}
