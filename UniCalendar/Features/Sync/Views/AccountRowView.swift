import SwiftUI

struct AccountRowView: View {
    let account: SyncAccount

    var body: some View {
        HStack(spacing: 12) {
            // Avatar (use real logo assets if you have them)
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                account.provider.icon
                    .foregroundColor(account.provider.tint)
                    .font(.system(size: 20, weight: .bold))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.email)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(account.provider.rawValue)
                    .font(.footnote)
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

