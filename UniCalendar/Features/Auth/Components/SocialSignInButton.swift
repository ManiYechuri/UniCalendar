import SwiftUI

struct SocialSignInButton: View {
    enum Logo { case google, microsoft }

    let title: String
    let logo: Logo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(.systemGray4), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.systemBackground))
                    )

                HStack(spacing: 10) {
                    Image(logo == .google ? "google_logo" : "microsoft_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(Typography.subheadline)
                        .foregroundColor(Color(.label))
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
            .frame(height: 58)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

