//
//  NeighborsPaySection.swift
//  Billix
//
//  Created by Claude Code on 1/7/26.
//  See What Your Neighbors Pay section with carousel
//

import SwiftUI

// MARK: - Card Data Model

private enum NeighborPayCard: String, CaseIterable, Identifiable {
    case housingTrends = "Housing Trends"
    case bills = "Bills"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .housingTrends: return "Explore rental markets"
        case .bills: return "Compare bill costs"
        }
    }

    var imageName: String {
        switch self {
        case .housingTrends: return "NEW_Home_Placeholder"
        case .bills: return "NEWEST_BILL_Placeholder"
        }
    }
}

// MARK: - Card View

private struct NeighborPayCardView: View {
    let card: NeighborPayCard

    var body: some View {
        VStack(spacing: 0) {
            // Image area
            Image(card.imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .clipped()

            // Content section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.rawValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Text(card.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Main Section

struct NeighborsPaySection: View {
    @State private var selectedCard: NeighborPayCard = .housingTrends
    @State private var timer: Timer?

    init() {
        // Customize page control colors for better visibility
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color(hex: "#5B8A6B"))
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color(hex: "#5B8A6B")).withAlphaComponent(0.3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header - left aligned
            Text("See What Your Neighbors Pay")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "#2D3B35"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            // Carousel with page indicators
            TabView(selection: $selectedCard) {
                ForEach(NeighborPayCard.allCases) { card in
                    if card == .housingTrends {
                        NavigationLink(destination: ExploreTabView()) {
                            NeighborPayCardView(card: card)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .tag(card)
                    } else {
                        // Placeholder - no navigation yet
                        NeighborPayCardView(card: card)
                            .tag(card)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .frame(height: 260)
            .padding(.horizontal, 20)
        }
        .onAppear {
            startAutoRotation()
        }
        .onDisappear {
            stopAutoRotation()
        }
    }

    private func startAutoRotation() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                let allCards = NeighborPayCard.allCases
                if let currentIndex = allCards.firstIndex(of: selectedCard) {
                    let nextIndex = (currentIndex + 1) % allCards.count
                    selectedCard = allCards[nextIndex]
                }
            }
        }
    }

    private func stopAutoRotation() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview("Neighbors Pay Section") {
    NavigationStack {
        NeighborsPaySection()
            .background(Color.billixCreamBeige.opacity(0.3))
    }
}
