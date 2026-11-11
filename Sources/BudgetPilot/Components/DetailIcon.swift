import SwiftUI

/// White symbol on a coloured rounded square, as used in the expense details.
struct DetailIcon: View {
    let systemImage: String
    let color: Color

    var body: some View {
        Image(systemName: systemImage)
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color, in: .rect(cornerRadius: 8))
    }
}

#Preview {
    HStack {
        DetailIcon(systemImage: "tag", color: .appDetailCategory)
        DetailIcon(systemImage: "calendar", color: .appDetailDate)
    }
}
