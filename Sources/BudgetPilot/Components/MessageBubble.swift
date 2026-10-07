import SwiftUI

struct MessageBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: .rect(cornerRadius: 25))
            .padding(.leading, 60)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

#Preview {
    ZStack {
        AppBackground()
        MessageBubble(text: "Groceries at Migros, a new phone case and two train tickets to Zurich for the weekend")
    }
}
