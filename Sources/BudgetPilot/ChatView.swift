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
        }
    }
}

#Preview {
    ChatView()
}
