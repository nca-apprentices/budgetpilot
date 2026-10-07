import SwiftUI

struct MessageBubble: View {
    let text: String
    @State private var isExpanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var collapsedHeight: CGFloat = 0

    var body: some View {
        VStack {
            Text(text)
                .lineLimit(isExpanded ? nil : 6)
                .background {
                    ZStack {
                        Text(text)
                            .fixedSize(horizontal: false, vertical: true)
                            .hidden()
                            .onGeometryChange(for: CGFloat.self) { proxy in
                                proxy.size.height
                            } action: { height in
                                fullHeight = height
                            }
                        Text(text)
                            .lineLimit(6)
                            .fixedSize(horizontal: false, vertical: true)
                            .hidden()
                            .onGeometryChange(for: CGFloat.self) { proxy in
                                proxy.size.height
                            } action: { height in
                                collapsedHeight = height
                            }
                    }
                }

            if fullHeight > collapsedHeight {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .accessibilityLabel(isExpanded ? "Show less" : "Show more")
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
        VStack(spacing: 8) {
            MessageBubble(text: String(repeating: "Groceries at Migros and two train tickets. ", count: 8))
            MessageBubble(text: "Hi")
        }
    }
}
