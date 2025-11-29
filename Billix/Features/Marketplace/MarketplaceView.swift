//
//  MarketplaceView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Main Marketplace container view
/// Replaces the Explore page with StockX x FB Marketplace x Fidelity vibe
struct MarketplaceView: View {
    @StateObject private var viewModel = MarketplaceViewModel()
    @Namespace private var tabAnimation

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab bar
                tabBar

                // Content
                if viewModel.isLoading {
                    loadingView
                } else {
                    tabContent
                }
            }
            .background(MarketplaceTheme.Colors.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Marketplace")
                        .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: MarketplaceTheme.Spacing.sm) {
                        Button(action: { viewModel.showFilterSheet = true }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search deals, providers, ZIP...")
        }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            FilterSheetView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showUnlockSheet) {
            if let listing = viewModel.selectedListing {
                UnlockBlueprintSheet(listing: listing)
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $viewModel.showAskOwnerSheet) {
            if let listing = viewModel.selectedListing {
                AskOwnerSheet(listing: listing)
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $viewModel.showPlaceBidSheet) {
            if let cluster = viewModel.selectedCluster {
                PlaceBidSheet(cluster: cluster)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                ForEach(MarketplaceTab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.horizontal, MarketplaceTheme.Spacing.md)
            .padding(.vertical, MarketplaceTheme.Spacing.sm)
        }
        .background(MarketplaceTheme.Colors.backgroundCard)
        .shadow(
            color: MarketplaceTheme.Shadows.low.color,
            radius: MarketplaceTheme.Shadows.low.radius,
            x: 0,
            y: 2
        )
    }

    private func tabButton(for tab: MarketplaceTab) -> some View {
        Button {
            withAnimation(MarketplaceTheme.Animation.quick) {
                viewModel.selectedTab = tab
            }
        } label: {
            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12))
                Text(tab.shortName)
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
            }
            .foregroundStyle(viewModel.selectedTab == tab ? .white : MarketplaceTheme.Colors.textSecondary)
            .padding(.horizontal, MarketplaceTheme.Spacing.md)
            .padding(.vertical, MarketplaceTheme.Spacing.xs)
            .background(
                Group {
                    if viewModel.selectedTab == tab {
                        Capsule()
                            .fill(MarketplaceTheme.Colors.primary)
                            .matchedGeometryEffect(id: "activeTab", in: tabAnimation)
                    } else {
                        Capsule()
                            .fill(MarketplaceTheme.Colors.backgroundSecondary)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .deals:
            DealsTabView(viewModel: viewModel)
        case .clusters:
            ClustersTabView(viewModel: viewModel)
        case .experts:
            ExpertsTabView(viewModel: viewModel)
        case .signals:
            SignalsTabView(viewModel: viewModel)
        }
    }

    private var loadingView: some View {
        VStack(spacing: MarketplaceTheme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading marketplace...")
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Deals Tab

struct DealsTabView: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @State private var selectedCardIndex: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                // Featured card (full size)
                if let featured = viewModel.filteredListings.first {
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                        Text("Featured Deal")
                            .marketplaceSectionHeader()
                            .padding(.horizontal, MarketplaceTheme.Spacing.md)

                        BillCardView(
                            listing: featured,
                            userCurrentPrice: viewModel.userPriceForCategory(featured.category),
                            onUnlock: { viewModel.unlockBlueprint(for: featured) },
                            onAskQuestion: { viewModel.askOwner(for: featured) },
                            onWatchlist: { viewModel.addToWatchlist(featured) },
                            onAskOwner: { viewModel.askOwner(for: featured) },
                            onReport: { viewModel.reportListing(featured) }
                        )
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)
                    }
                }

                // More deals (compact list)
                if viewModel.filteredListings.count > 1 {
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                        Text("More Deals")
                            .marketplaceSectionHeader()
                            .padding(.horizontal, MarketplaceTheme.Spacing.md)

                        ForEach(Array(viewModel.filteredListings.dropFirst())) { listing in
                            BillCardCompact(
                                listing: listing,
                                onTap: { viewModel.selectedListing = listing }
                            )
                            .padding(.horizontal, MarketplaceTheme.Spacing.md)
                        }
                    }
                }

                // Contract Takeovers section
                if !viewModel.takeovers.isEmpty {
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                        HStack {
                            Text("Contract Takeovers")
                                .marketplaceSectionHeader()

                            Spacer()

                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(MarketplaceTheme.Colors.accent)
                        }
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)

                        ForEach(viewModel.takeovers) { takeover in
                            TakeoverCard(takeover: takeover, onInquire: {})
                                .padding(.horizontal, MarketplaceTheme.Spacing.md)
                        }
                    }
                }

                // Scripts section
                if !viewModel.scripts.isEmpty {
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                        Text("Popular Scripts")
                            .marketplaceSectionHeader()
                            .padding(.horizontal, MarketplaceTheme.Spacing.md)

                        ForEach(viewModel.scripts) { script in
                            ScriptCard(script: script, onUnlock: {})
                                .padding(.horizontal, MarketplaceTheme.Spacing.md)
                        }
                    }
                }
            }
            .padding(.vertical, MarketplaceTheme.Spacing.md)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - Clusters Tab

struct ClustersTabView: View {
    @ObservedObject var viewModel: MarketplaceViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                // Active clusters
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                    Text("Active Clusters")
                        .marketplaceSectionHeader()
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)

                    ForEach(viewModel.filteredClusters) { cluster in
                        ClusterCard(
                            cluster: cluster,
                            onPlaceBid: { viewModel.placeBid(for: cluster) },
                            onClaimOffer: cluster.flashDropOffer != nil ? {} : nil
                        )
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)
                    }
                }

                // Empty state
                if viewModel.filteredClusters.isEmpty {
                    emptyState(
                        icon: "person.3",
                        title: "No clusters found",
                        message: "Try a different search or check back later"
                    )
                }
            }
            .padding(.vertical, MarketplaceTheme.Spacing.md)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - Experts Tab

struct ExpertsTabView: View {
    @ObservedObject var viewModel: MarketplaceViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                // Services
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                    Text("Bill Services")
                        .marketplaceSectionHeader()
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)

                    ForEach(viewModel.services) { service in
                        ServiceCard(service: service, onRequest: {})
                            .padding(.horizontal, MarketplaceTheme.Spacing.md)
                    }
                }

                // Bounties
                if !viewModel.bounties.isEmpty {
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                        Text("Data Bounties")
                            .marketplaceSectionHeader()
                            .padding(.horizontal, MarketplaceTheme.Spacing.md)

                        ForEach(viewModel.bounties) { bounty in
                            BountyCard(bounty: bounty, onSubmit: {})
                                .padding(.horizontal, MarketplaceTheme.Spacing.md)
                        }
                    }
                }
            }
            .padding(.vertical, MarketplaceTheme.Spacing.md)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - Signals Tab

struct SignalsTabView: View {
    @ObservedObject var viewModel: MarketplaceViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                // Predictions
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                    Text("Prediction Markets")
                        .marketplaceSectionHeader()
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)

                    ForEach(viewModel.predictions) { prediction in
                        PredictionCard(
                            prediction: prediction,
                            onStakeYes: {},
                            onStakeNo: {}
                        )
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)
                    }
                }

                // Empty state
                if viewModel.predictions.isEmpty {
                    emptyState(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "No predictions yet",
                        message: "Check back for rate predictions and market signals"
                    )
                }
            }
            .padding(.vertical, MarketplaceTheme.Spacing.md)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - Helper Views

private func emptyState(icon: String, title: String, message: String) -> some View {
    VStack(spacing: MarketplaceTheme.Spacing.md) {
        Image(systemName: icon)
            .font(.system(size: 40))
            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

        Text(title)
            .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

        Text(message)
            .font(.system(size: MarketplaceTheme.Typography.caption))
            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, MarketplaceTheme.Spacing.xxxl)
}

// MARK: - Previews

#Preview {
    MarketplaceView()
}
