import SwiftUI

/// The chat composer. Buttons are deliberately inert for now.
struct ChatInputBar: View {
    @State private var text = ""

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    TextField("What did you buy?", text: $text)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 6)

                    if !text.isEmpty {
                        GlassIconButton(systemImage: "arrow.up", prominent: true).accessibilityLabel("Send text")
                    }
                }
                .animation(.default, value: text.isEmpty)

                HStack(spacing: 8) {
                    GlassIconButton(systemImage: "plus").accessibilityLabel("Add receipt")
                    GlassMenuButton(systemImage: "sparkles", title: "Add with AI")

                    Spacer(minLength: 0)

                    GlassIconButton { BudgetRing() }
                        .accessibilityLabel("Budget")
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
    ZStack(alignment: .bottom) {
        AppBackground()
        ChatInputBar().padding(16)
    }
}
