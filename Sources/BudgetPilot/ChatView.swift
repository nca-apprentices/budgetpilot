import SwiftUI

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var selectedTab: AppTab = .chat

    var body: some View {
        ZStack {
            AppBackground()

            VStack {
                if messages.isEmpty {
                    Text("How can I help you with your budget?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(messages) { message in
                                MessageBubble(text: message.text)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .defaultScrollAnchor(.bottom)
                    .scrollEdgeEffectStyle(.hard, for: .top)
                }
            }.safeAreaInset(edge: .top) {
                TopBar(selection: $selectedTab)
                    .padding(.top, 8)
            }
            .safeAreaInset(edge: .bottom) {
                ChatInputBar { text in
                    messages.append(ChatMessage(text: text))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }
}

#Preview {
    ChatView()
}
