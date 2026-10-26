import SwiftUI

/// Download progress of the on-device model, shown while the app starts.
struct ModelLoadingView: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 12) {
            Text(progress < 1 ? "Downloading the assistant…" : "Preparing the assistant…")
                .foregroundStyle(.secondary)
            ProgressView(value: progress)
            Text(progress, format: .percent.precision(.fractionLength(0)))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .glassEffect(.regular, in: .rect(cornerRadius: 25))
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        AppBackground()
        ModelLoadingView(progress: 0.42)
    }
}
