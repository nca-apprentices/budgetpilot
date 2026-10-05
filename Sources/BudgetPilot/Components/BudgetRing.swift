import SwiftUI

/// Ring with a filled centre and a partial arc, as drawn in the design.
/// Not an SF Symbol, so it is built from shapes.
struct BudgetRing: View {
    var progress: Double = 0.25

    var body: some View {
        ZStack {
            Circle()
                .stroke(.tertiary, lineWidth: 1.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.appAccent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(Color.appAccent)
                .frame(width: 4)
        }
        .frame(width: 18, height: 18)
    }
}

#Preview {
    HStack(spacing: 16) {
        BudgetRing(progress: 0.25)
        BudgetRing(progress: 0.6)
        BudgetRing(progress: 1)
    }
    .padding()
}
