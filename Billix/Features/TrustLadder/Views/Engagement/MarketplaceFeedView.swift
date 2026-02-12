//
//  MarketplaceFeedView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Live marketplace activity feed showing anonymized swap activity
//

import SwiftUI

struct MarketplaceFeedView: View {
    @StateObject private var feedService = MarketplaceFeedService.shared
    @State private var showFilters = false

    // Theme colors
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Live indicator
                liveIndicatorBar

                ScrollView {
                    VStack(spacing: 16) {
                        // Statistics card
                        statisticsCard

                        // Hot categories
                        if !feedService.statistics.hotCategories.isEmpty {
                            hotCategoriesCard
                        }

                        // Activity feed
                        activityFeedSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Live Feed")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(primaryText)
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            FeedFiltersView()
        }
        .onAppear {
            feedService.startLiveUpdates()
        }
        .onDisappear {
            feedService.stopLiveUpdates()
        }
        .refreshable {
            await feedService.loadFeed()
            await feedService.loadStatistics()
        }
    }

    // MARK: - Live Indicator

    private var liveIndicatorBar: some View {
        HStack(spacing: 8) {
            // Live dot
            Circle()
                .fill(feedService.isLive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                        .scaleEffect(feedService.isLive ? 1.5 : 1)
                        .opacity(feedService.isLive ? 0 : 1)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: feedService.isLive)
                )

            Text(feedService.isLive ? "Live" : "Paused")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(feedService.isLive ? .green : secondaryText)

            Spacer()

            // Activity level
            HStack(spacing: 4) {
                Image(systemName: feedService.activityIndicator.level.icon)
                    .font(.system(size: 12))
                Text(feedService.activityIndicator.message)
                    .font(.system(size: 12))
            }
            .foregroundColor(feedService.activityIndicator.level.color)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(cardBg)
    }

    // MARK: - Statistics Card

    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Activity")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(secondaryText)

            HStack(spacing: 16) {
                statItem(
                    value: "\(feedService.statistics.totalActiveListings)",
                    label: "Active Listings",
                    icon: "list.bullet",
                    color: .blue
                )

                statItem(
                    value: "\(feedService.statistics.swapsCompletedToday)",
                    label: "Swaps Today",
                    icon: "checkmark.circle",
                    color: .green
                )

                statItem(
                    value: feedService.statistics.formattedMatchTime,
                    label: "Avg Match",
                    icon: "clock",
                    color: .orange
                )
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(primaryText)
            }

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Hot Categories

    private var hotCategoriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Hot Categories")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(feedService.statistics.hotCategories) { hot in
                        hotCategoryChip(hot)
                    }
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func hotCategoryChip(_ hot: HotCategory) -> some View {
        HStack(spacing: 6) {
            Image(systemName: hot.billCategory?.icon ?? "doc")
                .font(.system(size: 12))
                .foregroundColor(hot.billCategory?.color ?? .gray)

            Text(hot.billCategory?.displayName ?? hot.category)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(primaryText)

            HStack(spacing: 2) {
                Image(systemName: hot.trendIcon)
                    .font(.system(size: 9))
                Text("\(Int(hot.trend))%")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(hot.trendColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(cardBg.opacity(0.8))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(hot.billCategory?.color.opacity(0.3) ?? Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Activity Feed

    private var activityFeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(secondaryText)

                Spacer()

                if feedService.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            if feedService.feedEvents.isEmpty {
                emptyFeedState
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(feedService.feedEvents.prefix(30)) { event in
                        feedEventRow(event)
                    }
                }
            }
        }
    }

    private var emptyFeedState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 36))
                .foregroundColor(secondaryText)

            Text("No recent activity")
                .font(.system(size: 14))
                .foregroundColor(secondaryText)

            Text("Swap activity will appear here when people in your area start swapping")
                .font(.system(size: 12))
                .foregroundColor(secondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private func feedEventRow(_ event: MarketplaceFeedEvent) -> some View {
        HStack(spacing: 12) {
            // Event icon
            Image(systemName: event.type?.icon ?? "circle")
                .font(.system(size: 14))
                .foregroundColor(event.type?.color ?? .gray)
                .frame(width: 32, height: 32)
                .background((event.type?.color ?? .gray).opacity(0.15))
                .cornerRadius(8)

            // Event details
            VStack(alignment: .leading, spacing: 2) {
                Text(event.description)
                    .font(.system(size: 13))
                    .foregroundColor(primaryText)

                HStack(spacing: 8) {
                    if let category = event.billCategory {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.system(size: 9))
                            Text(category.displayName)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(category.color)
                    }

                    Text(event.timeAgo)
                        .font(.system(size: 10))
                        .foregroundColor(secondaryText)
                }
            }

            Spacer()

            // Amount range indicator
            if let range = event.range {
                Text(range.shortName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.15))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }
}

// MARK: - Feed Filters View

struct FeedFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var feedService = MarketplaceFeedService.shared

    @State private var selectedEventTypes: Set<FeedEventType> = Set(FeedEventType.allCases)
    @State private var selectedCategories: Set<ReceiptBillCategory> = Set(ReceiptBillCategory.allCases)
    @State private var selectedAmountRanges: Set<AmountRange> = Set(AmountRange.allCases)

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationView {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Event types
                        filterSection(title: "Event Types") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(FeedEventType.allCases, id: \.self) { type in
                                    filterChip(
                                        label: type.displayName,
                                        icon: type.icon,
                                        color: type.color,
                                        isSelected: selectedEventTypes.contains(type)
                                    ) {
                                        toggleSelection(type, in: &selectedEventTypes)
                                    }
                                }
                            }
                        }

                        // Categories
                        filterSection(title: "Categories") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(ReceiptBillCategory.allCases) { category in
                                    filterChip(
                                        label: category.displayName,
                                        icon: category.icon,
                                        color: category.color,
                                        isSelected: selectedCategories.contains(category)
                                    ) {
                                        toggleSelection(category, in: &selectedCategories)
                                    }
                                }
                            }
                        }

                        // Amount ranges
                        filterSection(title: "Amount Ranges") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(AmountRange.allCases, id: \.self) { range in
                                    filterChip(
                                        label: range.displayName,
                                        icon: "dollarsign.circle",
                                        color: accent,
                                        isSelected: selectedAmountRanges.contains(range)
                                    ) {
                                        toggleSelection(range, in: &selectedAmountRanges)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Filter Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedEventTypes = Set(FeedEventType.allCases)
                        selectedCategories = Set(ReceiptBillCategory.allCases)
                        selectedAmountRanges = Set(AmountRange.allCases)
                    }
                    .foregroundColor(secondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                    .foregroundColor(accent)
                }
            }
        }
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(secondaryText)

            content()
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func filterChip(label: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .black : primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? color : cardBg.opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func toggleSelection<T: Hashable>(_ item: T, in set: inout Set<T>) {
        if set.contains(item) {
            set.remove(item)
        } else {
            set.insert(item)
        }
    }

    private func applyFilters() {
        let filter = FeedFilter(
            eventTypes: selectedEventTypes,
            categories: selectedCategories,
            amountRanges: selectedAmountRanges,
            regionOnly: false
        )

        Task {
            await feedService.loadFeed(with: filter)
        }
    }
}

// MARK: - Compact Feed Widget

/// A compact version of the feed for embedding in other views
struct CompactMarketplaceFeed: View {
    @StateObject private var feedService = MarketplaceFeedService.shared
    let maxItems: Int

    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    init(maxItems: Int = 5) {
        self.maxItems = maxItems
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Live Feed")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(primaryText)
                }

                Spacer()

                NavigationLink {
                    MarketplaceFeedView()
                } label: {
                    Text("See All")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
            }

            if feedService.feedEvents.isEmpty {
                Text("No recent activity")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(feedService.recentEvents(maxItems)) { event in
                        compactEventRow(event)
                    }
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func compactEventRow(_ event: MarketplaceFeedEvent) -> some View {
        HStack(spacing: 8) {
            Image(systemName: event.type?.icon ?? "circle")
                .font(.system(size: 12))
                .foregroundColor(event.type?.color ?? .gray)

            Text(event.description)
                .font(.system(size: 12))
                .foregroundColor(primaryText)
                .lineLimit(1)

            Spacer()

            Text(event.timeAgo)
                .font(.system(size: 10))
                .foregroundColor(secondaryText)
        }
    }
}

// MARK: - Preview

struct MarketplaceFeedView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
        MarketplaceFeedView()
        }
        .preferredColorScheme(.dark)
    }
}
