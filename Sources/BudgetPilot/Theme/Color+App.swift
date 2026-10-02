import SwiftUI

/// The app's colour palette. Defined in one place so a colour is never
/// written as a literal twice; the SwiftUI counterpart to CSS custom
/// properties.
extension Color {
    static let appLightBlue = Color(red: 0.80, green: 0.90, blue: 1.00)
    static let appOffWhite = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let appLightPurple = Color(red: 0.90, green: 0.85, blue: 1.00)
}
