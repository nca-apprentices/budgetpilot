import SwiftUI

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var messages: [ChatMessage] = []
    @State private var selectedTab: AppTab = .chat
    @State private var assistant = AssistantModel()
    /// Lets the user retry by sending after the model failed to load.
    @State private var loadFailed = false
    /// Shown as a placeholder bubble while a reply is on its way.
    @State private var pendingStatus: String?

    var body: some View {
        ZStack {
            AppBackground()

            VStack {
                if messages.isEmpty {
                    if !assistant.isLoaded {
                        ModelLoadingView(progress: assistant.loadProgress)
                            .frame(maxHeight: .infinity)
                    } else {
                        Text("How can I help you with your budget?")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxHeight: .infinity)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach($messages) { $message in
                                MessageBubble(text: message.text, isFromUser: message.isFromUser)
                                if let proposal = message.proposal {
                                    ConfirmButton(
                                        title: proposal.confirmTitle,
                                        doneTitle: proposal.doneTitle,
                                        isDone: message.isConfirmed
                                    ) {
                                        confirm(proposal, from: $message)
                                    }
                                }
                            }
                            if let pendingStatus {
                                PendingBubble(text: pendingStatus)
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
                ChatInputBar(canSend: (assistant.isLoaded || loadFailed) && pendingStatus == nil) { text in
                    messages.append(ChatMessage(text: text, isFromUser: true))
                    pendingStatus = assistant.isLoaded
                        ? "Thinking…"
                        : "Loading the model. The first time it downloads several GB, which can take a few minutes."
                    Task {
                        defer { pendingStatus = nil }
                        do {
                            let replies = try await assistant.respond(to: text, in: modelContext)
                            messages.append(contentsOf: replies)
                        } catch {
                            messages.append(ChatMessage(
                                text: "Error: \(error.localizedDescription)",
                                isFromUser: false
                            ))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .task {
            do {
                try await assistant.load()
            } catch {
                messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", isFromUser: false))
                loadFailed = true
            }
        }
    }

    private func confirm(_ proposal: Proposal, from message: Binding<ChatMessage>) {
        do {
            switch proposal {
            case let .add(expense): try expense.save(in: modelContext)
            case let .edit(edit): try edit.apply(in: modelContext)
            }
            message.wrappedValue.isConfirmed = true
        } catch {
            messages.append(ChatMessage(
                text: "Error: \(error.localizedDescription)",
                isFromUser: false
            ))
        }
    }
}

#Preview {
    ChatView()
}
