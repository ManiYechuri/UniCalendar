import SwiftUI

// MARK: - Shared UI bits for Settings-like screens

public enum Accessory { case none, chevron }

public struct SettingCard<Content: View>: View {
    @ViewBuilder var content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        VStack(spacing: 0) { content }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

public struct IconBadge: View {
    let icon: Image
    let tint: Color
    public init(icon: Image, tint: Color) { self.icon = icon; self.tint = tint }

    public var body: some View {
        ZStack {
            Circle().fill(Color(.systemGray6))
            icon
                .foregroundColor(tint)
                .font(.system(size: 18, weight: .bold))
        }
        .frame(width: 40, height: 40)
    }
}

public struct SettingRow: View {
    let icon: Image
    let iconTint: Color
    let title: String
    let subtitle: String?
    var trailingText: String? = nil
    var accessory: Accessory = .none
    var action: () -> Void

    public init(
        icon: Image,
        iconTint: Color,
        title: String,
        subtitle: String? = nil,
        trailingText: String? = nil,
        accessory: Accessory = .none,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconTint = iconTint
        self.title = title
        self.subtitle = subtitle
        self.trailingText = trailingText
        self.accessory = accessory
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                IconBadge(icon: icon, tint: iconTint)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title).foregroundColor(.primary)
                        Spacer()
                        if let trailingText {
                            Text(trailingText)
                                .foregroundColor(.secondary)
                        }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                if accessory == .chevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

struct SettingRowContent: View {
    let icon: Image
    let iconTint: Color
    let title: String
    let subtitle: String?
    var trailingText: String? = nil
    var showsChevron: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(icon: icon, tint: iconTint)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title).foregroundColor(.primary)
                    Spacer()
                    if let trailingText {
                        Text(trailingText).foregroundColor(.secondary)
                    }
                }
                if let subtitle {
                    Text(subtitle).font(.footnote).foregroundColor(.secondary)
                }
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

public struct ToggleRow: View {
    let icon: Image
    let iconTint: Color
    let title: String
    @Binding var isOn: Bool

    public init(icon: Image, iconTint: Color, title: String, isOn: Binding<Bool>) {
        self.icon = icon
        self.iconTint = iconTint
        self.title = title
        self._isOn = isOn
    }

    public var body: some View {
        HStack(spacing: 12) {
            IconBadge(icon: icon, tint: iconTint)
            Text(title)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// Optional shared header
public struct SectionHeader: View {
    let text: String
    public init(_ text: String) { self.text = text }
    public var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 4)
    }
}

