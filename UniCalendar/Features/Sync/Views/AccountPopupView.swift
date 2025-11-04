import SwiftUI

struct AddAccountPopupView: View {
    var onClose: () -> Void
    var onConnectGoogle: () -> Void
    var onConnectOutlook: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("Connect New Account")
                    .font(Typography.f18Bold)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
            VStack(spacing: 12) {
                Button(action: onConnectGoogle) {
                    HStack(spacing: 12) {
                        providerBadge(color: .red, letter: "G")
                        Text("Connect with Google")
                            .font(Typography.f14SemiBold)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.red))
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: onConnectOutlook) {
                    HStack(spacing: 12) {
                        providerBadge(color: .blue, letter: "O")
                        Text("Connect with Microsoft Outlook")
                            .font(Typography.f14SemiBold)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func providerBadge(color: Color, letter: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 36)
            Text(letter)
                .font(Typography.f14SemiBold)
                .foregroundColor(.white)
        }
        .frame(width: 36, height: 36)
        .background(Circle().fill(color.opacity(0.001)))
    }
}

