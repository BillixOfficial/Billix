//
//  SettingsRow.swift
//  Billix
//
//  Created by Billix Team
//

import SwiftUI

/// Uber-style settings row with title, subtitle, icon, and chevron
struct SettingsRow: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let iconColor: Color
    let showChevron: Bool
    let action: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color = .billixMoneyGreen,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.showChevron = showChevron
        self.action = action
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                        .frame(width: 28, height: 28)
                }

                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.gray.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Settings row with trailing value display
struct SettingsValueRow: View {
    let title: String
    let value: String
    let icon: String?
    let action: () -> Void

    init(
        title: String,
        value: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.billixMoneyGreen)
                        .frame(width: 28, height: 28)
                }

                // Title
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Spacer()

                // Value
                Text(value)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.gray.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Settings row with badge/pill indicator
struct SettingsBadgeRow: View {
    let title: String
    let badge: String
    let badgeColor: Color
    let icon: String?
    let action: () -> Void

    init(
        title: String,
        badge: String,
        badgeColor: Color = .billixGoldenAmber,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.badge = badge
        self.badgeColor = badgeColor
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.billixMoneyGreen)
                        .frame(width: 28, height: 28)
                }

                // Title
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Spacer()

                // Badge
                Text(badge)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(badgeColor)
                    .cornerRadius(12)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.gray.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct SettingsRow_Settings_Rows_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
        // Standard row
        ProfileSectionCard {
        SettingsRow(
        title: "Edit Profile",
        subtitle: "Update your name and photo",
        icon: "pencil",
        action: {}
        )
        }
        
        // Value row
        ProfileSectionCard {
        SettingsValueRow(
        title: "Language",
        value: "English",
        icon: "globe",
        action: {}
        )
        }
        
        // Badge row
        ProfileSectionCard {
        SettingsBadgeRow(
        title: "Billix Credits",
        badge: "85",
        badgeColor: .billixGoldenAmber,
        icon: "star.fill",
        action: {}
        )
        }
        
        // Multiple rows
        ProfileSectionCard {
        VStack(spacing: 0) {
        SettingsRow(
        title: "Account",
        subtitle: "Manage your account",
        icon: "person.circle.fill",
        action: {}
        )
        
        ProfileDivider()
        
        SettingsRow(
        title: "Privacy",
        subtitle: "Control your data",
        icon: "lock.fill",
        action: {}
        )
        
        ProfileDivider()
        
        SettingsRow(
        title: "Help & Support",
        subtitle: "Get help",
        icon: "questionmark.circle.fill",
        action: {}
        )
        }
        .padding(.vertical, 4)
        }
        }
        .padding()
        .background(Color.billixLightGreen)
    }
}
