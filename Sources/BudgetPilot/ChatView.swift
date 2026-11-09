import SwiftData
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
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var inputMode: InputMode = .addWithAI
    private let priceSearch = PriceSearchService()

    private var canSend: Bool {
        guard pendingStatus == nil else { return false }
        return switch inputMode {
        case .addWithAI: assistant.isLoaded || loadFailed
        case .priceSearch: true
        }
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack {
                if selectedTab == .chat {
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
                                    ForEach(message.offers.prefix(5)) { offer in
                                        PriceOfferRow(offer: offer)
                                    }
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
                } else {
                    BudgetView()
                }
            }
            .contentShape(.rect)
            .onTapGesture { isInputFocused = false }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                TopBar(selection: $selectedTab)
                    .padding(.top, 8)
            }
            .safeAreaInset(edge: .bottom) {
                if selectedTab == .chat {
                    ChatInputBar(
                        text: $inputText,
                        selectedInputMode: $inputMode,
                        isFocused: $isInputFocused,
                        canSend: canSend
                    ) { text in
                        messages.append(ChatMessage(text: text, isFromUser: true))
                        switch inputMode {
                        case .addWithAI: askAssistant(text)
                        case .priceSearch: searchPrices(for: text)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .onChange(of: selectedTab) {
            isInputFocused = false
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

    private func askAssistant(_ text: String) {
        pendingStatus = assistant.isLoaded
            ? "Thinking…"
            : "Loading the model. The first time it downloads several GB, which can take a few minutes."
        Task {
            defer { pendingStatus = nil }
            do {
                let replies = try await assistant.respond(to: text, in: modelContext)
                messages.append(contentsOf: replies)
            } catch {
                messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", isFromUser: false))
            }
        }
    }

    /// Skips the model on purpose: it rewrites numbers wrongly, so prices go
    /// straight from the page to the screen.
    private func searchPrices(for query: String) {
        pendingStatus = "Searching toppreise.ch…"
        Task {
            defer { pendingStatus = nil }
            do {
                let offers = try await priceSearch.search(query)
                messages.append(ChatMessage(
                    text: offers.isEmpty
                        ? "Nothing found on toppreise.ch for “\(query)”."
                        : "Best matches on toppreise.ch, cheapest offer incl. shipping:",
                    isFromUser: false,
                    offers: offers
                ))
            } catch {
                messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", isFromUser: false))
            }
        }
    }

    private func confirm(_ proposal: Proposal, from message: Binding<ChatMessage>) {
        do {
            switch proposal {
            case let .add(expense): try expense.save(in: modelContext)
            case let .edit(edit): try edit.apply(in: modelContext)
            case let .delete(deletion): try deletion.apply(in: modelContext)
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
