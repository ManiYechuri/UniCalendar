import SwiftUI

struct AccountRowView: View {
    let account: SyncAccount

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                account.provider.icon
                    .foregroundColor(account.provider.tint)
                    .font(Typography.f18Bold)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.email)
                    .font(Typography.f14SemiBold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(account.provider.rawValue)
                    .font(Typography.footer)
                    .foregroundColor(.secondary)
            }
            Spacer()
            StatusDot(status: account.status)
        }
    }
}

private struct StatusDot: View {
    let status: SyncStatus
    var color: Color {
        switch status {
        case .connected: return .green
        case .syncing:   return .orange
        case .error:     return .red
        }
    }
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: color.opacity(0.5), radius: 2, x: 0, y: 0)
            .accessibilityHidden(true)
    }
}

