import SwiftUI

/// The chat composer. Buttons are deliberately inert for now.
struct ChatInputBar: View {
    @State private var text = ""

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(alignment: .leading, spacing: 14) {
                TextField("Was hast du ausgegeben?", text: $text)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 6)

                HStack(spacing: 8) {
                    GlassIconButton(systemImage: "plus")
                    GlassMenuButton(systemImage: "sparkles", title: "KI eintragen")

                    Spacer(minLength: 0)

                    GlassIconButton { BudgetRing() }
                        .accessibilityLabel("Budget")
                    GlassIconButton(systemImage: "mic")
                    GlassIconButton(systemImage: "waveform", prominent: true)
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
