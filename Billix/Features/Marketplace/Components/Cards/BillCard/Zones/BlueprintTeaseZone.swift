//
//  BlueprintTeaseZone.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Zone 4: Blueprint Tease - Hidden Asset
/// Shows there's a strategy, but keeps it locked
struct BlueprintTeaseZone: View {
    let listing: BillListing
    let onUnlock: () -> Void
    let onAskQuestion: () -> Void

    private var blueprint: Blueprint {
        listing.blueprint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Strategy header
            strategyHeader

            // Blurred script preview
            scriptPreview

            // Guarantee badge + Unlock CTA
            actionRow

            // Q&A preview
            if !listing.questions.isEmpty {
                qaPreview
            }
        }
    }

    private var strategyHeader: some View {
        HStack(spacing: MarketplaceTheme.Spacing.xs) {
            // Strategy tag
            Text(blueprint.strategyType.rawValue.replacingOccurrences(of: "_", with: " "))
                .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, MarketplaceTheme.Spacing.xs)
                .padding(.vertical, MarketplaceTheme.Spacing.xxxs)
                .background(
                    Capsule()
                        .fill(MarketplaceTheme.Colors.secondary)
                )

            // Dependencies
            if !blueprint.dependencies.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 10))
                    Text(blueprint.dependencies.joined(separator: ", "))
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .lineLimit(1)
                }
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
        }
    }

    private var scriptPreview: some View {
        ZStack {
            // Blurred background with script text
            VStack(alignment: .leading, spacing: 4) {
                Text("Script: \"\(blueprint.script.prefix(60))...\"")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    .lineLimit(2)

                // Fake additional blurred lines
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MarketplaceTheme.Colors.textTertiary.opacity(0.3))
                        .frame(height: 8)
                }
            }
            .padding(MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )
            .blur(radius: 4)

            // Lock overlay
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color.white.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Lock icon
            Image(systemName: "lock.fill")
                .font(.system(size: 24))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
        .frame(height: 80)
    }

    private var actionRow: some View {
        HStack {
            // Guarantee badge
            if blueprint.isVerified {
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Image(systemName: "shield.checkmark.fill")
                        .foregroundStyle(MarketplaceTheme.Colors.success)
                    Text("Verified or Points Back")
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }
            }

            Spacer()

            // Unlock button
            Button(action: onUnlock) {
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 12))
                    Text("Unlock")
                    Text("\(blueprint.pointsCost) pts")
                        .fontWeight(.bold)
                }
                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, MarketplaceTheme.Spacing.md)
                .padding(.vertical, MarketplaceTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(MarketplaceTheme.Colors.primary)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private var qaPreview: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xs) {
            // Question count
            Button(action: onAskQuestion) {
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 10))
                    Text("\(listing.questions.count) users asked questions")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                }
                .foregroundStyle(MarketplaceTheme.Colors.info)
            }

            // Sample Q&A
            if let firstQ = listing.questions.first, let answer = firstQ.answer {
                HStack(alignment: .top, spacing: MarketplaceTheme.Spacing.xxs) {
                    Text("\"\(firstQ.question)\"")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                        .lineLimit(1)
                    Text("→")
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    Text(answer)
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.success)
                }
            }
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.sm)
                .fill(MarketplaceTheme.Colors.info.opacity(0.05))
                .stroke(MarketplaceTheme.Colors.info.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    BlueprintTeaseZone(
        listing: MockMarketplaceData.billListings[0],
        onUnlock: {},
        onAskQuestion: {}
    )
    .padding()
    .background(Color.white)
}
