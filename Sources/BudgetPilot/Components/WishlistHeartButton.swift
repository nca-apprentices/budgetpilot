import SwiftUI

/// Filled when the product is on the wishlist; a tap adds or removes it.
struct WishlistHeartButton: View {
    let isOnWishlist: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isOnWishlist ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundStyle(Color.appAccent)
                .contentTransition(.symbolEffect(.replace))
                // Taller than the symbol so it's easy to hit; kept narrow so
                // product names in the chat keep their room.
                .frame(width: 32, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOnWishlist ? "Remove from wishlist" : "Add to wishlist")
    }
}

#Preview {
    HStack {
        WishlistHeartButton(isOnWishlist: false) {}
        WishlistHeartButton(isOnWishlist: true) {}
    }
}
