//
//  UnlockBlueprintSheet.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Sheet for unlocking a deal's blueprint/strategy
struct UnlockBlueprintSheet: View {
    let listing: BillListing
    @Environment(\.dismiss) private var dismiss

    @State private var isUnlocking: Bool = false
    @State private var unlockSuccess: Bool = false

    private var blueprint: Blueprint {
        listing.blueprint
    }

    var body: some View {
        VStack(spacing: MarketplaceTheme.Spacing.lg) {
            // Header
            header

            if unlockSuccess {
                successView
            } else {
                // Blueprint preview
                blueprintPreview

                // Cost breakdown
                costSection

                // Guarantee
                if blueprint.isVerified {
                    guaranteeSection
                }

                Spacer()

                // Unlock button
                unlockButton
            }
        }
        .padding(MarketplaceTheme.Spacing.lg)
    }

    private var header: some View {
        VStack(spacing: MarketplaceTheme.Spacing.xs) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .foregroundStyle(MarketplaceTheme.Colors.primary)

            Text("Unlock Blueprint")
                .font(.system(size: MarketplaceTheme.Typography.title, weight: .bold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            Text(listing.providerName)
                .font(.system(size: MarketplaceTheme.Typography.body))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
        }
    }

    private var blueprintPreview: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Strategy type
            HStack {
                Text("Strategy:")
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                Text(blueprint.strategyType.rawValue.replacingOccurrences(of: "_", with: " "))
                    .fontWeight(.semibold)
                    .foregroundStyle(MarketplaceTheme.Colors.secondary)
            }
            .font(.system(size: MarketplaceTheme.Typography.caption))

            // Success stats
            HStack(spacing: MarketplaceTheme.Spacing.lg) {
                statItem(value: "\(Int(blueprint.successRate * 100))%", label: "Success Rate")
                statItem(value: "\(blueprint.totalUses)", label: "Total Uses")
            }

            // Dependencies
            if !blueprint.dependencies.isEmpty {
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxs) {
                    Text("Requirements:")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    HStack {
                        ForEach(blueprint.dependencies, id: \.self) { dep in
                            HStack(spacing: 2) {
                                Image(systemName: "link")
                                    .font(.system(size: 10))
                                Text(dep)
                            }
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.info)
                            .padding(.horizontal, MarketplaceTheme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(MarketplaceTheme.Colors.info.opacity(0.1))
                            )
                        }
                    }
                }
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(MarketplaceTheme.Colors.backgroundSecondary)
        )
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                .foregroundStyle(MarketplaceTheme.Colors.success)
            Text(label)
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
    }

    private var costSection: some View {
        HStack {
            Text("Cost:")
                .font(.system(size: MarketplaceTheme.Typography.body))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

            Spacer()

            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                Image(systemName: "star.fill")
                    .foregroundStyle(MarketplaceTheme.Colors.accent)
                Text("\(blueprint.pointsCost) points")
                    .fontWeight(.bold)
            }
            .font(.system(size: MarketplaceTheme.Typography.headline))
            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .stroke(MarketplaceTheme.Colors.textTertiary.opacity(0.2), lineWidth: 1)
        )
    }

    private var guaranteeSection: some View {
        HStack(spacing: MarketplaceTheme.Spacing.sm) {
            Image(systemName: "shield.checkmark.fill")
                .font(.system(size: 24))
                .foregroundStyle(MarketplaceTheme.Colors.success)

            VStack(alignment: .leading, spacing: 0) {
                Text("Points-Back Guarantee")
                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                Text("If this strategy doesn't work, get your points back")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(MarketplaceTheme.Colors.success.opacity(0.1))
        )
    }

    private var unlockButton: some View {
        Button {
            unlockBlueprint()
        } label: {
            HStack {
                if isUnlocking {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "lock.open.fill")
                    Text("Unlock for \(blueprint.pointsCost) pts")
                }
            }
            .font(.system(size: MarketplaceTheme.Typography.body, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MarketplaceTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                    .fill(MarketplaceTheme.Colors.primary)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isUnlocking)
    }

    private var successView: some View {
        VStack(spacing: MarketplaceTheme.Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(MarketplaceTheme.Colors.success)

            Text("Blueprint Unlocked!")
                .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            // Full script reveal
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                Text("Script:")
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                Text(blueprint.script)
                    .font(.system(size: MarketplaceTheme.Typography.body))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
            }
            .padding(MarketplaceTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MarketplaceTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                            .fill(MarketplaceTheme.Colors.primary)
                    )
            }
        }
    }

    private func unlockBlueprint() {
        isUnlocking = true

        // Simulate unlock
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                isUnlocking = false
                withAnimation {
                    unlockSuccess = true
                }
            }
        }
    }
}

struct UnlockBlueprintSheet_Previews: PreviewProvider {
    static var previews: some View {
        UnlockBlueprintSheet(listing: MockMarketplaceData.billListings[0])
    }
}
