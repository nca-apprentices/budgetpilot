@testable import BudgetPilot
import Foundation
import SwiftData
import Testing

struct CheckedCallTests {
    @Test
    func acceptsABackedCall() {
        let result = BudgetIntent.checked(
            name: "set_income", arguments: ["amount": 6500], message: "I earn 6500 a month"
        )
        #expect(result == .success(.setIncome(amount: 6500)))
    }

    @Test
    func rejectsAYearlyIncome() {
        for message in ["I earn 85000 a year", "Mein Jahreslohn ist 85000", "85000 par an", "85'000 p.a."] {
            let result = BudgetIntent.checked(name: "set_income", arguments: ["amount": 85000], message: message)
            #expect(result == .failure(.yearlyIncome), "\(message)")
        }
    }

    @Test
    func rejectsAnInventedAmount() {
        let result = BudgetIntent.checked(
            name: "add_expense", arguments: ["title": "Lunch", "amount": 15], message: "lunch yesterday"
        )
        #expect(result == .failure(.amountNotInMessage))
    }

    @Test
    func asksWhichExpenseForAnUnreadableEditOrDelete() {
        let result = BudgetIntent.checked(name: "delete_expense", arguments: [:], message: "Delete it")
        #expect(result == .failure(.unreadable(tool: "delete_expense")))
        #expect(CallRejection.unreadable(tool: "delete_expense").question == "Which expense do you mean?")
        #expect(CallRejection.unreadable(tool: "add_expense").question.contains("How much"))
    }

    @Test
    func backsADecimalComma() {
        #expect(BudgetIntent.addExpense(title: "Pizza", amount: 12.5, category: .leisure).isBacked(by: "Pizza 12,50"))
        // A comma between two amounts is not a decimal comma.
        let coop = BudgetIntent.addExpense(title: "Coop", amount: 30, category: .groceries)
        #expect(coop.isBacked(by: "Coop 30, SBB 12"))
    }

    /// Replies the model wrote instead of calling, as seen in the eval logs.
    @Test
    func readsCallsWrittenAsText() throws {
        let budget = try #require(WrittenToolCall("get_budget()"))
        #expect(budget.name == "get_budget")
        #expect(budget.arguments.isEmpty)

        let delete = try #require(WrittenToolCall(#"delete_expense{match: "Coop"}"#))
        #expect(delete.arguments["match"] as? String == "Coop")

        let add = try #require(WrittenToolCall(#"`add_expense(title="parking", amount=14, category="transport")`"#))
        #expect(add.arguments["title"] as? String == "parking")
        #expect(add.arguments["amount"] as? Int == 14)

        let edit = try #require(WrittenToolCall(#"edit_expense{amount:38,match:"|>taxi<|"<||>}"#))
        #expect(edit.arguments["match"] as? String == "taxi")
        #expect(edit.arguments["amount"] as? Int == 38)
    }

    @Test
    func leavesProseAndUnknownToolsAlone() {
        #expect(WrittenToolCall("I can call get_budget() for you.") == nil)
        #expect(WrittenToolCall("book_flight(to: \"Rome\")") == nil)
        #expect(WrittenToolCall("Hoi! How can I help?") == nil)
    }

    @Test @MainActor
    func repliesWithTheQuestionWhenACallIsRejected() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let context = try ModelContext(ModelContainer(for: Expense.self, configurations: config))

        let reply = try AssistantModel().reply(
            toCall: "set_income", arguments: ["amount": 85000], from: "I earn 85000 a year", in: context
        )

        #expect(reply.text == "Is that per year? Please tell me your monthly income.")
    }
}
