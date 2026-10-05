import SwiftUI

struct ChatView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()
            ChatInputBar()
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
    }
}

#Preview {
    ChatView()
}
