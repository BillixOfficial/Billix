//
//  ExploreLandingView.swift
//  Billix
//
//  Created by Claude Code on 1/7/26.
//  Main landing screen for Explore tab with feature discovery
//

import SwiftUI

struct ExploreLandingView: View {
    @State private var searchQuery: String = ""
    @State private var showVoiceSearch: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Sunrise gradient background
                LinearGradient(
                    colors: [Color(hex: "#FFD700").opacity(0.4), Color.white],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                // Optional decorative cloud in top right
                Image(systemName: "cloud.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.3))
                    .offset(x: 100, y: -250)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Search Bar
                        ExploreSearchBar(
                            searchQuery: $searchQuery,
                            onVoiceSearch: { showVoiceSearch = true }
                        )
                        .padding(.horizontal, 20)

                        // Economy by AI Section
                        EconomyAISection(iconSize: 150)

                        // See What Your Neighbors Pay Section
                        NeighborsPaySection()

                        Spacer(minLength: 100) // Bottom tab bar padding
                    }
                    .padding(.top, 12)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var headerSection: some View {
        Text("Ready to explore\nthe cost of living")
            .font(.system(size: 32, weight: .bold, design: .default))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 20)
    }
}

#Preview("Explore Landing") {
    ExploreLandingView()
}
