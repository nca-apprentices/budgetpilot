import MLXLMCommon

/// How the model turns a sentence into a toppreise search term. Shared by the
/// app and the AssistantEval tool (`mise run eval -- --search-terms`), so the
/// eval measures what ships.
enum SearchTermSetup {
    /// The accessory example keeps the accessory in the term, so the search
    /// isn't for the phone itself. The model copies the example's accessory
    /// word ("coque", then "cover") for an English "case", so the example uses
    /// a rare one and the rules say to keep the user's word.
    static let instructions = """
    You turn a shopping request into a search term for a Swiss price comparison site. Users write in \
    English, German, Swiss German or French. Reply with the product only, using the user's own words: \
    brand, model, size or colour if given. Keep the words in the language the user wrote them; never \
    translate them. If it is an accessory, keep the user's exact word for the accessory and the device it \
    is for. Leave out prices, adjectives like "cheap", and who it is for. No sentence, no quotes, no \
    explanation.

    Examples:
    I'm looking for a cheap PS5 for my son -> PS5
    Ich suche günstige AirPods Pro 2 -> AirPods Pro 2
    wo gits de billigst Dyson V15? -> Dyson V15
    what does a Samsung 55 inch OLED TV cost -> Samsung 55 inch OLED TV
    a screen protector for my Galaxy S24 -> screen protector Galaxy S24
    """

    static let parameters = GenerateParameters(
        maxTokens: 24, // a product name is a few tokens; cuts a sentence short
        temperature: 0
    )
}
