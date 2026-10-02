import SwiftUI

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.appLightBlue, .appOffWhite, .appLightPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}
