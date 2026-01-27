//
//  BillExplorerFeedView.swift
//  Billix
//
//  Main feed view for the Bill Explorer marketplace with individual bill listings
//

import SwiftUI

struct BillExplorerFeedView: View {
    @StateObject private var viewModel = BillExplorerViewModel()
    @State private var showFilterSheet = false

    var body: some View {
        ZStack {
            // Background
            Color(hex: "#F7F9F8")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Region tabs
                regionTabsSection

                // State chips (when region selected)
                if viewModel.hasRegionFilter {
                    stateChipsSection
                }

                // Bill type filter chips
                filterChipsSection

                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredListings.isEmpty {
                    emptyStateView
                } else {
                    listingsScrollView
                }
            }
        }
        .sheet(item: $viewModel.selectedListing) { listing in
            BillExplorerDetailSheet(
                listing: listing,
                userVote: viewModel.getUserVote(for: listing.id),
                isBookmarked: viewModel.isBookmarked(listing.id),
                questions: [], // TODO: Load from Supabase
                onUpvote: { viewModel.upvote(listing) },
                onDownvote: { viewModel.downvote(listing) },
                onBookmark: { viewModel.toggleBookmark(listing) },
                onAskQuestion: { _ in /* TODO: Implement */ },
                onGetSimilarRates: { /* TODO: Implement */ },
                onNegotiationScript: { /* TODO: Implement */ },
                onFindSwapMatch: { /* TODO: Implement */ }
            )
            .presentationDragIndicator(.visible)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bill Explorer")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Text("See what others are paying")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                // Bookmarks button
                Button(action: { viewModel.toggleBookmarkedOnly() }) {
                    ZStack {
                        Circle()
                            .fill(viewModel.showBookmarkedOnly ? Color(hex: "#5B8A6B") : Color.white)
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)

                        Image(systemName: viewModel.showBookmarkedOnly ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16))
                            .foregroundColor(viewModel.showBookmarkedOnly ? .white : Color(hex: "#5B8A6B"))
                    }
                }

                if viewModel.bookmarkedCount > 0 {
                    Text("\(viewModel.bookmarkedCount)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#5B8A6B"))
                        .cornerRadius(10)
                        .offset(x: -12, y: -12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Region Tabs Section

    private var regionTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(USRegion.allCases) { region in
                    RegionTabButton(
                        region: region,
                        isSelected: viewModel.selectedRegion == region,
                        action: { viewModel.selectRegion(region) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .background(Color.white)
    }

    // MARK: - State Chips Section

    private var stateChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All States" chip
                StateChipButton(
                    stateCode: nil,
                    stateName: "All \(viewModel.selectedRegion.rawValue)",
                    isSelected: viewModel.selectedState == nil,
                    action: { viewModel.selectState(nil) }
                )

                // Individual state chips
                ForEach(viewModel.availableStates, id: \.self) { stateCode in
                    StateChipButton(
                        stateCode: stateCode,
                        stateName: stateCode,
                        isSelected: viewModel.selectedState == stateCode,
                        action: { viewModel.selectState(stateCode) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(Color(hex: "#F7F9F8"))
    }

    // MARK: - Filter Chips Section

    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All filter chip
                BillExplorerFilterChip(
                    title: "All Types",
                    isSelected: viewModel.selectedBillType == nil,
                    action: { viewModel.selectedBillType = nil; viewModel.applyFilters() }
                )

                // Bill type chips
                ForEach(viewModel.billTypeFilters, id: \.self) { billType in
                    BillExplorerFilterChip(
                        title: billType.displayName,
                        icon: billType.icon,
                        iconColor: Color(hex: billType.color),
                        isSelected: viewModel.selectedBillType == billType,
                        action: { viewModel.selectBillType(billType) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Listings Scroll View

    private var listingsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredListings) { listing in
                    BillListingCard(
                        listing: listing,
                        userVote: viewModel.getUserVote(for: listing.id),
                        isBookmarked: viewModel.isBookmarked(listing.id),
                        onTap: { viewModel.showDetail(for: listing) },
                        onUpvote: { viewModel.upvote(listing) },
                        onDownvote: { viewModel.downvote(listing) },
                        onBookmark: { viewModel.toggleBookmark(listing) },
                        onMessage: { viewModel.showDetail(for: listing) }
                    )
                }

                // Bottom padding for tab bar
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()

            ProgressView()
                .scaleEffect(1.2)

            Text("Loading bills...")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#8B9A94"))

            Spacer()
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: viewModel.showBookmarkedOnly ? "bookmark.slash" : "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#C4CCC8"))

            Text(viewModel.showBookmarkedOnly ? "No Saved Bills" : "No Bills Found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "#2D3B35"))

            Text(viewModel.showBookmarkedOnly
                 ? "Save bills to compare them later"
                 : "Try adjusting your filters")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#8B9A94"))
                .multilineTextAlignment(.center)

            if viewModel.selectedBillType != nil || viewModel.showBookmarkedOnly {
                Button(action: { viewModel.clearFilters() }) {
                    Text("Clear Filters")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#5B8A6B"))
                        .cornerRadius(20)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Bill Explorer Filter Chip Component

struct BillExplorerFilterChip: View {
    let title: String
    var icon: String? = nil
    var iconColor: Color? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white : (iconColor ?? Color(hex: "#5B8A6B")))
                }

                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "#5A6B64"))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "#5B8A6B") : Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(isSelected ? 0.10 : 0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Region Tab Button Component

struct RegionTabButton: View {
    let region: USRegion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: region.icon)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : Color(hex: region.color))

                Text(region.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "#2D3B35"))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: region.color) : Color(hex: "#F7F9F8"))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color(hex: "#E5E9E7"), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - State Chip Button Component

struct StateChipButton: View {
    let stateCode: String?
    let stateName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(stateName)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "#5A6B64"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color(hex: "#5B8A6B") : Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    BillExplorerFeedView()
}
