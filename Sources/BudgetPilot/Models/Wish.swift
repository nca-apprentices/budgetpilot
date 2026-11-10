import Foundation
import SwiftData

/// A product saved from a price search.
@Model
final class Wish {
    var title: String
    /// Cheapest offer incl. shipping on the day it was saved; not updated afterwards.
    var price: Decimal
    /// Toppreise links a product to the same page in every search, so this
    /// keeps one product from being saved twice.
    @Attribute(.unique) var url: URL
    var addedAt: Date

    init(offer: PriceOffer, addedAt: Date = .now) {
        title = offer.title
        price = offer.price
        url = offer.url
        self.addedAt = addedAt
    }
}
