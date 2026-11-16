@testable import BudgetPilot
import Testing

struct SearchTermTests {
    @Test func keepsTermFromUsersWords() {
        #expect(SearchTerm.checked("AirPods Pro 2", in: "Ich suche günstige AirPods Pro 2") == "AirPods Pro 2")
    }

    @Test func ignoresCaseAndAccents() {
        #expect(SearchTerm.checked("Gunstige PS5", in: "günstige ps5 bitte") == "Gunstige PS5")
    }

    @Test func dropsInventedWords() {
        #expect(SearchTerm.checked("iPhone 16", in: "a case for my iPhone 15") == nil)
    }

    @Test func dropsASentence() {
        #expect(SearchTerm.checked("Here is the search term: PS5", in: "I want a cheap PS5") == nil)
    }

    @Test func dropsAnEmptyReply() {
        #expect(SearchTerm.checked("  \n", in: "I want a cheap PS5") == nil)
    }

    @Test func dropsTooManyWords() {
        let input = "one two three four five six seven eight nine"
        #expect(SearchTerm.checked(input, in: input) == nil)
    }

    @Test func stripsQuotesAndFullStop() {
        #expect(SearchTerm.checked("\"PS5\".", in: "cheap PS5 please") == "PS5")
    }

    @Test(arguments: ["PS5", "Dyson V15", "AirPods Pro 2"])
    func shortInputSkipsModel(_ text: String) {
        #expect(SearchTerm.isShortEnough(text))
    }

    @Test func sentenceGoesToModel() {
        #expect(!SearchTerm.isShortEnough("I'm looking for a cheap PS5"))
    }
}
