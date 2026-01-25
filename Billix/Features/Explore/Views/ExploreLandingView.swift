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
    @State private var isNavigating = false
    @State private var activeCardIndex = 0
    @Namespace private var namespace

    var body: some View {
        ZStack {
            // Full-screen carousel (always visible)
            AnimatedExploreCarousel(
                navigationDestination: $navigationDestination,
                activeCardIndex: $activeCardIndex,
                namespace: namespace
            )
            .ignoresSafeArea()
            .transaction { transaction in
                transaction.animation = nil
            }
            .onChange(of: navigationDestination) { oldValue, newValue in
                if newValue != nil {
                    print("🚀 Navigation destination changed to: \(String(describing: newValue))")
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isNavigating = true
                    }
                }
            }

            // Header overlaid on backdrop
            VStack {
                ExploreHeaderView(activeCardIndex: activeCardIndex)
                    .padding(.top, 120)
                Spacer()
            }
            .allowsHitTesting(false)

            // Overlay destination view when navigating
            if isNavigating, let destination = navigationDestination {
                let _ = print("🎯 Building view for: \(destination)")
                ZStack {
                    // Black background
                    Color.black
                        .ignoresSafeArea()

                    // Destination view content
                    destinationView(for: destination)
                }
                .scaleEffect(isNavigating ? 1.0 : 0.01, anchor: .bottom)
                .opacity(isNavigating ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isNavigating)
                .zIndex(1)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: ExploreDestination) -> some View {
        NavigationStack {
            switch destination {
            case .economyByAI:
                EconomyFeedView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    isNavigating = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    navigationDestination = nil
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Back")
                                        .font(.system(size: 17))
                                }
                                .foregroundColor(Color(hex: "#3B6CFF"))
                            }
                        }
                    }
                    .toolbarBackground(.hidden, for: .navigationBar)

            case .housingTrends:
                ExploreTabView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    isNavigating = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    navigationDestination = nil
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Back")
                                        .font(.system(size: 17))
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }

            case .bills:
                BillsExploreView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    isNavigating = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    navigationDestination = nil
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Back")
                                        .font(.system(size: 17))
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Header Component

struct ExploreHeaderView: View {
    let activeCardIndex: Int

    private var headerTitle: String {
        return "Explore"
    }

    private var headerSubtitle: String {
        switch activeCardIndex {
        case 2: // Economy by AI
            return "Economy News in your area"
        default: // Housing Trends (0) and Bills Explorer (1)
            return "See what your neighbors pay"
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(headerTitle)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

            Text(headerSubtitle)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

#Preview("Explore Landing") {
    ExploreLandingView()
}
