import Foundation

/// Checks on the search term the model picks for price search.
enum SearchTerm {
    /// Short input is already a search term; the model would only slow it down.
    static func isShortEnough(_ text: String) -> Bool {
        words(in: text).count <= 3
    }

    /// The model's term, if it's made only of words the user typed. Anything
    /// else, like "iPhone 15" coming back as "iPhone 16", is dropped so the
    /// raw text is searched instead.
    static func checked(_ reply: String, in input: String) -> String? {
        let term = reply
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'“”„«».,!?"))
            .trimmingCharacters(in: .whitespaces)
        let termWords = words(in: term)
        guard !termWords.isEmpty, termWords.count <= 8 else { return nil }
        let inputWords = Set(words(in: input))
        guard termWords.allSatisfy(inputWords.contains) else { return nil }
        return term
    }

    /// Lowercased and without accents, so "Günstige" matches "gunstige".
    private static func words(in text: String) -> [String] {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }
}
