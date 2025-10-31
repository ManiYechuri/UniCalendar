import SwiftUI

struct MeetingChipView: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(color.opacity(0.35), lineWidth: 1)
                    )
            )
    }
}

