import SwiftUI

struct ChatView: View {
    var body: some View {
        ZStack {
            AppBackground()

            Text("How can I help you with your budget?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            ChatInputBar()
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        }
    }
}

#Preview {
    ChatView()
}
