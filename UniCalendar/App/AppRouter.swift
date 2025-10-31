import SwiftUI
import UIKit

final class AppRouter: ObservableObject {
    enum Route { case login, home }
    @Published var route: Route = .login

    @ViewBuilder
    var root: some View {
        switch route {
        case .login: LoginView()
        case .home:  HomeTabsView()
        }
    }

    func go(_ route: Route) { self.route = route }
}

extension UIApplication {
    var topViewController: UIViewController? {
        guard let scene = connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else { return nil }
        while let next = (top as? UINavigationController)?.visibleViewController
              ?? (top as? UITabBarController)?.selectedViewController
              ?? top.presentedViewController { top = next }
        return top
    }
}
