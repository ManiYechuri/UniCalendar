import SwiftUI

struct TermsFooter: View {
    var body: some View {
        Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
            .font(Typography.footer)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .accessibilityHint("Opens terms and privacy policy")
    }
}

