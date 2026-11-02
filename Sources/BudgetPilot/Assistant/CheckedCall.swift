import Foundation

/// Why the app won't act on a tool call. The app asks the user instead.
enum CallRejection: Error, Equatable {
    /// Unknown tool, or an argument missing or invalid.
    case unreadable(tool: String)
    /// The amount isn't in the user's message, so the model made it up.
    case amountNotInMessage
    /// The user gave a yearly income; the app keeps a monthly one.
    case yearlyIncome

    var question: String {
        switch self {
        case .unreadable(tool: "edit_expense"), .unreadable(tool: "delete_expense"):
            "Which expense do you mean?"
        case .unreadable, .amountNotInMessage:
            "Sorry, I could not read the amount. How much was it?"
        case .yearlyIncome:
            "Is that per year? Please tell me your monthly income."
        }
    }
}

extension BudgetIntent {
    /// Reads a tool call and checks it against the user's message. The app
    /// and the AssistantEval tool both go through here.
    static func checked(name: String, arguments: [String: Any], message: String) -> Result<Self, CallRejection> {
        guard let intent = BudgetIntent(name: name, arguments: arguments) else {
            return .failure(.unreadable(tool: name))
        }
        guard intent.isBacked(by: message) else { return .failure(.amountNotInMessage) }
        if case .setIncome = intent, isYearly(message) {
            return .failure(.yearlyIncome)
        }
        return .success(intent)
    }

    /// The names of `tools`, for spotting calls the model wrote as text.
    static let toolNames: Set<String> = Set(tools.compactMap {
        ($0["function"] as? [String: any Sendable])?["name"] as? String
    })

    /// "85000 a year", "Jahreslohn 78'000", "par an": the model saves these
    /// as monthly income however the prompt puts it.
    static func isYearly(_ message: String) -> Bool {
        message.contains(#/(?i)\b(year|annual|jahr|jährlich|johr|annuel|par an|p\.\s?a\.)/#)
    }
}

/// A tool call the model wrote into its reply instead of making it, like
/// `get_budget()` or `delete_expense{match: "Coop"}`. Without this the user
/// would see the call as text.
struct WrittenToolCall {
    let name: String
    let arguments: [String: Any]

    /// Nil unless the whole reply is one call to a known tool, so prose that
    /// mentions a tool stays prose.
    init?(_ reply: String, toolNames: Set<String> = BudgetIntent.toolNames) {
        let text = reply.trimmingCharacters(in: CharacterSet(charactersIn: "`").union(.whitespacesAndNewlines))
        guard let call = text.wholeMatch(of: #/(\w+)\s*[({](.*)[)}]/#.dotMatchesNewlines()),
              toolNames.contains(String(call.1))
        else { return nil }

        // Gemma's own call syntax sometimes leaks in: match:"|>taxi<|"<||>
        let body = String(call.2).replacing("<||>", with: "").replacing("<|", with: "").replacing("|>", with: "")
        var arguments: [String: Any] = [:]
        for pair in body.matches(of: #/(\w+)\s*[:=]\s*("[^"]*"|'[^']*'|[^,]+)/#) {
            let value = pair.2.trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
            let parsed: Any = if let number = Int(value) {
                number
            } else if let number = Double(value) {
                number
            } else {
                value
            }
            arguments[String(pair.1)] = parsed
        }
        name = String(call.1)
        self.arguments = arguments
    }
}
