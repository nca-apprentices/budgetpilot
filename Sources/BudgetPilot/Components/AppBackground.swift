import SwiftUI

struct AppBackground: View {
    private let lightBlue = Color(red: 0.80, green: 0.90, blue: 1.00)
    private let offWhite = Color(red: 0.97, green: 0.97, blue: 0.98)
    private let lightPurple = Color(red: 0.90, green: 0.85, blue: 1.00)

    var body: some View {
        LinearGradient(
            colors: [lightBlue, offWhite, lightPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}
