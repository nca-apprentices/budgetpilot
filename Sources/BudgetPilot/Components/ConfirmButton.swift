import SwiftUI

/// Sits under an assistant bubble that proposes something. Nothing happens
/// until the user taps it.
struct ConfirmButton: View {
    let title: String
    let doneTitle: String
    let isDone: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isDone ? doneTitle : title, systemImage: isDone ? "checkmark" : "plus")
        }
        .buttonStyle(.glass)
        .disabled(isDone)
        .padding(.trailing, 60)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 8) {
            ConfirmButton(title: "Save", doneTitle: "Saved", isDone: false) {}
            ConfirmButton(title: "Apply", doneTitle: "Changed", isDone: true) {}
        }
    }
}
