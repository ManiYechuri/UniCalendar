import SwiftUI

struct FilterPopupView: View {
    @Binding var selection: CalendarViewModel.SourceFilter
    var onClose: () -> Void
    var onApply: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Filter Events")
                    .font(.headline.weight(.semibold))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Section
            VStack(alignment: .leading, spacing: 12) {
                Text("CALENDAR SOURCE")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    SelectablePill("All",
                                   selected: selection == .all,
                                   leftIcon: "checkmark.circle",
                                   accent: .blue) { selection = .all }

                    SelectablePill("Google",
                                   selected: selection == .google,
                                   leftDot: Color.red) { selection = .google }
                }

                HStack(spacing: 12) {
                    SelectablePill("Outlook",
                                   selected: selection == .outlook,
                                   leftDot: Color.blue) { selection = .outlook }
                }
            }
            .padding(.horizontal, 20)

            // Apply button
            Button(action: onApply) {
                Text("Apply Filter")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28).stroke(Color.blue.opacity(0.15), lineWidth: 2)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 16)
    }
}

private struct SelectablePill: View {
    var title: String
    var selected: Bool
    var leftIcon: String? = nil
    var leftDot: Color? = nil
    var accent: Color = .blue
    var action: () -> Void

    init(_ title: String,
         selected: Bool,
         leftIcon: String? = nil,
         leftDot: Color? = nil,
         accent: Color = .blue,
         action: @escaping () -> Void) {
        self.title = title
        self.selected = selected
        self.leftIcon = leftIcon
        self.leftDot = leftDot
        self.accent = accent
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let leftIcon { Image(systemName: leftIcon) }
                if let leftDot {
                    Circle().fill(leftDot).frame(width: 8, height: 8)
                }
                Text(title).font(.body.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minWidth: 140)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? accent.opacity(0.12) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selected ? accent : Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

