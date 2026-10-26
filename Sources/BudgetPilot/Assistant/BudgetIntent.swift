import Foundation
import MLXLMCommon

/// What the user wants done. The model only proposes it: expenses wait for
/// the user to confirm, the income is saved or read straight away. More
/// intents from issue 57 become more cases.
enum BudgetIntent: Equatable {
    case addExpense(title: String, amount: Decimal, category: ExpenseCategory)
    case setIncome(amount: Decimal)
    case getIncome

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

        Tool<[String: String], String>(
            name: "get_income",
            description: "Look up the user's saved monthly income.",
            parameters: []
        ) { _ in "" }.schema,
    ]

    /// Reads a tool call, or nil if the model called something unknown or
    /// left out an argument.
    init?(name: String, arguments: [String: Any]) {
        switch name {
        case "add_expense":
            guard let amount = Self.amount(in: arguments),
                  let title = arguments["title"] as? String,
                  let raw = arguments["category"] as? String,
                  let category = ExpenseCategory(rawValue: raw)
            else { return nil }
            self = .addExpense(title: title, amount: amount, category: category)
        case "set_income":
            guard let amount = Self.amount(in: arguments), amount > 0 else { return nil }
            self = .setIncome(amount: amount)
        case "get_income":
            self = .getIncome
        default:
            return nil
        }
    }

    /// The model invents numbers, so an amount counts only if the user typed it.
    /// Intents without an amount have nothing to check.
    func isBacked(by message: String) -> Bool {
        let amount: Decimal
        switch self {
        case let .addExpense(_, value, _): amount = value
        case let .setIncome(value): amount = value
        case .getIncome: return true
        }
        return message.matches(of: #/\d+(?:\.\d{1,2})?/#).contains { Decimal(string: String($0.output)) == amount }
    }

    // MARK: - Private

    private static func amount(in arguments: [String: Any]) -> Decimal? {
        // Through the string form, so 12.35 does not become 12.3499999.
        guard let number = arguments["amount"] as? NSNumber else { return nil }
        return Decimal(string: number.stringValue)
    }
}
