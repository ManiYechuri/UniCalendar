import SwiftUI

struct OnRightSwipe: ViewModifier {
    var threshold: CGFloat = 48
    let action: () -> Void
    @State private var startX: CGFloat?

    func body(content: Content) -> some View {
        content.gesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .local)
                .onChanged { value in
                    if startX == nil { startX = value.startLocation.x }
                }
                .onEnded { value in
                    defer { startX = nil }
                    if value.translation.width > threshold { action() }
                }
        )
    }
}

extension View {
    func onRightSwipe(threshold: CGFloat = 48, _ action: @escaping () -> Void) -> some View {
        modifier(OnRightSwipe(threshold: threshold, action: action))
    }
}

