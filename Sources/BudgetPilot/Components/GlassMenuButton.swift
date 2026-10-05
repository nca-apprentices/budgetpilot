import SwiftUI

/// Glass pill with a leading icon, a title and a chevron, used to open a
/// mode menu.
struct GlassMenuButton: View {
    let systemImage: String
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
    }
}

#Preview {
    ZStack {
        AppBackground()
        GlassMenuButton(systemImage: "sparkles", title: "KI eintragen")
    }
}
