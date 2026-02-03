//
//  BillSwapSafetySheet.swift
//  Billix
//
//  Informational sheet explaining how BillSwap keeps users safe
//

import SwiftUI

/// Sheet explaining BillSwap safety features and trust system
struct BillSwapSafetySheet: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SwapTheme.Spacing.xxl) {

                    // Header
                    headerSection

                    // Safety Features
                    safetyFeaturesSection

                    // Trust Tiers
                    trustTiersSection

                    // How It Works
                    howItWorksSection

                    // Consequences
                    consequencesSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, SwapTheme.Spacing.lg)
                .padding(.top, SwapTheme.Spacing.lg)
            }
            .background(SwapTheme.Colors.background)
            .navigationTitle("How BillSwap Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: SwapTheme.Spacing.md) {
            HStack {
                Image(systemName: SwapTheme.Icons.trust)
                    .font(.system(size: 32))
                    .foregroundColor(SwapTheme.Colors.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Built for Safety")
                        .font(SwapTheme.Typography.title2)
                        .foregroundColor(SwapTheme.Colors.primaryText)

                    Text("Multiple layers of protection")
                        .font(SwapTheme.Typography.subheadline)
                        .foregroundColor(SwapTheme.Colors.secondaryText)
                }
            }

            Text("BillSwap connects people who need help paying bills. We've designed multiple safeguards to protect both parties in every swap.")
                .font(SwapTheme.Typography.body)
                .foregroundColor(SwapTheme.Colors.secondaryText)
        }
        .padding(SwapTheme.Spacing.lg)
        .background(SwapTheme.Colors.secondaryBackground)
        .cornerRadius(SwapTheme.CornerRadius.large)
    }

    // MARK: - Safety Features Section

    private var safetyFeaturesSection: some View {
        VStack(alignment: .leading, spacing: SwapTheme.Spacing.lg) {
            sectionHeader("Safety Features", icon: SwapTheme.Icons.safe)

            VStack(spacing: SwapTheme.Spacing.md) {
                safetyFeatureRow(
                    icon: SwapTheme.Icons.verified,
                    title: "Verified Bills",
                    description: "Bills are scanned and verified using OCR technology to confirm authenticity"
                )

                safetyFeatureRow(
                    icon: SwapTheme.Icons.timeline,
                    title: "Structured Terms",
                    description: "Clear deadlines and expectations agreed upon before any swap begins"
                )

                safetyFeatureRow(
                    icon: SwapTheme.Icons.proof,
                    title: "Proof-Based Checkpoints",
                    description: "Payment screenshots required to verify each step was completed"
                )

                safetyFeatureRow(
                    icon: "clock.badge.checkmark",
                    title: "Time-Bound Progress",
                    description: "Both parties must complete their side within agreed deadlines"
                )

                safetyFeatureRow(
                    icon: SwapTheme.Icons.trust,
                    title: "Trust Scores",
                    description: "Build reputation through successful swaps, visible to potential partners"
                )
            }
        }
    }

    private func safetyFeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: SwapTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(SwapTheme.Colors.success)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SwapTheme.Typography.headline)
                    .foregroundColor(SwapTheme.Colors.primaryText)

                Text(description)
                    .font(SwapTheme.Typography.subheadline)
                    .foregroundColor(SwapTheme.Colors.secondaryText)
            }
        }
        .padding(SwapTheme.Spacing.md)
        .background(SwapTheme.Colors.secondaryBackground)
        .cornerRadius(SwapTheme.CornerRadius.medium)
    }

    // MARK: - Trust Tiers Section

    private var trustTiersSection: some View {
        VStack(alignment: .leading, spacing: SwapTheme.Spacing.lg) {
            sectionHeader("Trust Tiers", icon: "star.fill")

            Text("Your tier determines the maximum bill amount you can swap. Complete more swaps to unlock higher limits.")
                .font(SwapTheme.Typography.subheadline)
                .foregroundColor(SwapTheme.Colors.secondaryText)

            VStack(spacing: SwapTheme.Spacing.sm) {
                tierRow(tier: 1, name: "New", limit: "$25", requirement: "Starting tier")
                tierRow(tier: 2, name: "Established", limit: "$50", requirement: "3+ successful swaps")
                tierRow(tier: 3, name: "Trusted", limit: "$100", requirement: "10+ successful swaps")
                tierRow(tier: 4, name: "Veteran", limit: "$150", requirement: "25+ successful swaps")
            }
        }
    }

    private func tierRow(tier: Int, name: String, limit: String, requirement: String) -> some View {
        HStack {
            Image(systemName: SwapTheme.Tiers.tierIcon(tier))
                .font(.system(size: 18))
                .foregroundColor(SwapTheme.Tiers.tierColor(tier))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(SwapTheme.Typography.headline)
                    .foregroundColor(SwapTheme.Colors.primaryText)

                Text(requirement)
                    .font(SwapTheme.Typography.caption)
                    .foregroundColor(SwapTheme.Colors.tertiaryText)
            }

            Spacer()

            Text(limit)
                .font(SwapTheme.Typography.amountSmall)
                .foregroundColor(SwapTheme.Tiers.tierColor(tier))
        }
        .padding(SwapTheme.Spacing.md)
        .background(SwapTheme.Colors.secondaryBackground)
        .cornerRadius(SwapTheme.CornerRadius.medium)
    }

    // MARK: - How It Works Section

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: SwapTheme.Spacing.lg) {
            sectionHeader("How It Works", icon: SwapTheme.Icons.exchange)

            VStack(spacing: SwapTheme.Spacing.sm) {
                stepRow(number: 1, title: "Upload & Verify", description: "Scan your bill to verify details via OCR")
                stepRow(number: 2, title: "Find a Match", description: "We match you with similar bills from others")
                stepRow(number: 3, title: "Review Terms", description: "Agree on deadlines and payment order")
                stepRow(number: 4, title: "Commit", description: "Both parties lock in with a small commitment fee")
                stepRow(number: 5, title: "Complete", description: "Pay each other's bills and upload proof")
                stepRow(number: 6, title: "Earn Trust", description: "Build your reputation for future swaps")
            }
        }
    }

    private func stepRow(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: SwapTheme.Spacing.md) {
            Text("\(number)")
                .font(SwapTheme.Typography.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(SwapTheme.Colors.primary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SwapTheme.Typography.headline)
                    .foregroundColor(SwapTheme.Colors.primaryText)

                Text(description)
                    .font(SwapTheme.Typography.subheadline)
                    .foregroundColor(SwapTheme.Colors.secondaryText)
            }

            Spacer()
        }
        .padding(SwapTheme.Spacing.md)
        .background(SwapTheme.Colors.secondaryBackground)
        .cornerRadius(SwapTheme.CornerRadius.medium)
    }

    // MARK: - Consequences Section

    private var consequencesSection: some View {
        VStack(alignment: .leading, spacing: SwapTheme.Spacing.lg) {
            sectionHeader("Accountability", icon: SwapTheme.Icons.warning)

            Text("To maintain trust in the community, there are consequences for not completing swaps:")
                .font(SwapTheme.Typography.subheadline)
                .foregroundColor(SwapTheme.Colors.secondaryText)

            VStack(spacing: SwapTheme.Spacing.sm) {
                consequenceRow(
                    icon: "arrow.down.circle",
                    title: "Missed Deadline",
                    consequence: "Trust tier downgrade",
                    severity: .medium
                )

                consequenceRow(
                    icon: "exclamationmark.triangle",
                    title: "Dispute",
                    consequence: "7-day eligibility lock",
                    severity: .high
                )

                consequenceRow(
                    icon: "xmark.circle",
                    title: "Repeated Issues",
                    consequence: "Permanent swap restriction",
                    severity: .critical
                )
            }
        }
    }

    private enum Severity {
        case medium, high, critical

        var color: Color {
            switch self {
            case .medium: return SwapTheme.Colors.warning
            case .high: return .orange
            case .critical: return SwapTheme.Colors.danger
            }
        }
    }

    private func consequenceRow(icon: String, title: String, consequence: String, severity: Severity) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(severity.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SwapTheme.Typography.headline)
                    .foregroundColor(SwapTheme.Colors.primaryText)

                Text(consequence)
                    .font(SwapTheme.Typography.caption)
                    .foregroundColor(severity.color)
            }

            Spacer()
        }
        .padding(SwapTheme.Spacing.md)
        .background(severity.color.opacity(0.1))
        .cornerRadius(SwapTheme.CornerRadius.medium)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: SwapTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(SwapTheme.Colors.primary)

            Text(title)
                .font(SwapTheme.Typography.title3)
                .foregroundColor(SwapTheme.Colors.primaryText)
        }
    }
}

// MARK: - Preview

#Preview {
    BillSwapSafetySheet()
}
