import SwiftUI

/// Glass pill that confirms an action and offers to undo it.
struct UndoToast: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.appSuccess)
            Text(message)
            Button("Undo", action: onUndo)
                .buttonStyle(.glass)
                .tint(Color.appAccent)
        }
        .fontWeight(.semibold)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
    }
}

#Preview {
    ZStack {
        AppBackground()
        UndoToast(message: "Expense deleted") {}
    }
}
