import SwiftUI

/// One row of a details list: a coloured icon, a label and its value.
struct DetailRow: View {
    let systemImage: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            DetailIcon(systemImage: systemImage, color: color)
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack {
        DetailRow(systemImage: "tag", color: .appDetailCategory, title: "Category", value: "Leisure")
        DetailRow(systemImage: "calendar", color: .appDetailDate, title: "Date", value: "23 Sep 2026")
    }
    .padding()
}
