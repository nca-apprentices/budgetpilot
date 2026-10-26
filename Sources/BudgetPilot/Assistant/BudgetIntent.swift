import Foundation
import MLXLMCommon

/// What the user wants done. The model only proposes it: expenses wait for
/// the user to confirm, the income is saved straight away. More intents from
/// issue 57 become more cases.
enum BudgetIntent: Equatable {
    case addExpense(title: String, amount: Decimal, category: ExpenseCategory)
    case setIncome(amount: Decimal)

    /// The tools the model may, call, one, per intent.
    static let tools: [ToolSpec] = [
        Tool<[String: String], String>(
            name: "add_expense",
            description: "Record something the user bought.",
            parameters: [
                .required("title", type: .string, description: "What was bought"),
                .required("amount", type: .double, description: "The amount exactly as the user wrote it"),
                .required("category", type: .string, description: "What the money is for",
                          extraProperties: ["enum": ExpenseCategory.allCases.map(\.rawValue)]),
            ]
        ) { _ in "" }.schema,

        Tool<[String: String], String>(
            name: "set_income",
            description: "Save the user's monthly income.",
            parameters: [
                .required("amount", type: .double, description: "The monthly income exactly as the user wrote it"),
            ]
        ) { _ in "" }.schema,
    ]

    /// Reads a tool call, or nil if the model called something unknown or
    /// left out an argument.
    init?(name: String, arguments: [String: Any]) {
        // Through the string form, so 12.35 does not become 12.3499999.
        guard let number = arguments["amount"] as? NSNumber,
              let amount = Decimal(string: number.stringValue)
        else { return nil }

        switch name {
        case "add_expense":
            guard let title = arguments["title"] as? String,
                  let raw = arguments["category"] as? String,
                  let category = ExpenseCategory(rawValue: raw)
            else { return nil }
            self = .addExpense(title: title, amount: amount, category: category)
        case "set_income":
            guard amount > 0 else { return nil }
            self = .setIncome(amount: amount)
        default:
            return nil
        }
    }

    /// The model invents numbers, so an amount counts only if the user typed it.
    func isBacked(by message: String) -> Bool {
        let amount = switch self {
        case let .addExpense(_, amount, _): amount
        case let .setIncome(amount): amount
        }
        return message.matches(of: #/\d+(?:\.\d{1,2})?/#).contains { Decimal(string: String($0.output)) == amount }
    }
}
