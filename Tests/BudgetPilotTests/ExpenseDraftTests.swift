@testable import BudgetPilot
import Foundation
import SwiftData
import Testing

struct ExpenseDraftTests {
    private let context: ModelContext
    private let expense: Expense

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        context = try ModelContext(ModelContainer(for: Expense.self, configurations: config))
        expense = Expense(
            title: "Lunch",
            amount: 25,
            category: .other,
            date: Date(timeIntervalSince1970: 1_800_000_000)
        )
        context.insert(expense)
        try context.save()
    }

    @Test
    func savesAllChangedFields() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        var draft = ExpenseDraft(expense)
        draft.title = "Lunch Migros"
        draft.amount = try #require(Decimal(string: "23.50"))
        draft.category = .groceries
        draft.date = date
        draft.paymentMethod = .card
        draft.note = "Typo by assistant"

        try draft.apply(to: expense, in: context)

        let saved = try #require(try context.fetch(FetchDescriptor<Expense>()).first)
        #expect(saved.title == "Lunch Migros")
        #expect(saved.amount == Decimal(string: "23.50"))
        #expect(saved.category == .groceries)
        #expect(saved.date == date)
        #expect(saved.paymentMethod == .card)
        #expect(saved.note == "Typo by assistant")
        #expect(saved.isCorrected)
    }

    @Test
    func storesAnEmptyNoteAsNone() throws {
        expense.note = "Via chat"
        var draft = ExpenseDraft(expense)
        draft.note = "  "

        try draft.apply(to: expense, in: context)

        #expect(expense.note == nil)
    }

    @Test
    func droppingADraftKeepsTheOldValues() {
        var draft = ExpenseDraft(expense)
        draft.title = "Dinner"
        draft.amount = 99

        #expect(expense.title == "Lunch")
        #expect(expense.amount == 25)
    }

    @Test(arguments: [Decimal(0), Decimal(-5)])
    func refusesAnAmountOfZeroOrLess(amount: Decimal) {
        var draft = ExpenseDraft(expense)
        draft.amount = amount

        #expect(!draft.canSave)
        #expect(throws: ExpenseDraftError.invalidAmount) {
            try draft.apply(to: expense, in: context)
        }
        #expect(expense.amount == 25)
    }

    @Test
    func refusesAnEmptyTitle() {
        var draft = ExpenseDraft(expense)
        draft.title = "   "

        #expect(!draft.canSave)
        #expect(throws: ExpenseDraftError.emptyTitle) {
            try draft.apply(to: expense, in: context)
        }
        #expect(expense.title == "Lunch")
    }
}
