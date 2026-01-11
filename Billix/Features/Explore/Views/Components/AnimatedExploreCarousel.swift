//
//  AnimatedExploreCarousel.swift
//  Billix
//
//  Created by Claude Code on 1/10/26.
//  Full-screen animated carousel with iOS 17+ visualEffect and safeAreaPadding
//

import SwiftUI

struct AnimatedExploreCarousel: View {
    @Binding var navigationDestination: ExploreDestination?
    @Binding var activeCardIndex: Int
    let namespace: Namespace.ID
    @State private var currentCardID: Int? = 150 // Start in middle of large array
    @State private var topPaddingPercent: CGFloat = 0.25 // Adjustable top padding (25%)
    @State private var cardHeightPercent: CGFloat = 0.77 // Adjustable card height (77%)
    @State private var cardWidthPercent: CGFloat = 0.70 // Adjustable card width (70%)
    @State private var buttonBottomPadding: CGFloat = 138 // Black button bottom padding
    @State private var placeholderHeightPercent: CGFloat = 0.46 // Placeholder height as % of card (46%)

    private let baseCards = AnimatedExploreCardModel.mockCards
    private var allCards: [AnimatedExploreCardModel] {
        // Large repetition for "infinite" scroll (3 × 100 = 300 cards)
        // User starts at index 150, can scroll 150 cards in either direction
        Array(repeating: baseCards, count: 100).flatMap { $0 }
    }
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private var cardWidth: CGFloat {
        screenWidth * cardWidthPercent // Adjustable card width
    }
    private var cardHeight: CGFloat {
        screenHeight * cardHeightPercent // Adjustable card height
    }
    private var backdropHeight: CGFloat {
        screenHeight * 0.65 // 65% of screen height
    }
    private var cardSpacing: CGFloat {
        screenWidth * 0.05 // 5% spacing for increased peek effect
    }

    var body: some View {
        ZStack {
            // Full-screen backdrop layer with wipe animation
            backdropLayerWithWipe
                .frame(height: backdropHeight)
                .frame(maxHeight: .infinity, alignment: .top)

            // Scrollable cards layer - extends to navbar
            scrollableCardsLayer
                .padding(.top, screenHeight * topPaddingPercent) // Adjustable top padding
        }
        .ignoresSafeArea()
        .onChange(of: currentCardID) { oldValue, newValue in
            if let newValue = newValue {
                activeCardIndex = newValue % baseCards.count
            }
        }
    }

    // MARK: - Backdrop Layer with Wipe Animation

    private var backdropLayerWithWipe: some View {
        // Map large array index (0-299) to base card index (0-2)
        let activeIndex = (currentCardID ?? 150) % baseCards.count

        return GeometryReader { _ in
            ZStack {
                // Background images (if available)
                ForEach(Array(baseCards.enumerated()), id: \.element.id) { index, card in
                    if let imageName = card.imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 15)
                            .opacity(index == activeIndex ? 0.7 : 0)
                            .animation(.easeInOut(duration: 0.3), value: activeIndex)
                    }
                }

                // Gradient overlays
                ForEach(Array(baseCards.enumerated()), id: \.element.id) { index, card in
                    LinearGradient(
                        colors: card.backdropGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(index == activeIndex ? 0.25 : 0)
                    .animation(.easeInOut(duration: 0.3), value: activeIndex)
                }

                // Bottom fade gradient
                LinearGradient(
                    colors: [Color.clear, Color.white],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 150)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Scrollable Cards Layer

    private var scrollableCardsLayer: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: cardSpacing) {
                ForEach(Array(allCards.enumerated()), id: \.offset) { index, card in
                    cardView(for: index)
                        .containerRelativeFrame(.horizontal)
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $currentCardID)
        .safeAreaPadding(.horizontal, (screenWidth - cardWidth) / 2)
    }

    // MARK: - Individual Card View

    private func cardView(for index: Int) -> some View {
        let card = baseCards[index % baseCards.count]  // Map 0-299 → 0-2

        return Button {
            // Only navigate if this is the centered card
            if currentCardID == index {
                print("🔘 Card tapped: \(card.title), destination: \(card.destination)")

                // Haptic feedback - feels tactile
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()

                // Delay navigation to show button animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    navigationDestination = card.destination
                }
            } else {
                print("⚠️ Card tapped but not centered. Current: \(currentCardID ?? -1), Tapped: \(index)")
            }
        } label: {
            AnimatedExploreCard(
                card: card,
                cardWidth: cardWidth,
                cardHeight: cardHeight,
                translateY: 0,  // No offset on card itself
                buttonBottomPadding: buttonBottomPadding,
                placeholderHeightPercent: placeholderHeightPercent,
                namespace: namespace
            )
            .visualEffect { content, geometryProxy in
                content
                    .offset(y: calculateElevation(for: geometryProxy))
                    .opacity(calculateOpacity(for: geometryProxy))
            }
            .padding(.top, 80) // Extra padding to show rounded corners
            .padding(.bottom, -80) // Negative padding to keep position
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Helper Functions

    // Calculate elevation based on distance from viewport center
    private func calculateElevation(for proxy: GeometryProxy) -> CGFloat {
        // Get card's center X in scroll view space
        let cardCenterX = proxy.frame(in: .scrollView).midX

        // Get viewport center X
        let viewportCenterX = proxy.bounds(of: .scrollView)?.midX ?? 0

        // Distance from card center to viewport center
        let distanceFromCenter = abs(cardCenterX - viewportCenterX)

        // Normalize: 0 = center, 1 = one card width away
        let normalizedDistance = min(distanceFromCenter / cardWidth, 1.0)

        // Interpolate with ease-out curve
        let elevationRange: CGFloat = 50
        let easedDistance = 1 - pow(1 - normalizedDistance, 2)  // Ease-out quadratic
        return -elevationRange * (1 - easedDistance)
    }

    // Calculate opacity based on distance from viewport center
    private func calculateOpacity(for proxy: GeometryProxy) -> CGFloat {
        // Get card's center X in scroll view space
        let cardCenterX = proxy.frame(in: .scrollView).midX

        // Get viewport center X
        let viewportCenterX = proxy.bounds(of: .scrollView)?.midX ?? 0

        // Distance from card center to viewport center
        let distanceFromCenter = abs(cardCenterX - viewportCenterX)

        // Normalize: 0 = center, 1 = one card width away
        let normalizedDistance = min(distanceFromCenter / cardWidth, 1.0)

        // Interpolate opacity: 1.0 at center, 0.4 at edges
        let minOpacity: CGFloat = 0.4
        let maxOpacity: CGFloat = 1.0
        return maxOpacity - (normalizedDistance * (maxOpacity - minOpacity))
    }

    // MARK: - Page Indicators

    private var pageIndicators: some View {
        let activeIndex = (currentCardID ?? 150) % baseCards.count

        return HStack(spacing: 8) {
            ForEach(0..<baseCards.count, id: \.self) { index in
                Circle()
                    .fill(activeIndex == index ? baseCards[index].accentColor : Color.gray.opacity(0.3))
                    .frame(
                        width: activeIndex == index ? 10 : 8,
                        height: activeIndex == index ? 10 : 8
                    )
                    .animation(.spring(response: 0.3), value: activeIndex)
            }
        }
    }

}

// MARK: - Custom Button Style

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview("Animated Carousel") {
    @Previewable @State var destination: ExploreDestination?
    @Previewable @State var activeIndex = 0
    @Previewable @Namespace var namespace

    VStack {
        AnimatedExploreCarousel(
            navigationDestination: $destination,
            activeCardIndex: $activeIndex,
            namespace: namespace
        )

        if let dest = destination {
            Text("Selected: \(String(describing: dest))")
                .padding()
        }
    }
    .background(Color(hex: "#90EE90").opacity(0.4))
}
