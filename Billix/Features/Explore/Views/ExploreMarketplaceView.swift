//
//  ExploreMarketplaceView.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  New root view for Explore marketplace (replaces carousel-based discovery)
//

import SwiftUI

/// Main marketplace view with unified header and Bills/Housing tabs
struct ExploreMarketplaceView: View {

    // MARK: - Tab Enum

    enum MarketplaceTab: String, CaseIterable {
        case housing = "Housing"
        case bills = "Bills"

        var icon: String {
            switch self {
            case .housing: return "house.fill"
            case .bills: return "bolt.fill"
            }
        }
    }

    // MARK: - Properties

    @StateObject private var locationManager = LocationManager()
    @StateObject private var housingViewModel = HousingSearchViewModel()
    @State private var selectedTab: MarketplaceTab = .bills

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Unified Sticky Header
                unifiedHeader
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: "F8F9FA"),
                                Color(hex: "E9ECEF")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Tab Content
                tabContent
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "E9ECEF"),
                        Color(hex: "F8F9FA")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
        }
    }

    // MARK: - Unified Header

    private var unifiedHeader: some View {
        VStack(spacing: 16) {
            // Segmented Control with improved styling
            Picker("Tab", selection: $selectedTab) {
                ForEach(MarketplaceTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .housing:
            HousingExploreView(
                locationManager: locationManager,
                viewModel: housingViewModel
            )

        case .bills:
            BillsExploreView()
        }
    }
}

// MARK: - Previews

#Preview("Explore Marketplace - Bills Tab") {
    ExploreMarketplaceView()
}

#Preview("Explore Marketplace - Housing Tab") {
    ExploreMarketplaceView()
}
