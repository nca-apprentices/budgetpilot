import Foundation
import SwiftData

enum Wishlist {
    /// Does nothing when the product is already on the wishlist, so the price
    /// it was first saved with is kept.
    static func add(_ offer: PriceOffer, in context: ModelContext, date: Date = .now) throws {
        let url = offer.url
        let saved = FetchDescriptor<Wish>(predicate: #Predicate { $0.url == url })
        guard try context.fetchCount(saved) == 0 else { return }
        context.insert(Wish(offer: offer, addedAt: date))
        try context.save()
    }

    static func remove(_ url: URL, in context: ModelContext) throws {
        try context.delete(model: Wish.self, where: #Predicate { $0.url == url })
        try context.save()
    }

    /// What the heart under a price search result does.
    static func toggle(_ offer: PriceOffer, in context: ModelContext, date: Date = .now) throws {
        let url = offer.url
        let saved = FetchDescriptor<Wish>(predicate: #Predicate { $0.url == url })
        if try context.fetchCount(saved) > 0 {
            try remove(url, in: context)
        } else {
            try add(offer, in: context, date: date)
        }
    }

    static func total(of wishes: [Wish]) -> Decimal {
        wishes.reduce(0) { $0 + $1.price }
    }

    /// How much more the wishes cost than the available budget; zero when they fit.
    static func shortfall(of wishes: [Wish], available: Decimal) -> Decimal {
        max(total(of: wishes) - available, 0)
    }
}
