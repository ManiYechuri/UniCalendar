import SwiftUI

struct ConnectGoogleSetupView: View {
    var onContinue: () -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            // Card
            VStack(spacing: 24) {
                Spacer(minLength: 8)

                // Google mark
                ZStack {
                    Circle().fill(Color(.systemGray6))
                        .frame(width: 96, height: 96)
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.red) // swap to your asset when you have it
                        .opacity(0.85)
                }
                .padding(.top, 12)

                // Title
                VStack(spacing: 6) {
                    Text("Connect your")
                        .font(.system(size: 28, weight: .heavy))
                    Text("Google Account")
                        .font(.system(size: 28, weight: .heavy))
                }
                .multilineTextAlignment(.center)

                // Body copy
                Text("""
                UniCal uses Google's secure service to connect your account. You will be redirected to a Google sign-in page to grant permission. UniCal will never see your password.
                """)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

                // Primary CTA
                Button(action: onContinue) {
                    Text("Continue to Google")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.blue))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 4)

                // Secondary
                Button("Cancel", action: onCancel)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)

                Spacer(minLength: 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.regularMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .frame(maxWidth: 480) // looks nice on iPad too
        }
    }
}

