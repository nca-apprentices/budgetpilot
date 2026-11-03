/// What the model should do with a message. Only the last turn is scored;
/// earlier turns set up the conversation.
enum Expected {
    /// Answer in text, or make a call the app rejects (it then asks the user).
    case reply
    /// Call this tool. Argument checks: `amount` compares numbers, `title` and
    /// `new_title` must contain one of the `|`-separated words, anything else
    /// must equal one of them. All case-insensitive.
    case call(String, [String: String] = [:])
    /// Call these tools, in this order, each accepted by the app.
    case calls([String])
}

struct EvalCase {
    let id: String
    let turns: [String]
    let expected: Expected

    init(_ id: String, _ turns: String..., expect expected: Expected) {
        self.id = id
        self.turns = turns
        self.expected = expected
    }
}

/// The intents of issue 57, in the languages users write in.
let cases: [EvalCase] = [
    // Add expense
    EvalCase("issue-add", "Sony WH-1000XM5 headphones for 299",
             expect: .call("add_expense", ["title": "sony|headphones", "amount": "299", "category": "leisure|other"])),
    EvalCase("add-en", "I bought groceries at Coop for 45.30",
             expect: .call("add_expense", ["title": "coop", "amount": "45.3", "category": "groceries"])),
    EvalCase("add-de", "Habe im Migros für 23.50 eingekauft",
             expect: .call("add_expense", ["title": "migros", "amount": "23.5", "category": "groceries"])),
    EvalCase("add-ch", "Ha grad 12 Stutz für es Kafi usgeh",
             expect: .call("add_expense", ["amount": "12", "category": "leisure|groceries|other"])),
    EvalCase("add-sbb", "SBB Halbtax 190",
             expect: .call("add_expense", ["amount": "190", "category": "transport"])),
    EvalCase("add-netflix", "Paid Netflix, 18.90",
             expect: .call("add_expense", ["title": "netflix", "amount": "18.9", "category": "subscriptions"])),
    EvalCase("add-rent", "Miete bezahlt: 1850 CHF",
             expect: .call("add_expense", ["amount": "1850", "category": "housing"])),
    EvalCase("add-doctor", "Doctor's appointment cost me 120 francs",
             expect: .call("add_expense", ["amount": "120", "category": "health"])),
    EvalCase("add-count", "I bought 2 coffees for 9.80",
             expect: .call("add_expense", ["title": "coffee", "amount": "9.8", "category": "leisure|groceries|other"])),
    EvalCase("add-fr", "J'ai payé 35 francs pour le coiffeur",
             expect: .call("add_expense", ["amount": "35", "category": "other|health"])),
    EvalCase("add-short", "Coop 20",
             expect: .call("add_expense", ["title": "coop", "amount": "20", "category": "groceries"])),
    EvalCase("add-bill", "Swisscom Abo 49.90/Monat",
             expect: .call("add_expense", ["amount": "49.9", "category": "subscriptions"])),
    EvalCase("add-comma", "Pizza 12,50",
             expect: .call("add_expense", ["title": "pizza", "amount": "12.5", "category": "leisure|groceries|other"])),
    EvalCase("add-two", "Coop 30 and SBB 12", expect: .calls(["add_expense", "add_expense"])),
    EvalCase("add-noamount", "I bought new shoes", expect: .reply),
    EvalCase("add-noamount-de", "I went to the dentist", expect: .reply),
    EvalCase("add-followup", "I bought new shoes", "120",
             expect: .call("add_expense", ["title": "shoes", "amount": "120", "category": "other|leisure"])),

    // Edit expense
    EvalCase("issue-edit", "the headphones were 279",
             expect: .call("edit_expense", ["match": "headphones", "amount": "279"])),
    EvalCase("edit-amount", "Change the Coop expense to 48.20",
             expect: .call("edit_expense", ["match": "coop", "amount": "48.2"])),
    EvalCase("edit-cat", "The Migros one was actually transport, not groceries",
             expect: .call("edit_expense", ["match": "migros", "category": "transport"])),
    EvalCase("edit-title-de", "Benenn den Denner Einkauf in Lidl um",
             expect: .call("edit_expense", ["match": "denner", "new_title": "lidl"])),
    EvalCase("edit-one", "the Coop one was 54",
             expect: .call("edit_expense", ["match": "coop", "amount": "54"])),
    EvalCase("edit-not", "oops, the lunch was 23.50 not 21.50",
             expect: .call("edit_expense", ["match": "lunch", "amount": "23.5"])),
    // Needs the earlier tool call in the history.
    EvalCase("edit-after-add", "Lunch at Tibits 21.50", "oops, the lunch was 23.50 not 21.50",
             expect: .call("edit_expense", ["match": "lunch|tibits|tibits lunch|lunch at tibits", "amount": "23.5"])),
    EvalCase("edit-vague", "Change that to 30", expect: .reply),

    // Delete expense
    EvalCase("issue-delete", "delete yesterday's lunch",
             expect: .call("delete_expense", ["match": "lunch"])),
    EvalCase("delete-de", "Lösch den Coop Einkauf",
             expect: .call("delete_expense", ["match": "coop"])),
    EvalCase("delete-ch", "lösch bitte de zug",
             expect: .call("delete_expense", ["match": "zug"])),
    EvalCase("delete-vague", "Delete it", expect: .reply),

    // Set income or fixed costs
    EvalCase("issue-income", "my income is 5000 a month",
             expect: .call("set_income", ["amount": "5000"])),
    EvalCase("income-de", "Ich verdiene 7200 im Monat",
             expect: .call("set_income", ["amount": "7200"])),
    EvalCase("income-apos", "Mein Lohn ist 6'500 CHF",
             expect: .call("set_income", ["amount": "6500"])),
    EvalCase("income-yearly", "I earn 85000 a year", expect: .reply),
    EvalCase("issue-fixed", "my fixed costs are 1920",
             expect: .call("set_fixed_costs", ["amount": "1920"])),
    EvalCase("fixed-de", "Meine Fixkosten sind 2'100 Franken",
             expect: .call("set_fixed_costs", ["amount": "2100"])),

    // Ask
    EvalCase("issue-left", "how much is left?", expect: .call("get_budget")),
    EvalCase("issue-where", "where did my money go?", expect: .call("get_budget")),
    EvalCase("left-de", "Wie viel habe ich diesen Monat noch?", expect: .call("get_budget")),
    EvalCase("left-ch", "wievill han i no?", expect: .call("get_budget")),
    EvalCase("get-en", "What is my income?", expect: .call("get_income")),
    EvalCase("get-de", "Wie viel verdiene ich?", expect: .call("get_income")),

    // Chat
    EvalCase("chat-tip", "How can I save money on groceries?", expect: .reply),
    EvalCase("chat-hi", "Hoi!", expect: .reply),
]
