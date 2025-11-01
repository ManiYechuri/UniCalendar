import SwiftUI

struct LoadingOverlay: View {
    var text: String = "Syncing calendars…"
    var body: some View {
        ZStack {
            Color.black.opacity(0.06).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                Text(text).font(Typography.f14SemiBold).foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .shadow(radius: 8)
        }
    }
}

