import SwiftUI

struct WishRow: View {
    let wish: Wish
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                // Not a heart: that would sit next to the heart button and look
                // like a second one.
                Image(systemName: "bag.fill")
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.appAccent, in: .rect(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(wish.title)
                        .font(.headline)
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Text("Saved")
                        Text(wish.addedAt, format: .dateTime.day().month())
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text(wish.price, format: .number.precision(.fractionLength(2)))
                    .font(.headline)
            }
            // Kept apart from the button so VoiceOver can still reach it.
            .accessibilityElement(children: .combine)

            WishlistHeartButton(isOnWishlist: true, action: onRemove)
        }
    }
}

#Preview {
    WishRow(wish: Wish(offer: PriceOffer(
        title: "SONY Playstation 5 Slim Digital Edition",
        price: 549,
        offerCount: 14,
        url: PriceSearchService.baseURL
    ))) {}
        .padding()
}
