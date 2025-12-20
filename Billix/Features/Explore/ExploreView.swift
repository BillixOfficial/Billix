//
//  ExploreView.swift
//  Billix
//
//  Created by Claude Code on 11/27/25.
//

import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @State private var showSearch: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MarketplaceTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()

                // Content based on view mode
                if viewModel.viewMode == .map {
                    mapContent
                } else {
                    feedContent
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    viewModeToggle
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showSearch) {
            ExploreSearchSheet(viewModel: viewModel)
        }
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        HStack(spacing: 0) {
            ForEach(ExploreViewMode.allCases, id: \.rawValue) { mode in
                Button {
                    withAnimation(MarketplaceTheme.Animation.quick) {
                        viewModel.viewMode = mode
                    }
                } label: {
                    HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12))

                        Text(mode.rawValue)
                            .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                    }
                    .foregroundStyle(viewModel.viewMode == mode ? .white : MarketplaceTheme.Colors.textSecondary)
                    .padding(.horizontal, MarketplaceTheme.Spacing.sm)
                    .padding(.vertical, MarketplaceTheme.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(viewModel.viewMode == mode ? MarketplaceTheme.Colors.primary : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(MarketplaceTheme.Colors.backgroundSecondary)
        )
    }

    // MARK: - Feed Content

    private var feedContent: some View {
        ScrollView {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                // Section selector
                sectionSelector
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)

                // Content based on selected section
                Group {
                    switch viewModel.selectedSection {
                    case .simulator:
                        simulatorSection
                    case .marketplace:
                        marketplaceSection
                    case .gougeIndex:
                        gougeIndexSection
                    }
                }
                .padding(.horizontal, MarketplaceTheme.Spacing.md)

                // Bottom padding for tab bar
                Spacer()
                    .frame(height: 100)
            }
            .padding(.top, MarketplaceTheme.Spacing.md)
        }
        .refreshable {
            await viewModel.loadMockData()
        }
    }

    // MARK: - Section Selector

    private var sectionSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                ForEach(ExploreSection.allCases, id: \.rawValue) { section in
                    sectionTab(section)
                }
            }
        }
    }

    private func sectionTab(_ section: ExploreSection) -> some View {
        let isSelected = viewModel.selectedSection == section

        return Button {
            withAnimation(MarketplaceTheme.Animation.quick) {
                viewModel.selectedSection = section
            }
        } label: {
            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                Image(systemName: section.icon)
                    .font(.system(size: 14))

                Text(section.rawValue)
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : MarketplaceTheme.Colors.textSecondary)
            .padding(.horizontal, MarketplaceTheme.Spacing.md)
            .padding(.vertical, MarketplaceTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? sectionColor(for: section) : MarketplaceTheme.Colors.backgroundCard)
            )
            .shadow(
                color: isSelected ? sectionColor(for: section).opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionColor(for section: ExploreSection) -> Color {
        switch section {
        case .simulator: return MarketplaceTheme.Colors.warning
        case .marketplace: return MarketplaceTheme.Colors.primary
        case .gougeIndex: return MarketplaceTheme.Colors.danger
        }
    }

    // MARK: - Simulator Section

    private var simulatorSection: some View {
        VStack(spacing: MarketplaceTheme.Spacing.lg) {
            // Recession Simulator
            RecessionSimulatorView(viewModel: viewModel)

            // Make Me Move
            MakeMeMoveView(viewModel: viewModel)

            // Outage Bot
            OutageBotView(viewModel: viewModel)
        }
    }

    // MARK: - Marketplace Section

    private var marketplaceSection: some View {
        VStack(spacing: MarketplaceTheme.Spacing.md) {
            // Quick access to full marketplace
            NavigationLink {
                MarketplaceView()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxxs) {
                        Text("Bill Marketplace")
                            .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        Text("Browse deals, clusters, and expert scripts")
                            .font(.system(size: MarketplaceTheme.Typography.caption))
                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(MarketplaceTheme.Colors.primary)
                }
                .padding(MarketplaceTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.xl)
                        .fill(MarketplaceTheme.Colors.backgroundCard)
                        .shadow(
                            color: MarketplaceTheme.Shadows.medium.color,
                            radius: MarketplaceTheme.Shadows.medium.radius,
                            x: 0,
                            y: MarketplaceTheme.Shadows.medium.y
                        )
                )
            }
            .buttonStyle(.plain)

            // Embedded mini heatmap
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                HStack {
                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(MarketplaceTheme.Colors.primary)

                        Text("Price Map")
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    }

                    Spacer()

                    Button {
                        withAnimation(MarketplaceTheme.Animation.quick) {
                            viewModel.viewMode = .map
                        }
                    } label: {
                        Text("Full Map")
                            .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                            .foregroundStyle(MarketplaceTheme.Colors.primary)
                    }
                }

                Text("See how your area compares on \(viewModel.heatmapCategory.rawValue) pricing")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                // Mini zone cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        ForEach(viewModel.heatmapZones.prefix(4)) { zone in
                            miniZoneCard(zone)
                        }
                    }
                }
            }
            .padding(MarketplaceTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.xl)
                    .fill(MarketplaceTheme.Colors.backgroundCard)
            )
        }
    }

    private func miniZoneCard(_ zone: HeatmapZone) -> some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxs) {
            HStack {
                Text("ZIP \(zone.zipCode)")
                    .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                Spacer()

                Circle()
                    .fill(zone.tier.color)
                    .frame(width: 8, height: 8)
            }

            Text("$\(Int(zone.averagePrice))/mo")
                .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                .foregroundStyle(zone.tier.color)

            Text(zone.tier == .gouging ? "Price Gouging" : zone.tier.rawValue)
                .font(.system(size: 9))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
        .frame(width: 90)
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(zone.tier.color.opacity(0.1))
        )
    }

    // MARK: - Gouge Index Section

    private var gougeIndexSection: some View {
        GougeIndexView(viewModel: viewModel)
    }

    // MARK: - Map Content

    private var mapContent: some View {
        BillHeatmapView(viewModel: viewModel)
    }
}

// MARK: - Search Sheet

struct ExploreSearchSheet: View {
    @ObservedObject var viewModel: ExploreViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var searchCategory: String = "All"

    private let categories = ["All", "Providers", "Deals", "ZIP Codes"]

    var body: some View {
        NavigationStack {
            VStack(spacing: MarketplaceTheme.Spacing.md) {
                // Search bar
                HStack(spacing: MarketplaceTheme.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    TextField("Search providers, deals, ZIP codes...", text: $searchText)
                        .font(.system(size: MarketplaceTheme.Typography.body))

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                        }
                    }
                }
                .padding(MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                )
                .padding(.horizontal, MarketplaceTheme.Spacing.md)

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                searchCategory = category
                            } label: {
                                Text(category)
                                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                                    .foregroundStyle(searchCategory == category ? .white : MarketplaceTheme.Colors.textSecondary)
                                    .padding(.horizontal, MarketplaceTheme.Spacing.sm)
                                    .padding(.vertical, MarketplaceTheme.Spacing.xs)
                                    .background(
                                        Capsule()
                                            .fill(searchCategory == category ? MarketplaceTheme.Colors.primary : MarketplaceTheme.Colors.backgroundSecondary)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)
                }

                // Results or suggestions
                if searchText.isEmpty {
                    searchSuggestions
                } else {
                    searchResults
                }

                Spacer()
            }
            .padding(.top, MarketplaceTheme.Spacing.md)
            .navigationTitle("Search")
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

    private var searchSuggestions: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.md) {
            Text("Popular Searches")
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                .padding(.horizontal, MarketplaceTheme.Spacing.md)

            VStack(spacing: MarketplaceTheme.Spacing.xs) {
                suggestionRow(icon: "wifi", text: "Internet deals under $50")
                suggestionRow(icon: "bolt.fill", text: "Fixed-rate energy plans")
                suggestionRow(icon: "location", text: "Price gouging in 07030")
                suggestionRow(icon: "flame.fill", text: "Most hated providers")
            }
            .padding(.horizontal, MarketplaceTheme.Spacing.md)
        }
    }

    private func suggestionRow(icon: String, text: String) -> some View {
        Button {
            searchText = text
        } label: {
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    .frame(width: 24)

                Text(text)
                    .font(.system(size: MarketplaceTheme.Typography.callout))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Spacer()

                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
            .padding(MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )
        }
        .buttonStyle(.plain)
    }

    private var searchResults: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.md) {
                Text("Results")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)

                // Mock results
                VStack(spacing: MarketplaceTheme.Spacing.xs) {
                    searchResultRow(
                        icon: "wifi",
                        title: "Verizon Fios 300",
                        subtitle: "Internet • $49.99/mo",
                        badge: "Deal"
                    )

                    searchResultRow(
                        icon: "bolt.fill",
                        title: "PSEG",
                        subtitle: "Energy Provider • +15% above market",
                        badge: "Provider"
                    )

                    searchResultRow(
                        icon: "location",
                        title: "ZIP 07030",
                        subtitle: "Price Gouging Zone • Internet",
                        badge: "Location"
                    )
                }
                .padding(.horizontal, MarketplaceTheme.Spacing.md)
            }
        }
    }

    private func searchResultRow(icon: String, title: String, subtitle: String, badge: String) -> some View {
        HStack(spacing: MarketplaceTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(MarketplaceTheme.Colors.primary.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(MarketplaceTheme.Colors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Text(subtitle)
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }

            Spacer()

            Text(badge)
                .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                .foregroundStyle(MarketplaceTheme.Colors.primary)
                .padding(.horizontal, MarketplaceTheme.Spacing.xs)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(MarketplaceTheme.Colors.primary.opacity(0.15))
                )

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(MarketplaceTheme.Colors.backgroundSecondary)
        )
    }
}

#Preview {
    ExploreView()
}
