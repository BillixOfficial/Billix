//
//  SectionHeader.swift
//  Billix
//
//  Created by Claude Code
//  Reusable section header component for grouping content
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String

    init(title: String, subtitle: String? = nil, icon: String) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.billixMoneyGreen)

            // Text
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.billixDarkGreen)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.billixMediumGreen)
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Preview

struct SectionHeader_Section_Headers_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.xl) {
        SectionHeader(
        title: "Available Seasons",
        subtitle: "2 seasons",
        icon: "map.fill"
        )
        
        SectionHeader(
        title: "Continue Playing",
        icon: "play.circle.fill"
        )
        
        SectionHeader(
        title: "Coming Soon",
        icon: "bell.fill"
        )
        }
        .background(Color.billixLightGreen)
    }
}
