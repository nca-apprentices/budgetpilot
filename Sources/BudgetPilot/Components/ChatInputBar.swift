import SwiftUI

/// The chat composer. Only the send button is wired up for now.
struct ChatInputBar: View {
    @State private var text = ""
    @State private var selectedInputMode: InputMode = .addWithAI
    @State private var selectedAnswerMode: AnswerMode = .aiAnalysis
    var isFocused: FocusState<Bool>.Binding
    /// False while the model loads or a reply is pending.
    var canSend = true
    var onSend: (String) -> Void

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    TextField(selectedInputMode.placeholder, text: $text)
                        .focused(isFocused)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 6)

                    if !text.isEmpty {
                        GlassIconButton(systemImage: "arrow.up", prominent: true) {
                            onSend(text)
                            text = ""
                        }
                        .accessibilityLabel("Send text")
                        .disabled(!canSend)
                    }
                }
                .animation(.default, value: text.isEmpty)

                HStack(spacing: 8) {
                    GlassIconButton(systemImage: "plus").accessibilityLabel("Add receipt")
                    GlassMenuButton(systemImage: selectedInputMode.systemImage, title: selectedInputMode.title) {
                        Section("Input mode") {
                            ForEach(InputMode.allCases, id: \.self) { mode in
                                // A Picker drops the header and subtitles on iOS, a Toggle keeps them
                                // and still shows the checkmark.
                                Toggle(isOn: Binding(
                                    get: { selectedInputMode == mode },
                                    set: { _ in selectedInputMode = mode }
                                )) {
                                    Text(mode.title)
                                    Text(mode.subtitle)
                                    Image(systemName: mode.systemImage)
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)

                    GlassIconMenu {
                        Section("Answer mode") {
                            ForEach(AnswerMode.allCases, id: \.self) { mode in
                                Toggle(isOn: Binding(
                                    get: { selectedAnswerMode == mode },
                                    set: { _ in selectedAnswerMode = mode }
                                )) {
                                    Text(mode.title)
                                    Text(mode.subtitle)
                                    Image(systemName: mode.systemImage)
                                }
                            }
                        }
                    } label: {
                        BudgetRing()
                    }
                    .accessibilityLabel("Answer mode")
                    GlassIconButton(systemImage: "mic").accessibilityLabel("Dictate")
                    GlassIconButton(systemImage: "waveform", prominent: true).accessibilityLabel("Talk to assistant")
                }
            }
            .padding(14)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
        }
        .tint(.appAccent)
        .foregroundStyle(.primary)
    }
}

#Preview {
    @Previewable @FocusState var isFocused: Bool

    ZStack(alignment: .bottom) {
        AppBackground()
        ChatInputBar(isFocused: $isFocused) { _ in }.padding(16)
    }
}
