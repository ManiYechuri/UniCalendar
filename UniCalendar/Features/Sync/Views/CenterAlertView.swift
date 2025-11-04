import SwiftUI

struct CenterAlertView: View {
    let title: String
    let message: String
    let cancelTitle: String
    let destructiveTitle: String
    var onCancel: () -> Void
    var onDestructive: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(Typography.h1)
                .multilineTextAlignment(.center)
                .padding(.top, 16)

            Text(message)
                .font(Typography.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            HStack(spacing: 20) {
                Button(cancelTitle, action: onCancel)
                    .font(Typography.f12Regular)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)

                Button(destructiveTitle, action: onDestructive)
                    .font(Typography.f12Regular)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(.regularMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 8)
        .frame(maxWidth: 320)
        .padding(.horizontal, 24)
    }
}

