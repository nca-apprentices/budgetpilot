import SwiftUI

struct TopBar: View {
    @Binding var selection: AppTab

    var body: some View {
        ZStack {
            TabSwitch(selection: $selection)

            HStack {
                GlassIconButton(systemImage: "line.3.horizontal")
                    .accessibilityLabel("Menu")

                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    @Previewable @State var tab: AppTab = .chat
    ZStack {
        AppBackground()
        TopBar(selection: $tab)
    }
}
