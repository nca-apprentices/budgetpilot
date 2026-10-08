import SwiftUI

struct TabSwitch: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation {
                        selection = tab
                    }
                } label: {
                    Text(tab.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(selection == tab ? .primary : .secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background {
                            if selection == tab {
                                Capsule().fill(Color.appSegmentSelected)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .glassEffect(.regular, in: .capsule)
    }
}

#Preview {
    @Previewable @State var tab: AppTab = .chat
    ZStack {
        AppBackground()
        TabSwitch(selection: $tab)
    }
}
