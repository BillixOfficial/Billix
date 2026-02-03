//
//  HelpTipCard.swift
//  Billix
//
//  Collapsible help tip card for contextual guidance
//

import SwiftUI

struct HelpTipCard: View {
    let icon: String
    let title: String
    let message: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: SwapTheme.Spacing.sm) {
            Button {
                withAnimation(SwapTheme.Animations.spring) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: SwapTheme.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(SwapTheme.Colors.success)

                    Text(title)
                        .font(SwapTheme.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(SwapTheme.Colors.primaryText)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SwapTheme.Colors.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Text(message)
                    .font(SwapTheme.Typography.caption)
                    .foregroundColor(SwapTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(SwapTheme.Spacing.md)
        .background(SwapTheme.Colors.success.opacity(0.08))
        .cornerRadius(SwapTheme.CornerRadius.medium)
    }
}

// MARK: - Preview

#Preview("Help Tip Card") {
    VStack(spacing: 16) {
        HelpTipCard(
            icon: "checkmark.shield",
            title: "Why do we scan your bill?",
            message: "OCR verification confirms your bill is authentic, protecting both you and your swap partner from fraud."
        )

        HelpTipCard(
            icon: "star.fill",
            title: "About tier limits",
            message: "Tier limits protect new users. As you complete successful swaps, your limit increases automatically."
        )

        HelpTipCard(
            icon: "lock.shield",
            title: "Guest pay links",
            message: "Guest pay links let your partner pay your bill without accessing your account credentials. This keeps both parties secure."
        )
    }
    .padding()
}
