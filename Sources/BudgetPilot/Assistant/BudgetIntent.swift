import Foundation
import MLXLMCommon

/// What the user wants done. The model only proposes it: expenses wait for
/// the user to confirm, the income is saved or read straight away. More
/// intents from issue 57 become more cases.
enum BudgetIntent: Equatable {
    case addExpense(title: String, amount: Decimal, category: ExpenseCategory)
    case setIncome(amount: Decimal)
    case getIncome
    case editExpense(match: String, title: String?, amount: Decimal?, category: ExpenseCategory?)

    /// The tools the model may, call, one, per intent.
    static let tools: [ToolSpec] = [
        Tool<[String: String], String>(
            name: "edit_expense",
            description: "Change an expense the user already saved.",
            parameters: [
                .required("match", type: .string, description: "Which expense, in the user's words, e.g. Coop."),
                .optional("new_title", type: .string, description: "The new name, only if it changes"),
                .optional("amount", type: .double, description: "The new amount exactly as the user wrote it"),
                .optional("category", type: .string, description: "The new category, only if it changes",
                          extraProperties: ["enum": ExpenseCategory.allCases.map(\.rawValue)]),
            ]
        ) { _ in "" }.schema,

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
        case "edit_expense":
            guard let intent = Self.editExpense(from: arguments) else { return nil }
            self = intent
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
        case let .editExpense(_, _, value?, _): amount = value
        case .editExpense: return true
        }
        return message.matches(of: #/\d+(?:\.\d{1,2})?/#).contains { Decimal(string: String($0.output)) == amount }
    }

    // MARK: - Private

    /// Missing optional fields mean "keep the value"; present but invalid ones
    /// reject the call.
    private static func editExpense(from arguments: [String: Any]) -> BudgetIntent? {
        guard let match = (arguments["match"] as? String)?.trimmingCharacters(in: .whitespaces),
              !match.isEmpty
        else { return nil }

        let title = (arguments["new_title"] as? String).flatMap { $0.isEmpty ? nil : $0 }

        var amount: Decimal?
        if arguments["amount"] != nil {
            guard let value = Self.amount(in: arguments), value > 0 else { return nil }
            amount = value
        }

        var category: ExpenseCategory?
        if arguments["category"] != nil {
            guard let raw = arguments["category"] as? String,
                  let value = ExpenseCategory(rawValue: raw)
            else { return nil }
            category = value
        }

        guard title != nil || amount != nil || category != nil else { return nil }
        return .editExpense(match: match, title: title, amount: amount, category: category)
    }

    private static func amount(in arguments: [String: Any]) -> Decimal? {
        // Through the string form, so 12.35 does not become 12.3499999.
        guard let number = arguments["amount"] as? NSNumber else { return nil }
        return Decimal(string: number.stringValue)
    }
}
