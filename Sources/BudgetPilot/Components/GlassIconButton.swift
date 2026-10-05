import SwiftUI

/// Circular glass button around an icon. `prominent` gives the filled,
/// tinted variant used for the primary action.
struct GlassIconButton<Label: View>: View {
    var prominent = false
    var action: () -> Void = {}
    @ViewBuilder var label: Label

    var body: some View {
        if prominent {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }

    private var button: some View {
        Button(action: action) { label }
            .buttonBorderShape(.circle)
    }
}

extension GlassIconButton where Label == Image {
    /// Convenience for the common case of an SF Symbol.
    init(systemImage: String, prominent: Bool = false, action: @escaping () -> Void = {}) {
        self.init(prominent: prominent, action: action) {
            Image(systemName: systemImage)
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack(spacing: 8) {
            GlassIconButton(systemImage: "plus")
            GlassIconButton(systemImage: "mic")
            GlassIconButton(systemImage: "waveform", prominent: true)
        }
        .tint(.appAccent)
    }
}
