import SwiftUI

/// Glass pill with a leading icon, a title and a chevron, used to open a
/// mode menu.
struct GlassMenuButton<Content: View>: View {
    let systemImage: String
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        Menu {
            content
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .lineLimit(1)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel(title)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .menuOrder(.fixed)
    }
}

#Preview {
    ZStack {
        AppBackground()
        GlassMenuButton(systemImage: "sparkles", title: "Add with AI") {
            Button("Option 1") {}
            Button("Option 2") {}
        }
    }
}
