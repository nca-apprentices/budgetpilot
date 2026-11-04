import SwiftUI

/// Round glass button like `GlassIconButton`, but opens a menu instead of
/// running an action.
struct GlassIconMenu<Content: View, Label: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var label: Label

    var body: some View {
        Menu {
            content
        } label: {
            label
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .menuOrder(.fixed)
    }
}

#Preview {
    ZStack {
        AppBackground()
        GlassIconMenu {
            Button("Option 1") {}
            Button("Option 2") {}
        } label: {
            BudgetRing()
        }
    }
}
