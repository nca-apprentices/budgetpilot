import Foundation
import SwiftSoup

/// Looks up prices on toppreise.ch. Toppreise has no public API, so this reads
/// the search results page; if the markup changes, `parse` returns no offers
/// and `PriceSearchServiceTests` shows which selector broke.
struct PriceSearchService {
    static let baseURL = URL(string: "https://www.toppreise.ch")!

    var session: URLSession = .shared

    func search(_ query: String) async throws -> [PriceOffer] {
        let (data, response) = try await session.data(from: Self.searchURL(for: query))
        if let status = (response as? HTTPURLResponse)?.statusCode, status != 200 {
            throw PriceSearchError.unavailable(statusCode: status)
        }
        guard let html = String(data: data, encoding: .utf8) else { throw PriceSearchError.unreadablePage }
        return try Self.parse(html)
    }

    static func searchURL(for query: String) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = "/produktsuche"
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        return components.url!
    }

    /// Offers in the order toppreise ranks them, which is by relevance: sorting
    /// by price would put cases and cables above the product itself.
    ///
    /// Toppreise groups variants of one product (PS5 Slim Digital, 825 GB and
    /// 1 TB) into a series. Each series counts as one result with its cheapest
    /// variant, so a popular product doesn't fill all the places shown.
    static func parse(_ html: String) throws -> [PriceOffer] {
        let document = try SwiftSoup.parse(html)
        let entries = try document.select(".Plugin_ProductCollItem, .Plugin_Product[data-link]:not(.f_collection)")
        var offers: [PriceOffer] = []
        for entry in entries.array() {
            let candidates = entry.hasClass("Plugin_ProductCollItem")
                ? try entry.select(".Plugin_Product[data-link]").array().compactMap(offer(from:))
                : try [offer(from: entry)].compactMap { $0 }
            guard let offer = candidates.min(by: { $0.price < $1.price }),
                  !offers.contains(where: { $0.url == offer.url })
            else { continue }
            offers.append(offer)
        }
        return offers
    }

    /// "4'529.00", "CHF 39.50" or "12.–" → the amount in CHF.
    static func parsePrice(_ text: String) -> Decimal? {
        let digits = text
            .replacingOccurrences(of: ".–", with: "")
            .replacingOccurrences(of: ".-", with: "")
            .filter { $0.isASCII && ($0.isNumber || $0 == ".") }
        guard !digits.isEmpty else { return nil }
        return Decimal(string: digits, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func offer(from product: Element) throws -> PriceOffer? {
        let link = try product.attr("data-link")
        // Products inside a series have no .product-name; both kinds put the
        // name in a bold link.
        let title = try product.select("a.bold").first()?.text() ?? ""
        // Including shipping is what the user actually pays; fall back to the
        // bare product price when the page shows only that.
        let priceText = try product.select(".shippingPrice .Plugin_Price").first()?.text()
            ?? product.select(".Plugin_Price").first()?.text()
        guard !title.isEmpty,
              let price = priceText.flatMap(parsePrice),
              let url = URL(string: link, relativeTo: baseURL)?.absoluteURL
        else { return nil }
        let offersLabel = try product.select(".offersLabel").first()?.text() ?? ""
        let offerCount = offersLabel.split(separator: " ").first.flatMap { Int($0) }
        return PriceOffer(title: title, price: price, offerCount: offerCount, url: url)
    }
}

enum PriceSearchError: LocalizedError {
    case unavailable(statusCode: Int)
    case unreadablePage

    var errorDescription: String? {
        switch self {
        case let .unavailable(statusCode):
            "toppreise.ch is not answering right now (HTTP \(statusCode)). Try again later."
        case .unreadablePage:
            "toppreise.ch sent a page that could not be read."
        }
    }
}
