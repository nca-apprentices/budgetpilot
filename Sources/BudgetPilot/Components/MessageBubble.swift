import SwiftUI

struct MessageBubble: View {
    let text: String
    @State private var isExpanded = false

    var body: some View {
        VStack {
            Text(text)
                .lineLimit(isExpanded ? nil : 6)

            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            }
        }
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
        MessageBubble(text: String(repeating: "Groceries at Migros and two train tickets. ", count: 8))
        MessageBubble(text: "Hi")
    }
}
