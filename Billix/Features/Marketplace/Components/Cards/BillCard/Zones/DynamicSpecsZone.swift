//
//  DynamicSpecsZone.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Zone 3: Dynamic Specs
/// Like sneaker size/condition - the shape of this deal
struct DynamicSpecsZone: View {
    let listing: BillListing

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Spec pills row
            specsRow

            Divider()
                .background(MarketplaceTheme.Colors.textTertiary.opacity(0.2))

            // Friction level
            FrictionMeter(level: listing.frictionLevel)

            // Requirements
            if !listing.requirements.isEmpty {
                requirementsRow
            }
        }
    }

    private var specsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                ForEach(listing.specs.specItems, id: \.label) { item in
                    specPill(icon: item.icon, label: item.label)
                }
            }
        }
    }

    private func specPill(icon: String, label: String) -> some View {
        HStack(spacing: MarketplaceTheme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(MarketplaceTheme.Colors.primary)
            Text(label)
                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
        }
        .padding(.horizontal, MarketplaceTheme.Spacing.sm)
        .padding(.vertical, MarketplaceTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.sm)
                .fill(MarketplaceTheme.Colors.backgroundSecondary)
                .stroke(MarketplaceTheme.Colors.primary.opacity(0.2), lineWidth: 1)
        )
    }

    private var requirementsRow: some View {
        HStack(spacing: MarketplaceTheme.Spacing.xxs) {
            Text("Requires:")
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            ForEach(listing.requirements, id: \.self) { req in
                Text(req)
                    .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                    .foregroundStyle(MarketplaceTheme.Colors.secondary)
                    .padding(.horizontal, MarketplaceTheme.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(MarketplaceTheme.Colors.secondary.opacity(0.1))
                    )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DynamicSpecsZone(listing: MockMarketplaceData.billListings[0])
        DynamicSpecsZone(listing: MockMarketplaceData.billListings[1])
    }
    .padding()
    .background(Color.white)
}
