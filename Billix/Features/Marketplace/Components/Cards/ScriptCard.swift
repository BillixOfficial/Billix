//
//  ScriptCard.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Card for negotiation scripts/bluffs
struct ScriptCard: View {
    let script: NegotiationScript
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header
            HStack {
                // Script icon
                ZStack {
                    Circle()
                        .fill(MarketplaceTheme.Colors.secondary.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: "text.quote")
                        .font(.system(size: 18))
                        .foregroundStyle(MarketplaceTheme.Colors.secondary)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(script.title)
                        .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                        .lineLimit(2)

                    if let provider = script.providerName {
                        Text("Provider: \(provider)")
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }
                }

                Spacer()

                if script.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(MarketplaceTheme.Colors.info)
                }
            }

            // Success stats
            HStack(spacing: MarketplaceTheme.Spacing.lg) {
                statItem(label: "Success", value: "\(script.successPercent)%", color: MarketplaceTheme.Colors.success)
                statItem(label: "Wins", value: "\(script.totalWins)", color: MarketplaceTheme.Colors.textPrimary)
                statItem(label: "Uses", value: "\(script.totalUses)", color: MarketplaceTheme.Colors.textSecondary)
            }

            Divider()
                .background(MarketplaceTheme.Colors.textTertiary.opacity(0.2))

            // Author + Action
            HStack {
                // Author
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    Text(script.authorHandle)
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                Spacer()

                // Unlock button
                Button(action: onUnlock) {
                    HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 12))
                        Text("Unlock")
                        Text("(\(script.pointsCost) pts)")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)
                    .padding(.vertical, MarketplaceTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(MarketplaceTheme.Colors.secondary)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .marketplaceCard(elevation: .low)
    }

    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
    }
}

struct ScriptCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
        ForEach(MockMarketplaceData.scripts) { script in
        ScriptCard(script: script, onUnlock: {})
        }
        }
        .padding()
        .background(MarketplaceTheme.Colors.backgroundPrimary)
    }
}
