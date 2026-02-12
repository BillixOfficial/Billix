//
//  RecessionSimulatorView.swift
//  Billix
//
//  Created by Claude Code on 11/27/25.
//

import SwiftUI

/// Recession Simulator - "Fidelity Stress Test for Bills"
struct RecessionSimulatorView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @State private var showInfoTooltip: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.md) {
            // Header
            header

            // Scenario selector
            scenarioSelector

            // Custom slider (when custom selected)
            if viewModel.selectedScenario == .custom {
                customSlider
            }

            // Results panel
            if let result = viewModel.stressTestResult {
                resultsPanel(result)
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(MarketplaceTheme.Colors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.xl))
        .shadow(
            color: MarketplaceTheme.Shadows.medium.color,
            radius: MarketplaceTheme.Shadows.medium.radius,
            x: 0,
            y: MarketplaceTheme.Shadows.medium.y
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxxs) {
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 18))
                        .foregroundStyle(MarketplaceTheme.Colors.warning)

                    Text("Recession Simulator")
                        .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                }

                Text("Stress test your monthly bills under 'what-if' scenarios.")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
            }

            Spacer()

            Button {
                showInfoTooltip.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
            .popover(isPresented: $showInfoTooltip) {
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                    Text("How it works")
                        .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))

                    Text("We use your current bills, category averages, and historical volatility to estimate future costs. These are estimates, not guarantees.")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }
                .padding()
                .frame(width: 280)
                .presentationCompactAdaptation(.popover)
            }
        }
    }

    // MARK: - Scenario Selector

    private var scenarioSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                ForEach(EconomicScenario.allCases) { scenario in
                    scenarioPill(scenario)
                }
            }
        }
    }

    private func scenarioPill(_ scenario: EconomicScenario) -> some View {
        let isSelected = viewModel.selectedScenario == scenario

        return Button {
            withAnimation(MarketplaceTheme.Animation.quick) {
                viewModel.selectScenario(scenario)
            }
        } label: {
            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                Text(scenario.icon)
                    .font(.system(size: 14))

                Text(scenario.rawValue)
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : MarketplaceTheme.Colors.textSecondary)
            .padding(.horizontal, MarketplaceTheme.Spacing.sm)
            .padding(.vertical, MarketplaceTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? MarketplaceTheme.Colors.warning : MarketplaceTheme.Colors.backgroundSecondary)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Slider

    private var customSlider: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xs) {
            HStack {
                Text("Inflation shock")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                Spacer()

                Text("+\(Int(viewModel.customInflationRate))%")
                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.warning)
            }

            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                Text("0%")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                Slider(value: $viewModel.customInflationRate, in: 0...15, step: 0.5)
                    .tint(MarketplaceTheme.Colors.warning)
                    .onChange(of: viewModel.customInflationRate) { _, newValue in
                        viewModel.updateCustomInflation(newValue)
                    }

                Text("15%")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(MarketplaceTheme.Colors.warning.opacity(0.1))
        )
    }

    // MARK: - Results Panel

    private func resultsPanel(_ result: StressTestResult) -> some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.md) {
            // Headline result
            headlineResult(result)

            // Category breakdown
            categoryBreakdown(result)

            // Recommendations
            if !result.recommendations.isEmpty {
                recommendationsSection(result.recommendations)
            }
        }
    }

    private func headlineResult(_ result: StressTestResult) -> some View {
        VStack(spacing: MarketplaceTheme.Spacing.xxs) {
            Text("Your projected bill increase:")
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: MarketplaceTheme.Spacing.sm) {
                Text("+$\(Int(result.totalImpactMonthly))")
                    .font(.system(size: MarketplaceTheme.Typography.hero, weight: .bold, design: .rounded))
                    .foregroundStyle(MarketplaceTheme.Colors.danger)

                Text("/mo")
                    .font(.system(size: MarketplaceTheme.Typography.body))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                Spacer()

                Text("+$\(Int(result.totalImpactYearly))/year")
                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .medium))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    .padding(.horizontal, MarketplaceTheme.Spacing.sm)
                    .padding(.vertical, MarketplaceTheme.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(MarketplaceTheme.Colors.danger.opacity(0.1))
                    )
            }
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(MarketplaceTheme.Colors.danger.opacity(0.05))
                .stroke(MarketplaceTheme.Colors.danger.opacity(0.2), lineWidth: 1)
        )
    }

    private func categoryBreakdown(_ result: StressTestResult) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                ForEach(result.categoryBreakdown.filter { $0.impactAmount > 0 }) { impact in
                    categoryChip(impact)
                }
            }
        }
    }

    private func categoryChip(_ impact: CategoryImpact) -> some View {
        HStack(spacing: MarketplaceTheme.Spacing.xxs) {
            Image(systemName: impact.category.icon)
                .font(.system(size: 12))
                .foregroundStyle(impact.category.color)

            Text(impact.category.rawValue)
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

            Text("+$\(Int(impact.impactAmount))")
                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
        }
        .padding(.horizontal, MarketplaceTheme.Spacing.sm)
        .padding(.vertical, MarketplaceTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(impact.category.color.opacity(0.1))
        )
    }

    // MARK: - Recommendations

    private func recommendationsSection(_ recommendations: [StressTestRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            Text("Recommended Moves")
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            ForEach(recommendations) { rec in
                recommendationCard(rec)
            }
        }
    }

    private func recommendationCard(_ recommendation: StressTestRecommendation) -> some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xs) {
            HStack {
                Circle()
                    .fill(recommendation.urgency.color)
                    .frame(width: 8, height: 8)

                Text(recommendation.title)
                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Spacer()

                if let savings = recommendation.potentialSavings {
                    Text("Save ~$\(Int(savings))")
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                        .foregroundStyle(MarketplaceTheme.Colors.success)
                }
            }

            Text(recommendation.description)
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

            Button {
                // Handle action
            } label: {
                Text(actionButtonText(for: recommendation.actionType))
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.primary)
            }
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(MarketplaceTheme.Colors.backgroundSecondary)
        )
    }

    private func actionButtonText(for action: StressTestRecommendation.RecommendationAction) -> String {
        switch action {
        case .lockRate: return "View Plans →"
        case .viewPlans: return "Browse Deals →"
        case .setStrikePrice: return "Set Strike Price →"
        case .joinCluster: return "Join Cluster →"
        case .switchProvider: return "See Options →"
        }
    }
}

struct RecessionSimulatorView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
        RecessionSimulatorView(viewModel: ExploreViewModel())
        .padding()
        }
        .background(MarketplaceTheme.Colors.backgroundPrimary)
    }
}
