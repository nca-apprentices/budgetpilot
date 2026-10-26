import SwiftUI

/// Sits under an assistant bubble that proposes an expense. The expense is
/// stored only when the user taps it.
struct SaveExpenseButton: View {
    let isSaved: Bool
    let save: () -> Void

    var body: some View {
        Button(action: save) {
            Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "checkmark" : "plus")
        }
        .buttonStyle(.glass)
        .disabled(isSaved)
        .padding(.trailing, 60)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 8) {
            SaveExpenseButton(isSaved: false) {}
            SaveExpenseButton(isSaved: true) {}
        }
    }
}
