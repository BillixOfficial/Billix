//
//  GougeIndexView.swift
//  Billix
//
//  Created by Claude Code on 11/27/25.
//

import SwiftUI

/// Gouge Index / Wall of Shame - Provider Leaderboard
struct GougeIndexView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @State private var showShareSheet: Bool = false
    @State private var shareContent: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.md) {
            // Header
            header

            // This month's highlights
            highlightsCarousel

            // Filter bar
            filterBar

            // Rankings list
            rankingsList
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
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(content: shareContent)
                .presentationDetents([.medium])
                .presentationBackground(Color(hex: "#F5F7F6"))
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxxs) {
            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(MarketplaceTheme.Colors.danger)

                Text("Gouge Index")
                    .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Spacer()

                Text("Updated today")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }

            Text("Who's overcharging in your area? Community-sourced rankings.")
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
        }
    }

    // MARK: - Highlights Carousel

    private var highlightsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                ForEach(viewModel.gougeHighlights) { highlight in
                    HighlightCard(highlight: highlight, onShare: {
                        shareHighlight(highlight)
                    })
                }
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Category filter
            Menu {
                Button("All Categories") {
                    viewModel.gougeIndexCategory = nil
                }
                ForEach(BillCategoryType.allCases) { category in
                    Button(category.rawValue) {
                        viewModel.gougeIndexCategory = category
                    }
                }
            } label: {
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Image(systemName: viewModel.gougeIndexCategory?.icon ?? "square.grid.2x2")
                        .font(.system(size: 12))

                    Text(viewModel.gougeIndexCategory?.rawValue ?? "All")
                        .font(.system(size: MarketplaceTheme.Typography.caption))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                .padding(.horizontal, MarketplaceTheme.Spacing.sm)
                .padding(.vertical, MarketplaceTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                )
            }

            // Region filter
            Menu {
                Button("My ZIP") {
                    viewModel.gougeIndexRegion = "My ZIP"
                }
                Button("My City") {
                    viewModel.gougeIndexRegion = "My City"
                }
                Button("My State") {
                    viewModel.gougeIndexRegion = "My State"
                }
                Button("National") {
                    viewModel.gougeIndexRegion = "National"
                }
            } label: {
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Image(systemName: "location")
                        .font(.system(size: 12))

                    Text(viewModel.gougeIndexRegion)
                        .font(.system(size: MarketplaceTheme.Typography.caption))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                .padding(.horizontal, MarketplaceTheme.Spacing.sm)
                .padding(.vertical, MarketplaceTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                )
            }

            Spacer()
        }
    }

    // MARK: - Rankings List

    private var rankingsList: some View {
        VStack(spacing: MarketplaceTheme.Spacing.xs) {
            ForEach(filteredRankings) { ranking in
                ProviderRankingRow(ranking: ranking, onShare: {
                    shareRanking(ranking)
                }, onSelect: {
                    viewModel.selectedProvider = ranking
                })
            }
        }
    }

    private var filteredRankings: [ProviderRanking] {
        if let category = viewModel.gougeIndexCategory {
            return viewModel.providerRankings.filter { $0.category == category }
        }
        return viewModel.providerRankings
    }

    // MARK: - Share Actions

    private func shareHighlight(_ highlight: GougeHighlight) {
        switch highlight.highlightType {
        case .mostHated:
            shareContent = "The most hated bill provider in my area is \(highlight.providerName) - charging \(highlight.metric) above market rate! Check your bills on Billix."
        case .biggestSurge:
            shareContent = "\(highlight.providerName) just raised prices \(highlight.metric) this month. Time to switch? Check alternatives on Billix."
        case .bestSurprise:
            shareContent = "Found a gem: \(highlight.providerName) is actually \(highlight.metric) below market rate. See how on Billix."
        }
        showShareSheet = true
    }

    private func shareRanking(_ ranking: ProviderRanking) {
        let emoji = ranking.rating == .mostHated ? "🔥" : ranking.rating == .bestValue ? "⭐" : "📊"
        shareContent = "\(emoji) \(ranking.providerName) is \(ranking.overchargePercent >= 0 ? "+" : "")\(Int(ranking.overchargePercent))% vs market average for \(ranking.category.rawValue) in \(ranking.region). #BillixGougeIndex"
        showShareSheet = true
    }
}

// MARK: - Highlight Card

struct HighlightCard: View {
    let highlight: GougeHighlight
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Badge
            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                Image(systemName: highlight.highlightType.icon)
                    .font(.system(size: 12))

                Text(highlight.title)
                    .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
            }
            .foregroundStyle(highlight.highlightType.color)

            // Provider info
            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(highlight.highlightType.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: highlight.providerLogo)
                        .font(.system(size: 16))
                        .foregroundStyle(highlight.highlightType.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(highlight.providerName)
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    Text(highlight.subtitle)
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }
            }

            // Metric
            Text(highlight.metric)
                .font(.system(size: MarketplaceTheme.Typography.title, weight: .bold, design: .rounded))
                .foregroundStyle(highlight.highlightType.color)

            // Share button
            Button {
                onShare()
            } label: {
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))

                    Text("Share")
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                }
                .foregroundStyle(highlight.highlightType.color)
            }
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(highlight.highlightType.color.opacity(0.08))
                .stroke(highlight.highlightType.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Provider Ranking Row

struct ProviderRankingRow: View {
    let ranking: ProviderRanking
    let onShare: () -> Void
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(rankBackgroundColor)
                        .frame(width: 28, height: 28)

                    Text("#\(ranking.rank)")
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
                        .foregroundStyle(ranking.rank <= 3 ? .white : MarketplaceTheme.Colors.textSecondary)
                }

                // Provider icon
                ZStack {
                    Circle()
                        .fill(ranking.category.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: ranking.providerLogo)
                        .font(.system(size: 16))
                        .foregroundStyle(ranking.category.color)
                }

                // Provider info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        Text(ranking.providerName)
                            .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        // Rating badge
                        HStack(spacing: 2) {
                            Image(systemName: ranking.rating.icon)
                                .font(.system(size: 8))

                            Text(ranking.rating.rawValue)
                                .font(.system(size: 8, weight: .medium))
                        }
                        .foregroundStyle(ranking.rating.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(ranking.rating.color.opacity(0.15))
                        )
                    }

                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        Text(ranking.category.rawValue)
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                        Text("•")
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                        Text("\(ranking.complaintsCount) complaints")
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }
                }

                Spacer()

                // Overcharge percent
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(ranking.overchargePercent >= 0 ? "+" : "")\(Int(ranking.overchargePercent))%")
                        .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                        .foregroundStyle(overchargeColor)

                    if ranking.recentPriceChange != 0 {
                        HStack(spacing: 2) {
                            Image(systemName: ranking.recentPriceChange > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 8))

                            Text("\(abs(Int(ranking.recentPriceChange)))%")
                                .font(.system(size: MarketplaceTheme.Typography.micro))
                        }
                        .foregroundStyle(ranking.recentPriceChange > 0 ? MarketplaceTheme.Colors.danger : MarketplaceTheme.Colors.success)
                    }
                }

                // Share button
                Button {
                    onShare()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }
            }
            .padding(MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )
        }
        .buttonStyle(.plain)
    }

    private var rankBackgroundColor: Color {
        switch ranking.rank {
        case 1: return MarketplaceTheme.Colors.danger
        case 2: return Color(hex: "#F97316")
        case 3: return Color(hex: "#EAB308")
        default: return MarketplaceTheme.Colors.backgroundSecondary
        }
    }

    private var overchargeColor: Color {
        if ranking.overchargePercent > 20 {
            return MarketplaceTheme.Colors.danger
        } else if ranking.overchargePercent > 0 {
            return Color(hex: "#F97316")
        } else if ranking.overchargePercent < -10 {
            return MarketplaceTheme.Colors.success
        } else {
            return MarketplaceTheme.Colors.textSecondary
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: View {
    let content: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                // Preview
                Text(content)
                    .font(.system(size: MarketplaceTheme.Typography.body))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    .padding(MarketplaceTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                            .fill(MarketplaceTheme.Colors.backgroundSecondary)
                    )
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)

                // Share buttons
                HStack(spacing: MarketplaceTheme.Spacing.lg) {
                    shareButton(icon: "message.fill", label: "Messages", color: .green)
                    shareButton(icon: "square.and.arrow.up", label: "More", color: MarketplaceTheme.Colors.primary)
                }

                Spacer()
            }
            .padding(.top, MarketplaceTheme.Spacing.lg)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func shareButton(icon: String, label: String, color: Color) -> some View {
        Button {
            // In a real app, this would trigger the share action
            dismiss()
        } label: {
            VStack(spacing: MarketplaceTheme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }

                Text(label)
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct GougeIndexView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            GougeIndexView(viewModel: ExploreViewModel())
                .padding()
        }
        .background(MarketplaceTheme.Colors.backgroundPrimary)
    }
}
