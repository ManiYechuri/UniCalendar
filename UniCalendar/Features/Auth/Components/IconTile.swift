import SwiftUI

struct IconTile: View {
    let systemName: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color(.systemGray6))
                .frame(width: 80, height: 80)

            Image(systemName: systemName)
                .font(.system(size: 35, weight: .semibold))
                .foregroundColor(Color(.label))
                .accessibilityHidden(true)
        }
    }
}

