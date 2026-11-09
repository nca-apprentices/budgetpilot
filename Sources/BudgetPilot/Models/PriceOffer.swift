import Foundation

/// A product found by price search, with its cheapest offer as listed on
/// toppreise.ch.
struct PriceOffer: Identifiable, Equatable {
    let title: String
    /// Cheapest offer including shipping, in CHF. Taken from the page as is,
    /// never written by the model.
    let price: Decimal
    let offerCount: Int?
    /// The product's toppreise.ch page. Not opened from the app; it identifies
    /// the product because it stays the same across searches.
    let url: URL

    var id: URL {
        url
    }
}
