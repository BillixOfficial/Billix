//
//  ExploreView.swift
//  Billix
//
//  Explore page with carousel-based feature discovery
//

import SwiftUI

struct ExploreView: View {
    @State private var selectedFeature: ExploreFeatureCard? = nil
    @State private var showFeatureSheet: Bool = false
    @State private var navigationDestination: CarouselDestination? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                ExploreTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                            .padding(.horizontal, ExploreTheme.horizontalPadding)
                            .padding(.top, 8)

                        // Feature Carousel
                        ExploreCarouselView(
                            selectedFeature: $selectedFeature,
                            showFeatureSheet: $showFeatureSheet
                        )

                        // Quick Access Section
                        quickAccessSection
                            .padding(.horizontal, ExploreTheme.horizontalPadding)

                        // Bottom padding for tab bar
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Explore")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(ExploreTheme.primaryText)
                }
            }
            .sheet(isPresented: $showFeatureSheet) {
                if let feature = selectedFeature {
                    ExploreSubFeatureSheet(
                        feature: feature,
                        navigationDestination: $navigationDestination
                    )
                }
            }
            .navigationDestination(item: $navigationDestination) { destination in
                destinationView(for: destination)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Discover Tools")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ExploreTheme.primaryText)

            Text("Explore features to save money and understand your bills")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(ExploreTheme.secondaryText)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Quick Access Section

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ExploreTheme.primaryText)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                QuickAccessCard(
                    title: "Outage Bot",
                    icon: "bolt.trianglebadge.exclamationmark.fill",
                    color: Color(hex: "#F59E0B"),
                    destination: .outageBot
                ) {
                    navigationDestination = .outageBot
                }

                QuickAccessCard(
                    title: "Bill Heatmap",
                    icon: "map.fill",
                    color: Color(hex: "#10B981"),
                    destination: .billHeatmap
                ) {
                    navigationDestination = .billHeatmap
                }

                QuickAccessCard(
                    title: "Marketplace",
                    icon: "storefront.fill",
                    color: Color(hex: "#6366F1"),
                    destination: .marketplace
                ) {
                    navigationDestination = .marketplace
                }

                QuickAccessCard(
                    title: "Gouge Index",
                    icon: "exclamationmark.triangle.fill",
                    color: Color(hex: "#EF4444"),
                    destination: .gougeIndex
                ) {
                    navigationDestination = .gougeIndex
                }
            }
        }
    }

    // MARK: - Destination View

    @ViewBuilder
    private func destinationView(for destination: CarouselDestination) -> some View {
        switch destination {
        case .recessionSimulator:
            RecessionSimulatorDestinationView()
        case .makeMeMove:
            MakeMeMoveDestinationView()
        case .outageBot:
            OutageBotView()
        case .billHeatmap:
            BillHeatmapDestinationView()
        case .gougeIndex:
            GougeIndexDestinationView()
        case .marketplace:
            MarketplaceView()
        case .clusters:
            ClustersDestinationView()
        case .expertScripts:
            ExpertScriptsDestinationView()
        case .billAnalysis:
            BillAnalysisDestinationView()
        case .savingsTracker:
            SavingsTrackerDestinationView()
        }
    }
}

// MARK: - Quick Access Card

private struct QuickAccessCard: View {
    let title: String
    let icon: String
    let color: Color
    let destination: CarouselDestination
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ExploreTheme.primaryText)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ExploreTheme.secondaryText.opacity(0.5))
            }
            .padding(14)
            .background(ExploreTheme.cardBackground)
            .cornerRadius(14)
            .shadow(color: ExploreTheme.shadowColor, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(QuickAccessButtonStyle())
    }
}

private struct QuickAccessButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Placeholder Destination Views

private struct RecessionSimulatorDestinationView: View {
    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        ScrollView {
            RecessionSimulatorView(viewModel: viewModel)
                .padding()
        }
        .background(ExploreTheme.background)
        .navigationTitle("Recession Simulator")
    }
}

private struct MakeMeMoveDestinationView: View {
    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        ScrollView {
            MakeMeMoveView(viewModel: viewModel)
                .padding()
        }
        .background(ExploreTheme.background)
        .navigationTitle("Make Me Move")
    }
}

private struct BillHeatmapDestinationView: View {
    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        BillHeatmapView(viewModel: viewModel)
            .navigationTitle("Bill Heatmap")
    }
}

private struct GougeIndexDestinationView: View {
    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        ScrollView {
            GougeIndexView(viewModel: viewModel)
                .padding()
        }
        .background(ExploreTheme.background)
        .navigationTitle("Gouge Index")
    }
}

private struct ClustersDestinationView: View {
    var body: some View {
        MarketplaceView()
            .navigationTitle("Clusters")
    }
}

private struct ExpertScriptsDestinationView: View {
    var body: some View {
        MarketplaceView()
            .navigationTitle("Expert Scripts")
    }
}

private struct BillAnalysisDestinationView: View {
    var body: some View {
        VStack {
            Text("Bill Analysis")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ExploreTheme.background)
        .navigationTitle("Bill Analysis")
    }
}

private struct SavingsTrackerDestinationView: View {
    var body: some View {
        VStack {
            Text("Savings Tracker")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ExploreTheme.background)
        .navigationTitle("Savings Tracker")
    }
}

// MARK: - Preview

#Preview {
    ExploreView()
}
