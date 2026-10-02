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
                    Button {} label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)

                    Button {} label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("KI eintragen")
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)

                    Spacer(minLength: 0)

                    Button {} label: {
                        BudgetRing()
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)

                    Button {} label: {
                        Image(systemName: "mic")
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)

                    Button {} label: {
                        Image(systemName: "waveform")
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                }
            }
            .padding(14)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
        }
        .tint(.appAccent)
        .foregroundStyle(.primary)
    }
}

/// Ring with a filled centre and a partial arc, as drawn in the design.
private struct BudgetRing: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(.tertiary, lineWidth: 1.5)
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Color.appAccent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(Color.appAccent)
                .frame(width: 4)
        }
        .frame(width: 18, height: 18)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppBackground()
        ChatInputBar().padding(16)
    }
}
