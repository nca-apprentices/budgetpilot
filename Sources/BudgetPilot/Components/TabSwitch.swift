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
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var tab: AppTab = .chat
    TabSwitch(selection: $tab)
}
