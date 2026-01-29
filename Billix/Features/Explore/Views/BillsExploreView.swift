//
//  BillsExploreView.swift
//  Billix
//
//  Updated by Claude Code on 1/26/26.
//  Bill Explorer feed with bill listings and filters
//

import SwiftUI

struct BillsExploreView: View {
    @StateObject private var viewModel = BillExplorerViewModel()

    private let backgroundColor = Color(hex: "#F5F5F7")

    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Filter chips
                filterChipsRow
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredListings.isEmpty {
                    emptyStateView
                } else {
                    feedContent
                }
            }
        }
        .navigationTitle("Bill Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Filter Chips Row

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // "All" chip
                filterChip(
                    icon: "square.grid.2x2",
                    label: "All",
                    isSelected: viewModel.selectedExploreBillType == nil,
                    color: "#6B7280"
                ) {
                    viewModel.selectExploreBillType(nil)
                }

                // Bill type chips
                ForEach(viewModel.billTypes) { billType in
                    filterChip(
                        icon: billType.icon,
                        label: billType.rawValue,
                        isSelected: viewModel.selectedExploreBillType == billType,
                        color: billType.color
                    ) {
                        viewModel.selectExploreBillType(billType)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(icon: String, label: String, isSelected: Bool, color: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : Color(hex: color))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                Color(hex: color) :
                Color.white
            )
            .clipShape(Capsule())
            .shadow(
                color: isSelected ? Color(hex: color).opacity(0.3) : .black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Feed Content

    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredListings) { listing in
                    ExploreBillListingCard(
                        listing: listing,
                        onReactionTapped: { reaction in
                            viewModel.toggleReaction(for: listing.id, reaction: reaction)
                        },
                        onCommentTapped: {
                            // Phase 2: Comments
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.billixDarkTeal)

            Text("Loading bills...")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#D1D5DB"))

            VStack(spacing: 8) {
                Text("No bills found")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "#374151"))

                Text("Try selecting a different category")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#6B7280"))
            }

            if viewModel.selectedExploreBillType != nil {
                Button {
                    viewModel.selectExploreBillType(nil)
                } label: {
                    Text("Show All Bills")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.billixDarkTeal)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Bill Explorer") {
    NavigationStack {
        BillsExploreView()
    }
}
