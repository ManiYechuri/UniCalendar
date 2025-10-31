import SwiftUI

struct LoginView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: Spacing.l) {
                Spacer(minLength: Spacing.m)

                IconTile(systemName: "calendar")

                VStack(spacing: Spacing.s) {
                    Text("Your calendars,\nunified.")
                        .font(Typography.h1)
                        .multilineTextAlignment(.center)

                    Text("Connect Google and Microsoft accounts to see everything in one place.")
                        .font(Typography.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                VStack(spacing: Spacing.s) {
                    SocialSignInButton(
                        title: "Sign in with Google",
                        logo: .google
                    ) { Task { await auth.signInWithGoogle() } }

                    SocialSignInButton(
                        title: "Sign in with Microsoft",
                        logo: .microsoft
                    ) { Task { await auth.signInWithMicrosoft() } }
                }
                .padding(.horizontal, Spacing.l)

                Spacer()

                TermsFooter()
                    .padding(.horizontal, Spacing.l)
                    .padding(.bottom, Spacing.m)
            }
        }
        .onReceive(auth.$state) { state in
            if case .authenticated = state { router.go(.home) }
        }
        .disabled(auth.isBusy)
        .overlay { if auth.isBusy { ProgressView().scaleEffect(1.2) } }
        .onAppear {
            if AccountStorage.shared.connectedAccounts().isEmpty {
                EventStorage.shared.nukeAll()
                GoogleAccountStore.shared.removeAll()
            }
        }
    }
}

