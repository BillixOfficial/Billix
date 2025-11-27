//
//  BountyCard.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Card for data bounties - requests for specific bill information
struct BountyCard: View {
    let bounty: Bounty
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header with bounty label
            HStack {
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Image(systemName: "target")
                        .font(.system(size: 12))
                    Text("BOUNTY")
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
                        .tracking(1)
                }
                .foregroundStyle(MarketplaceTheme.Colors.accent)

                Spacer()

                // Reward
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                    Text("\(bounty.rewardPoints) pts")
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                }
                .foregroundStyle(MarketplaceTheme.Colors.accent)
            }

            // Title
            Text(bounty.title)
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            // Requirements
            if !bounty.requirements.isEmpty {
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Text("Requirements:")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    ForEach(bounty.requirements, id: \.self) { req in
                        Text(req)
                            .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                            .foregroundStyle(MarketplaceTheme.Colors.primary)
                            .padding(.horizontal, MarketplaceTheme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(MarketplaceTheme.Colors.primary.opacity(0.1))
                            )
                    }
                }
            }

            Divider()
                .background(MarketplaceTheme.Colors.textTertiary.opacity(0.2))

            // Footer
            HStack {
                // Claims
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                    Text("\(bounty.claimCount) submissions")
                }
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                if let remaining = bounty.timeRemaining {
                    Text("•")
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    Text(remaining)
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.warning)
                }

                Spacer()

                // Submit button
                Button(action: onSubmit) {
                    Text("Submit Bill")
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)
                        .padding(.vertical, MarketplaceTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(MarketplaceTheme.Colors.accent)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.xl)
                .fill(MarketplaceTheme.Colors.backgroundCard)
                .stroke(MarketplaceTheme.Colors.accent.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: MarketplaceTheme.Shadows.low.color,
            radius: MarketplaceTheme.Shadows.low.radius,
            x: MarketplaceTheme.Shadows.low.x,
            y: MarketplaceTheme.Shadows.low.y
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(MockMarketplaceData.bounties) { bounty in
            BountyCard(bounty: bounty, onSubmit: {})
        }
    }
    .padding()
    .background(MarketplaceTheme.Colors.backgroundPrimary)
}
