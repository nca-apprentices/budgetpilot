import SwiftUI

/// One price search result.
struct PriceOfferRow: View {
    let offer: PriceOffer
    let isOnWishlist: Bool
    let onToggleWishlist: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(offer.title)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let offerCount = offer.offerCount {
                        Text(offerCount == 1 ? "1 offer" : "\(offerCount) offers")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Text(offer.price, format: .currency(code: "CHF"))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appAccent)
            }
            // Kept apart from the button so VoiceOver can still reach it.
            .accessibilityElement(children: .combine)

            WishlistHeartButton(isOnWishlist: isOnWishlist, action: onToggleWishlist)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .padding(.trailing, 60)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 8) {
            PriceOfferRow(
                offer: PriceOffer(
                    title: "HP USB-C-Ladegerät 65 W, USB-C, EU-Stecker (AJ7X5AA#ABB)",
                    price: 44.40,
                    offerCount: 2,
                    url: PriceSearchService.baseURL
                ),
                isOnWishlist: false
            ) {}
            PriceOfferRow(
                offer: PriceOffer(
                    title: "Apple MacBook Pro 14\"",
                    price: 1890,
                    offerCount: 1,
                    url: PriceSearchService.baseURL
                ),
                isOnWishlist: true
            ) {}
        }
        .padding(16)
    }
}
