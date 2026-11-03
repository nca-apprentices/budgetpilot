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
    case deleteExpense(match: String)
    case setFixedCosts(amount: Decimal)
    case getBudget

    /// The tools the model may, call, one, per intent.
    static let tools: [ToolSpec] = [
        Tool<[String: String], String>(
            name: "edit_expense",
            description: """
            Correct an expense the user names, e.g. "the Coop one was 54" or "the lunch was 23.50 not 21.50". \
            The app finds it by name.
            """,
            parameters: [
                .required("match", type: .string, description: "The name of the expense only, e.g. Coop"),
                .optional("new_title", type: .string, description: "The new name, only if it changes"),
                .optional("amount", type: .double, description: """
                The new amount exactly as the user wrote it, never the old one after not/nicht/nöd/pas
                """),
                .optional("category", type: .string,
                          description: "The new category, only if it changes; clothes are other",
                          extraProperties: ["enum": ExpenseCategory.allCases.map(\.rawValue)]),
            ]
        ) { _ in "" }.schema,

        Tool<[String: String], String>(
            name: "delete_expense",
            description: "Remove an expense the user names. The app finds it by name.",
            parameters: [
                .required("match", type: .string, description: "The name of the expense only, e.g. Coop"),
            ]
        ) { _ in "" }.schema,

        Tool<[String: String], String>(
            name: "add_expense",
            description: "Record a new purchase. Not for corrections like \"the Coop one was 54\".",
            parameters: [
                .required("title", type: .string, description: "What was bought"),
                .required("amount", type: .double, description: "The amount exactly as the user wrote it"),
                .optional("category", type: .string, description: "What the money is for; leave out if unsure",
                          extraProperties: ["enum": ExpenseCategory.allCases.map(\.rawValue)]),
            ]
        ) { _ in "" }.schema,

        Tool<[String: String], String>(
            name: "set_income",
            description: "Save the user's monthly income or salary. Not for a yearly amount.",
            parameters: [
                .required("amount", type: .double, description: "The monthly income exactly as the user wrote it"),
            ]
        ) { _ in "" }.schema,

        Tool<[String: String], String>(
            name: "set_fixed_costs",
            description: """
            Save the total of the user's monthly fixed costs. Not for a single bill such as rent or an Abo.
            """,
            parameters: [
                .required("amount", type: .double,
                          description: "The monthly fixed costs exactly as the user wrote them"),
            ]
        ) { _ in "" }.schema,

        Tool<[String: String], String>(
            name: "get_income",
            description: """
            Look up the user's saved monthly income. Only when they ask about their income or salary, \
            not about what is left.
            """,
            parameters: []
        ) { _ in "" }.schema,

        Tool<[String: String], String>(
            name: "get_budget",
            description: """
            Look up what is left this month, what was spent, on what, and where the money went, \
            e.g. "how much is left?", "wievill han i no?", "wo isch mis gäld anegange?", "combien il me reste?", \
            "can I afford this?".
            """,
            parameters: []
        ) { _ in "" }.schema,
    ]

    /// Reads a tool call, or nil if the model called something unknown or
    /// left out an argument.
    init?(name: String, arguments: [String: Any]) {
        let intent: BudgetIntent? = switch name {
        case "add_expense": Self.addExpense(from: arguments)
        case "edit_expense": Self.editExpense(from: arguments)
        case "delete_expense": Self.match(in: arguments).map { .deleteExpense(match: $0) }
        case "set_income": Self.positiveAmount(in: arguments).map { .setIncome(amount: $0) }
        case "set_fixed_costs": Self.positiveAmount(in: arguments).map { .setFixedCosts(amount: $0) }
        case "get_income": .getIncome
        case "get_budget": .getBudget
        default: nil
        }
        guard let intent else { return nil }
        self = intent
    }

    /// The model invents numbers, so an amount counts only if the user typed it.
    /// Intents without an amount have nothing to check.
    func isBacked(by message: String) -> Bool {
        let amount: Decimal
        switch self {
        case let .addExpense(_, value, _): amount = value
        case let .setIncome(value): amount = value
        case let .setFixedCosts(value): amount = value
        case .getIncome, .getBudget, .deleteExpense: return true
        case let .editExpense(_, _, value?, _): amount = value
        case .editExpense: return true
        }
        // Swiss thousands separators: 6'500 and 6’500 mean 6500. A decimal
        // comma, 12,50, means 12.50.
        let digits = message.replacing(#/['’](?=\d{3})/#, with: "")
        return digits.matches(of: #/\d+(?:[.,]\d{1,2})?/#).contains {
            Decimal(string: String($0.output).replacing(",", with: ".")) == amount
        }
    }

    // MARK: - Private

    private static func addExpense(from arguments: [String: Any]) -> BudgetIntent? {
        // The model writes 0 when the user gave no amount.
        guard let amount = positiveAmount(in: arguments),
              let title = arguments["title"] as? String
        else { return nil }
        // A missing category means the model was unsure; an unknown one is a bad call.
        let raw = arguments["category"] as? String ?? ExpenseCategory.other.rawValue
        guard let category = ExpenseCategory(rawValue: raw) else { return nil }
        return .addExpense(title: title, amount: amount, category: category)
    }

    /// Missing optional fields mean "keep the value"; present but invalid ones
    /// reject the call.
    private static func editExpense(from arguments: [String: Any]) -> BudgetIntent? {
        guard let match = match(in: arguments) else { return nil }

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

    private static func match(in arguments: [String: Any]) -> String? {
        let match = (arguments["match"] as? String)?.trimmingCharacters(in: .whitespaces)
        return match?.isEmpty == false ? match : nil
    }

    private static func positiveAmount(in arguments: [String: Any]) -> Decimal? {
        amount(in: arguments).flatMap { $0 > 0 ? $0 : nil }
    }

    private static func amount(in arguments: [String: Any]) -> Decimal? {
        // Through Swift's shortest round-trip form: NSNumber(9.8).stringValue
        // is 9.800000000000001, and Decimal(Double) drifts the same way.
        switch arguments["amount"] {
        case let value as Double: Decimal(string: "\(value)")
        case let value as Int: Decimal(value)
        default: nil
        }
    }
}
