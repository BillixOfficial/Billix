//
//  SettingsToggleRow.swift
//  Billix
//
//  Created by Billix Team
//

import SwiftUI

/// Settings row with toggle switch (Uber-style)
struct SettingsToggleRow: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let iconColor: Color
    @Binding var isOn: Bool
    let onChange: ((Bool) -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color = .billixMoneyGreen,
        isOn: Binding<Bool>,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self._isOn = isOn
        self.onChange = onChange
    }

    var body: some View {
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
                        .lineLimit(2)
                }
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.billixMoneyGreen)
                .onChange(of: isOn) { _, newValue in
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onChange?(newValue)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Compact toggle row without icon (for grouped lists)
struct CompactToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let onChange: ((Bool) -> Void)?

    init(
        title: String,
        isOn: Binding<Bool>,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self._isOn = isOn
        self.onChange = onChange
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.billixMoneyGreen)
                .onChange(of: isOn) { _, newValue in
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onChange?(newValue)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview("Toggle Rows") {
    struct PreviewWrapper: View {
        @State private var toggle1 = true
        @State private var toggle2 = false
        @State private var toggle3 = true
        @State private var toggle4 = false

        var body: some View {
            VStack(spacing: 16) {
                // With icon and subtitle
                ProfileSectionCard {
                    SettingsToggleRow(
                        title: "Push Notifications",
                        subtitle: "Get alerts about your bills",
                        icon: "bell.fill",
                        isOn: $toggle1
                    )
                }

                // With icon, no subtitle
                ProfileSectionCard {
                    SettingsToggleRow(
                        title: "Email Notifications",
                        icon: "envelope.fill",
                        isOn: $toggle2
                    )
                }

                // Grouped toggles
                ProfileSectionCard {
                    ProfileSectionHeader("Bill Alerts")

                    VStack(spacing: 0) {
                        CompactToggleRow(
                            title: "Upcoming due dates",
                            isOn: $toggle3
                        )

                        ProfileDivider()

                        CompactToggleRow(
                            title: "Price changes",
                            isOn: $toggle4
                        )
                    }
                    .padding(.bottom, 8)
                }

                // Multiple toggles with subtitles
                ProfileSectionCard {
                    VStack(spacing: 0) {
                        SettingsToggleRow(
                            title: "Marketplace Participation",
                            subtitle: "Help others see real bill prices in your area",
                            icon: "chart.bar.fill",
                            iconColor: .billixPurple,
                            isOn: $toggle1
                        )

                        ProfileDivider()

                        SettingsToggleRow(
                            title: "Show Tenure",
                            subtitle: "Display how long you've been with providers",
                            icon: "clock.fill",
                            iconColor: .billixGoldenAmber,
                            isOn: $toggle2
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.billixLightGreen)
        }
    }

    return PreviewWrapper()
}
