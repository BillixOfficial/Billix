import SwiftUI

/// Main Bills Marketplace view with grid, filters, and stats
struct BillsExploreView: View {
    @StateObject private var viewModel = BillsExploreViewModel()
    @State private var showScrollToTop = false

    // Grid columns (2 columns for iPhone)
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            // Background
            Color.billixCreamBeige.opacity(0.3)
                .ignoresSafeArea()

            // Main content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                        // Top anchor for scroll-to-top
                        Color.clear
                            .frame(height: 1)
                            .id("top")

                        // Stats Header - only show when ZIP is entered
                        if viewModel.selectedZipPrefix != nil {
                            Section {
                                BillsStatsHeaderView(
                                    totalProviders: viewModel.totalProviders,
                                    averageSavings: viewModel.averageSavings,
                                    totalSamples: viewModel.totalSamples
                                )
                                .padding(.horizontal)
                                .padding(.top, 16)
                            }
                        }

                        // Filter Bar (sticky)
                        Section {
                            EmptyView()
                        } header: {
                            VStack(spacing: 0) {
                                BillsFilterBarView(
                                    selectedCategory: $viewModel.selectedCategory,
                                    selectedZipPrefix: $viewModel.selectedZipPrefix,
                                    selectedSort: $viewModel.selectedSort,
                                    categories: viewModel.getCategories(),
                                    onApplyFilters: {
                                        await viewModel.loadInitialData()
                                    },
                                    onClearFilters: {
                                        await viewModel.clearFilters()
                                    }
                                )
                                .padding(.vertical, 12)
                                .background(Color.billixCreamBeige.opacity(0.95))
                            }
                        }

                        // Content
                        if viewModel.isLoading {
                            loadingView
                        } else if let error = viewModel.error {
                            errorView(error)
                        } else if viewModel.hasData {
                            gridContent
                        } else if viewModel.selectedZipPrefix == nil {
                            zipPromptView
                        } else {
                            emptyStateView
                        }
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .overlay(alignment: .bottomTrailing) {
                    // Scroll to top button
                    if showScrollToTop {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(Color.billixMoneyGreen)
                                        .shadow(
                                            color: Color.billixNavyBlue.opacity(0.3),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                        }
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }

    // MARK: - Grid Content

    private var gridContent: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.filteredData) { data in
                BillMarketplaceCard(data: data)
                    .onTapGesture {
                        // TODO: Show detail sheet in Phase 3
                        print("Tapped: \(data.provider?.name ?? "Unknown")")
                    }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.billixMoneyGreen)

            Text("Loading marketplace...")
                .font(.subheadline)
                .foregroundColor(.billixDarkTeal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Error View

    private func errorView(_ error: NetworkError) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.billixGold)

            Text("Oops!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.billixNavyBlue)

            Text(error.userFriendlyMessage)
                .font(.body)
                .foregroundColor(.billixDarkTeal)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if error.shouldRetry {
                Button {
                    Task {
                        await viewModel.loadInitialData()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.billixMoneyGreen)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(.billixDarkTeal.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Bills Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.billixNavyBlue)

                Text("Try adjusting your filters or check back later")
                    .font(.body)
                    .foregroundColor(.billixDarkTeal)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await viewModel.clearFilters()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Clear Filters")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.billixMoneyGreen)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }

    // MARK: - ZIP Prompt View

    private var zipPromptView: some View {
        VStack(spacing: 32) {
            // Icon
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.billixMoneyGreen)

            VStack(spacing: 12) {
                Text("Enter Your ZIP Code")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.billixNavyBlue)

                Text("Discover and compare bills in your area.\nTap the ZIP Code filter above to get started.")
                    .font(.body)
                    .foregroundColor(.billixDarkTeal)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Visual hint pointing to filter bar
            VStack(spacing: 8) {
                Image(systemName: "arrow.up")
                    .font(.title2)
                    .foregroundColor(.billixGold)

                Text("Tap 'ZIP Code' above")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.billixGold)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview

#Preview {
    BillsExploreView()
}
