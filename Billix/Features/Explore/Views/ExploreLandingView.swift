//
//  ExploreLandingView.swift
//  Billix
//
//  Created by Claude Code on 1/7/26.
//  Main landing screen for Explore tab with feature discovery
//

import SwiftUI

struct ExploreLandingView: View {
    @State private var navigationDestination: ExploreDestination?

    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen carousel (no other UI elements)
                AnimatedExploreCarousel(navigationDestination: $navigationDestination)
            }
            .ignoresSafeArea() // Allow content to extend to edges
            .navigationDestination(for: ExploreDestination.self) { destination in
                switch destination {
                case .economyByAI:
                    ComingSoonView(title: "Economy by AI")
                case .housingTrends:
                    ExploreTabView()
                case .bills:
                    BillsExploreView()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview("Explore Landing") {
    ExploreLandingView()
}
