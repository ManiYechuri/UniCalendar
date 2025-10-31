import SwiftUI

struct ConnectOutlookSetupView: View {
    var onContinue: () -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 8)

                // Outlook mark (swap to your asset when ready)
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.systemGray6))
                        .frame(width: 96, height: 96)
                    Image(systemName: "o.circle.fill")
                        .font(.system(size: 70, weight: .regular))
                        .foregroundColor(.blue)
                        .opacity(0.9)
                }
                .padding(.top, 12)

                VStack(spacing: 6) {
                    Text("Connect Outlook")
                        .font(.system(size: 28, weight: .heavy))
                    Text("Account")
                        .font(.system(size: 28, weight: .heavy))
                }
                .multilineTextAlignment(.center)

                Text("""
                You'll be redirected to Microsoft to securely log in and grant permissions. UniCal will never see your password.
                """)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

                Button(action: onContinue) {
                    Text("Continue to Microsoft")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.blue))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 4)

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
            .frame(maxWidth: 480)
        }
    }
}

