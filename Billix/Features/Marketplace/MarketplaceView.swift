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
                .presentationBackground(Color(hex: "#F5F7F6"))
        }
        .sheet(isPresented: $viewModel.showUnlockSheet) {
            if let listing = viewModel.selectedListing {
                UnlockBlueprintSheet(listing: listing)
                    .presentationDetents([.medium])
                    .presentationBackground(Color(hex: "#F5F7F6"))
            }
        }
        .sheet(isPresented: $viewModel.showAskOwnerSheet) {
            if let listing = viewModel.selectedListing {
                AskOwnerSheet(listing: listing)
                    .presentationDetents([.medium])
                    .presentationBackground(Color(hex: "#F5F7F6"))
            }
        }
        .sheet(isPresented: $viewModel.showPlaceBidSheet) {
            if let cluster = viewModel.selectedCluster {
                PlaceBidSheet(cluster: cluster)
                    .presentationDetents([.medium, .large])
                    .presentationBackground(Color(hex: "#F5F7F6"))
            }
        }
        // TODO: Add cluster sheets when files are added to Xcode
        // .sheet(isPresented: $viewModel.showCreateClusterSheet) {
        //     CreateClusterSheet(viewModel: viewModel)
        //         .presentationDetents([.large])
        //         .presentationBackground(Color(hex: "#F5F7F6"))
        // }
        // .sheet(isPresented: $viewModel.showJoinClusterSheet) {
        //     if let cluster = viewModel.selectedMarketplaceCluster {
        //         JoinClusterSheet(cluster: cluster, viewModel: viewModel)
        //             .presentationDetents([.medium])
        //             .presentationBackground(Color(hex: "#F5F7F6"))
        //     }
        // }
        // .sheet(isPresented: $viewModel.showShareDealSheet) {
        //     ShareDealSheet(viewModel: viewModel)
        //         .presentationDetents([.large])
        //         .presentationBackground(Color(hex: "#F5F7F6"))
        // }
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
        .background(MarketplaceTheme.Colors.backgroundPrimary)
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
            .foregroundStyle(viewModel.selectedTab == tab ? .white : MarketplaceTheme.Colors.textPrimary)
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
                            .stroke(MarketplaceTheme.Colors.primary.opacity(0.3), lineWidth: 1.5)
                            .background(Capsule().fill(Color.white))
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

// MARK: - Deals Tab (Redesigned)

struct DealsTabView: View {
    @ObservedObject var viewModel: MarketplaceViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                // TODO: Share Deal CTA - Add when files are in Xcode
                // ShareDealCTACard(onTap: { viewModel.shareDeal() })
                //     .padding(.horizontal, MarketplaceTheme.Spacing.md)

                // TODO: Provider Aggregates - Add when files are in Xcode
                // if !viewModel.filteredAggregates.isEmpty {
                //     VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                //         HStack {
                //             Text("Average Bills in Your Area")
                //                 .marketplaceSectionHeader()
                //
                //             Spacer()
                //
                //             Text(viewModel.userZipCode.prefix(3) + "XX")
                //                 .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                //                 .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                //                 .padding(.horizontal, 8)
                //                 .padding(.vertical, 4)
                //                 .background(Capsule().fill(MarketplaceTheme.Colors.backgroundSecondary))
                //         }
                //         .padding(.horizontal, MarketplaceTheme.Spacing.md)
                //
                //         ForEach(viewModel.filteredAggregates) { aggregate in
                //             ProviderAggregateCard(
                //                 aggregate: aggregate,
                //                 onCompare: { viewModel.compareBill(to: aggregate) },
                //                 onDetails: nil
                //             )
                //             .padding(.horizontal, MarketplaceTheme.Spacing.md)
                //         }
                //     }
                // }

                // TODO: Featured Deals - Add when files are in Xcode
                // if !viewModel.filteredFeaturedDeals.isEmpty {
                //     VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                //         HStack {
                //             Text("Featured Deals")
                //                 .marketplaceSectionHeader()
                //
                //             Spacer()
                //
                //             Image(systemName: "star.fill")
                //                 .font(.system(size: 12))
                //                 .foregroundStyle(MarketplaceTheme.Colors.accent)
                //         }
                //         .padding(.horizontal, MarketplaceTheme.Spacing.md)
                //
                //         ForEach(viewModel.filteredFeaturedDeals) { deal in
                //             FeaturedDealCard(
                //                 deal: deal,
                //                 onUnlock: {
                //                     Task {
                //                         try? await viewModel.unlockFeaturedDeal(deal)
                //                     }
                //                 }
                //             )
                //             .padding(.horizontal, MarketplaceTheme.Spacing.md)
                //         }
                //     }
                // }

                // Empty state - show placeholder for now
                // if viewModel.filteredAggregates.isEmpty && viewModel.filteredFeaturedDeals.isEmpty {
                if true {
                    emptyState(
                        icon: "chart.bar.doc.horizontal",
                        title: "No deals in your area yet",
                        message: "Be the first to share your bill and earn points!"
                    )
                }
            }
            .padding(.vertical, MarketplaceTheme.Spacing.md)
        }
        .refreshable {
            await viewModel.refreshTab(.deals)
        }
    }
}

// MARK: - Clusters Tab (Redesigned)

struct ClustersTabView: View {
    @ObservedObject var viewModel: MarketplaceViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                // Create Cluster CTA
                CreateClusterCTACard(onTap: { viewModel.createCluster() })
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)

                // Active clusters
                if !viewModel.filteredMarketplaceClusters.isEmpty {
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                        HStack {
                            Text("Active Clusters")
                                .marketplaceSectionHeader()

                            Spacer()

                            Text("\(viewModel.filteredMarketplaceClusters.count) open")
                                .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                                .foregroundStyle(MarketplaceTheme.Colors.success)
                        }
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)

                        ForEach(viewModel.filteredMarketplaceClusters) { cluster in
                            MarketplaceClusterCard(
                                cluster: cluster,
                                onJoin: { viewModel.joinCluster(cluster) }
                            )
                            .padding(.horizontal, MarketplaceTheme.Spacing.md)
                        }
                    }
                }

                // Empty state
                if viewModel.filteredMarketplaceClusters.isEmpty {
                    emptyState(
                        icon: "person.3",
                        title: "No clusters in your area yet",
                        message: "Start a cluster and invite others to negotiate together!"
                    )
                }
            }
            .padding(.vertical, MarketplaceTheme.Spacing.md)
        }
        .refreshable {
            await viewModel.refreshTab(.clusters)
        }
    }
}

// MARK: - Create Cluster CTA Card

struct CreateClusterCTACard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(MarketplaceTheme.Colors.success.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.3.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(MarketplaceTheme.Colors.success)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Start a Cluster")
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    Text("Negotiate together with 5+ neighbors")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("7-30 days")
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }
            }
            .padding(MarketplaceTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                    .fill(MarketplaceTheme.Colors.backgroundCard)
                    .stroke(
                        MarketplaceTheme.Colors.success.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Marketplace Cluster Card

struct MarketplaceClusterCard: View {
    let cluster: MarketplaceCluster
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header
            HStack {
                // Category icon
                ZStack {
                    Circle()
                        .fill(MarketplaceTheme.Colors.primary.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: cluster.categoryIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(MarketplaceTheme.Colors.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(cluster.title)
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    Text("\(cluster.providerName ?? "Provider") • \(cluster.category.capitalized)")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                Spacer()

                // Status badge
                ClusterStatusBadge(status: cluster.status)
            }

            // Goal
            Text(cluster.goalDescription)
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                .lineLimit(2)

            // Stats row
            HStack(spacing: MarketplaceTheme.Spacing.md) {
                // Members
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                    Text("\(cluster.memberCount)/\(cluster.maxMembers)")
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                }
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                // Time remaining
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                    Text(cluster.timeRemainingDisplay ?? "")
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                }
                .foregroundStyle(cluster.isUrgent ? MarketplaceTheme.Colors.warning : MarketplaceTheme.Colors.textSecondary)

                Spacer()
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(MarketplaceTheme.Colors.success)
                        .frame(width: geo.size.width * cluster.memberProgress, height: 6)
                }
            }
            .frame(height: 6)

            // Join button
            if cluster.canJoin {
                Button(action: onJoin) {
                    Text("Join Cluster")
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MarketplaceTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.sm)
                                .fill(MarketplaceTheme.Colors.success)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(MarketplaceTheme.Colors.backgroundCard)
                .shadow(
                    color: MarketplaceTheme.Shadows.low.color,
                    radius: MarketplaceTheme.Shadows.low.radius,
                    x: 0, y: 2
                )
        )
    }
}

// MARK: - Cluster Status Badge

struct ClusterStatusBadge: View {
    let status: MarketplaceClusterStatus

    var body: some View {
        Text(status.displayName)
            .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
    }

    private var textColor: Color {
        switch status {
        case .forming: return MarketplaceTheme.Colors.info
        case .active: return MarketplaceTheme.Colors.success
        case .negotiating: return MarketplaceTheme.Colors.warning
        case .goalReached: return MarketplaceTheme.Colors.success
        case .completed: return MarketplaceTheme.Colors.textSecondary
        case .expired: return MarketplaceTheme.Colors.danger
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.15)
    }
}

// MARK: - Experts Tab (Redesigned)

struct ExpertsTabView: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @State private var showOfferServiceSheet = false
    @State private var showPostBountySheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                // Quick Actions - Stacked Full Width
                quickActionsSection
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)

                // Services
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                    Text("Bill Services")
                        .marketplaceSectionHeader()
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)

                    if viewModel.services.isEmpty {
                        emptyServicesState
                    } else {
                        ForEach(viewModel.services) { service in
                            ServiceCard(service: service, onRequest: {
                                viewModel.requestService(service)
                            })
                            .padding(.horizontal, MarketplaceTheme.Spacing.md)
                        }
                    }
                }

                // Bounties
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                    Text("Data Bounties")
                        .marketplaceSectionHeader()
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)

                    if viewModel.bounties.isEmpty {
                        emptyBountiesState
                    } else {
                        ForEach(viewModel.bounties) { bounty in
                            BountyCard(bounty: bounty, onSubmit: {
                                viewModel.claimBounty(bounty)
                            })
                            .padding(.horizontal, MarketplaceTheme.Spacing.md)
                        }
                    }
                }
            }
            .padding(.vertical, MarketplaceTheme.Spacing.md)
        }
        .refreshable {
            await viewModel.refreshTab(.experts)
        }
        // TODO: Add service sheets when files are in Xcode
        // .sheet(isPresented: $showOfferServiceSheet) {
        //     OfferServiceSheet(viewModel: viewModel)
        // }
        // .sheet(isPresented: $showPostBountySheet) {
        //     PostBountySheet(viewModel: viewModel)
        // }
    }

    // MARK: - Quick Actions (Stacked Full-Width)

    private var quickActionsSection: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Offer Service Button - Full Width
            Button {
                showOfferServiceSheet = true
            } label: {
                HStack(spacing: MarketplaceTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(MarketplaceTheme.Colors.primary.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(MarketplaceTheme.Colors.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Offer Your Service")
                            .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        Text("Help others negotiate their bills")
                            .font(.system(size: MarketplaceTheme.Typography.caption))
                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }
                .padding(MarketplaceTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                        .fill(MarketplaceTheme.Colors.backgroundCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                .stroke(MarketplaceTheme.Colors.primary.opacity(0.3), lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // Post Bounty Button - Full Width
            Button {
                showPostBountySheet = true
            } label: {
                HStack(spacing: MarketplaceTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(MarketplaceTheme.Colors.accent.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: "scope")
                            .font(.system(size: 18))
                            .foregroundStyle(MarketplaceTheme.Colors.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Post a Bounty")
                            .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        Text("Request specific bill data")
                            .font(.system(size: MarketplaceTheme.Typography.caption))
                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text("25+ pts")
                            .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                    }
                    .foregroundStyle(MarketplaceTheme.Colors.accent)
                }
                .padding(MarketplaceTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                        .fill(MarketplaceTheme.Colors.backgroundCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                .stroke(MarketplaceTheme.Colors.accent.opacity(0.3), lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - Empty States

    private var emptyServicesState: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 32))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            Text("No services yet")
                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

            Text("Be the first to offer your expertise!")
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MarketplaceTheme.Spacing.xl)
        .padding(.horizontal, MarketplaceTheme.Spacing.md)
    }

    private var emptyBountiesState: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            Image(systemName: "scope")
                .font(.system(size: 32))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            Text("No bounties yet")
                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

            Text("Post a bounty to find specific bill data")
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MarketplaceTheme.Spacing.xl)
        .padding(.horizontal, MarketplaceTheme.Spacing.md)
    }
}

// MARK: - Signals Tab (Redesigned)

struct SignalsTabView: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @State private var selectedCategory: String? = nil
    @State private var showVoteSuccess = false
    @State private var lastVotedSignalId: UUID?

    private let categories = ["All", "energy", "internet", "mobile", "insurance", "streaming"]

    var body: some View {
        ScrollView {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                // Category Filter Pills
                categoryFilterSection

                // Featured "Hot" Prediction
                if let hotSignal = hotSignal {
                    featuredPredictionCard(hotSignal)
                        .padding(.horizontal, MarketplaceTheme.Spacing.md)
                }

                // TODO: Market Pulse Card - Add when files are in Xcode
                // if !viewModel.marketPulse.isEmpty {
                //     MarketPulseCard(sentiments: viewModel.marketPulse)
                //         .padding(.horizontal, MarketplaceTheme.Spacing.md)
                // }

                // TODO: Your Votes Section - Add when files are in Xcode
                // if hasUserVotes {
                //     yourVotesSection
                // }

                // Active Signals - placeholder for now
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                    HStack {
                        Text("Active Predictions")
                            .marketplaceSectionHeader()

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("AI Generated")
                                .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                        }
                        .foregroundStyle(MarketplaceTheme.Colors.primary)
                    }
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)

                    // Show empty state for now
                    emptyState(
                        icon: "waveform.path.ecg",
                        title: "No predictions yet",
                        message: "AI-generated predictions coming soon!"
                    )
                    // TODO: Add SignalCard when files are in Xcode
                    // if filteredByCategory.isEmpty {
                    //     emptyState(...)
                    // } else {
                    //     ForEach(filteredByCategory) { signal in
                    //         SignalCard(...)
                    //     }
                    // }
                }

                // How It Works
                howItWorksSection
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)
            }
            .padding(.vertical, MarketplaceTheme.Spacing.md)
        }
        .refreshable {
            await viewModel.refreshTab(.signals)
        }
    }

    // MARK: - Category Filter

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                ForEach(categories, id: \.self) { category in
                    categoryPill(category)
                }
            }
            .padding(.horizontal, MarketplaceTheme.Spacing.md)
        }
    }

    private func categoryPill(_ category: String) -> some View {
        let isSelected = (category == "All" && selectedCategory == nil) || selectedCategory == category

        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedCategory = category == "All" ? nil : category
            }
        } label: {
            HStack(spacing: 4) {
                if category != "All" {
                    Image(systemName: categoryIcon(for: category))
                        .font(.system(size: 10))
                }
                Text(category.capitalized)
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : MarketplaceTheme.Colors.textPrimary)
            .padding(.horizontal, MarketplaceTheme.Spacing.sm)
            .padding(.vertical, MarketplaceTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? MarketplaceTheme.Colors.primary : Color.white)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : MarketplaceTheme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "energy": return "bolt.fill"
        case "internet": return "wifi"
        case "mobile": return "iphone"
        case "insurance": return "shield.fill"
        case "streaming": return "play.tv.fill"
        default: return "chart.bar.fill"
        }
    }

    // MARK: - Featured Prediction

    private var hotSignal: MarketplaceSignal? {
        viewModel.signals.first { $0.activityLevel == .hot }
    }

    private func featuredPredictionCard(_ signal: MarketplaceSignal) -> some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Hot badge
            HStack {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 12))
                    Text("TRENDING NOW")
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .heavy))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, MarketplaceTheme.Spacing.sm)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                )

                Spacer()

                if let provider = signal.providerName {
                    Text(provider)
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }
            }

            // Question
            Text(signal.question)
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .bold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            // Quick vote bar
            VotingPercentageBar(yesPercentage: signal.yesPercentage)

            // Vote buttons
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                quickVoteButton(signal: signal, vote: "yes", label: "Yes", color: MarketplaceTheme.Colors.success)
                quickVoteButton(signal: signal, vote: "no", label: "No", color: MarketplaceTheme.Colors.danger)
            }

            // Activity indicator
            HStack {
                PulseDotsView(activityLevel: signal.activityLevel)
                Spacer()
                Text(signal.expiresDisplay)
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(MarketplaceTheme.Colors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.5), Color.red.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.orange.opacity(0.2), radius: 12, x: 0, y: 4)
        )
    }

    private func quickVoteButton(signal: MarketplaceSignal, vote: String, label: String, color: Color) -> some View {
        let hasVoted = viewModel.userVotes[signal.id] != nil
        let isThisVote = viewModel.userVotes[signal.id] == vote

        return Button {
            voteOnSignal(signal, vote: vote)
        } label: {
            Text(label)
                .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                .foregroundStyle(isThisVote ? .white : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(isThisVote ? color : color.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .stroke(color.opacity(isThisVote ? 0 : 0.5), lineWidth: 1.5)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(hasVoted && !isThisVote)
        .opacity(hasVoted && !isThisVote ? 0.5 : 1)
    }

    // MARK: - Voting

    private func voteOnSignal(_ signal: MarketplaceSignal, vote: String) {
        // Optimistic update
        viewModel.userVotes[signal.id] = vote

        // Show success animation
        lastVotedSignalId = signal.id
        withAnimation(.spring(response: 0.3)) {
            showVoteSuccess = true
        }

        // Hide after delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation {
                showVoteSuccess = false
            }
        }

        // Actually save to backend
        Task {
            try? await viewModel.voteOnSignal(signal, vote: vote)
        }
    }

    // MARK: - Filtered Signals

    private var filteredByCategory: [MarketplaceSignal] {
        let signals = viewModel.filteredSignals
        guard let category = selectedCategory else { return signals }
        return signals.filter { $0.category.lowercased() == category.lowercased() }
    }

    // MARK: - User Votes

    private var hasUserVotes: Bool {
        !viewModel.userVotes.isEmpty
    }

    private var yourVotesSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xs) {
            Text("Your Votes")
                .marketplaceSectionHeader()
                .padding(.horizontal, MarketplaceTheme.Spacing.md)

            VStack(spacing: 0) {
                ForEach(votedSignals) { signal in
                    if let vote = viewModel.userVotes[signal.id] {
                        SignalCardCompact(signal: signal, userVote: vote)
                            .padding(.horizontal, MarketplaceTheme.Spacing.md)

                        if signal.id != votedSignals.last?.id {
                            Divider()
                                .background(MarketplaceTheme.Colors.textTertiary.opacity(0.2))
                                .padding(.horizontal, MarketplaceTheme.Spacing.md)
                        }
                    }
                }
            }
            .padding(.vertical, MarketplaceTheme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                    .fill(MarketplaceTheme.Colors.backgroundCard)
            )
            .padding(.horizontal, MarketplaceTheme.Spacing.md)
        }
    }

    private var votedSignals: [MarketplaceSignal] {
        viewModel.signals.filter { viewModel.userVotes[$0.id] != nil }
    }

    // MARK: - How It Works

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            Text("How Signals Work")
                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .bold))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

            VStack(spacing: MarketplaceTheme.Spacing.xs) {
                howItWorksRow(icon: "sparkles", text: "AI analyzes market trends & news")
                howItWorksRow(icon: "hand.thumbsup.fill", text: "Vote on predictions you agree with")
                howItWorksRow(icon: "chart.bar.fill", text: "Track community sentiment")
                howItWorksRow(icon: "bell.fill", text: "Get notified when predictions resolve")
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(MarketplaceTheme.Colors.backgroundSecondary.opacity(0.5))
        )
    }

    private func howItWorksRow(icon: String, text: String) -> some View {
        HStack(spacing: MarketplaceTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(MarketplaceTheme.Colors.primary)
                .frame(width: 20)

            Text(text)
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

            Spacer()
        }
    }
}

// MARK: - Helper Views

private func emptyState(icon: String, title: String, message: String) -> some View {
    VStack(spacing: MarketplaceTheme.Spacing.md) {
        ZStack {
            Circle()
                .fill(MarketplaceTheme.Colors.primary.opacity(0.1))
                .frame(width: 80, height: 80)

            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(MarketplaceTheme.Colors.primary.opacity(0.6))
        }

        Text(title)
            .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

        Text(message)
            .font(.system(size: MarketplaceTheme.Typography.caption))
            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, MarketplaceTheme.Spacing.xl)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, MarketplaceTheme.Spacing.xxl)
    .padding(.horizontal, MarketplaceTheme.Spacing.md)
    .background(
        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
            .fill(MarketplaceTheme.Colors.backgroundCard)
            .shadow(
                color: MarketplaceTheme.Shadows.low.color,
                radius: MarketplaceTheme.Shadows.low.radius,
                x: 0, y: 2
            )
    )
    .padding(.horizontal, MarketplaceTheme.Spacing.md)
}

// MARK: - Vote Success Overlay

struct VoteSuccessOverlay: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            Circle()
                .fill(MarketplaceTheme.Colors.success.opacity(0.2))
                .frame(width: 100, height: 100)
                .scaleEffect(scale)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(MarketplaceTheme.Colors.success)
                .scaleEffect(scale)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.2
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.8)) {
                opacity = 0
                scale = 0.8
            }
        }
    }
}

// MARK: - Inline Signal Components (until files added to Xcode)

struct VotingPercentageBar: View {
    let yesPercentage: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(MarketplaceTheme.Colors.danger.opacity(0.3))

                RoundedRectangle(cornerRadius: 4)
                    .fill(MarketplaceTheme.Colors.success)
                    .frame(width: geo.size.width * (yesPercentage / 100))
            }
        }
        .frame(height: 8)
    }
}

struct PulseDotsView: View {
    let activityLevel: SignalActivityLevel

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        switch activityLevel {
        case .hot:
            return MarketplaceTheme.Colors.success
        case .active:
            return index < 2 ? MarketplaceTheme.Colors.warning : MarketplaceTheme.Colors.textTertiary.opacity(0.3)
        case .cooling:
            return index < 1 ? MarketplaceTheme.Colors.textTertiary : MarketplaceTheme.Colors.textTertiary.opacity(0.3)
        case .settled:
            return MarketplaceTheme.Colors.textTertiary.opacity(0.3)
        }
    }
}

struct SignalCardCompact: View {
    let signal: MarketplaceSignal
    let userVote: String

    var body: some View {
        HStack(spacing: MarketplaceTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill((userVote == "yes" ? MarketplaceTheme.Colors.success : MarketplaceTheme.Colors.danger).opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: userVote == "yes" ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(userVote == "yes" ? MarketplaceTheme.Colors.success : MarketplaceTheme.Colors.danger)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(signal.question)
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text("You voted \(userVote.capitalized)")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(userVote == "yes" ? MarketplaceTheme.Colors.success : MarketplaceTheme.Colors.danger)

                    Text("•")
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text("\(userVote == "yes" ? signal.yesPercentage : 100 - signal.yesPercentage, specifier: "%.0f")% agree")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, MarketplaceTheme.Spacing.xs)
    }
}

// MARK: - Previews

#Preview {
    MarketplaceView()
}
