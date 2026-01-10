//
//  AnimatedExploreCarousel.swift
//  Billix
//
//  Created by Claude Code on 1/10/26.
//  Full-screen animated carousel inspired by React Native movie carousel
//

import SwiftUI

struct AnimatedExploreCarousel: View {
    @State private var scrollOffset: CGFloat = 0
    @Binding var navigationDestination: ExploreDestination?
    @State private var topPaddingPercent: CGFloat = 0.24 // Adjustable top padding (24%)
    @State private var cardHeightPercent: CGFloat = 0.64 // Adjustable card height (64%)
    @State private var cardWidthPercent: CGFloat = 0.70 // Adjustable card width (70%)

    private let cards = AnimatedExploreCardModel.mockCards
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

    var body: some View {
        ZStack {
            // Full-screen backdrop layer with wipe animation
            backdropLayerWithWipe
                .frame(height: backdropHeight)
                .frame(maxHeight: .infinity, alignment: .top)

            // Scrollable cards layer - extends to navbar
            scrollableCardsLayer
                .padding(.top, screenHeight * topPaddingPercent) // Adjustable top padding

            // Debug controls
            VStack {
                HStack(spacing: 15) {
                    VStack {
                        Text("Top: \(Int(topPaddingPercent * 100))%")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)

                        HStack {
                            Button("-") {
                                topPaddingPercent = max(0.1, topPaddingPercent - 0.01)
                            }
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 35, height: 35)
                            .background(Color.red)
                            .cornerRadius(8)

                            Button("+") {
                                topPaddingPercent = min(0.6, topPaddingPercent + 0.01)
                            }
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 35, height: 35)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                    }

                    VStack {
                        Text("Height: \(Int(cardHeightPercent * 100))%")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)

                        HStack {
                            Button("-") {
                                cardHeightPercent = max(0.4, cardHeightPercent - 0.01)
                            }
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 35, height: 35)
                            .background(Color.red)
                            .cornerRadius(8)

                            Button("+") {
                                cardHeightPercent = min(0.9, cardHeightPercent + 0.01)
                            }
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 35, height: 35)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                    }

                    VStack {
                        Text("Width: \(Int(cardWidthPercent * 100))%")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)

                        HStack {
                            Button("-") {
                                cardWidthPercent = max(0.5, cardWidthPercent - 0.01)
                            }
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 35, height: 35)
                            .background(Color.red)
                            .cornerRadius(8)

                            Button("+") {
                                cardWidthPercent = min(1.0, cardWidthPercent + 0.01)
                            }
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 35, height: 35)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 60)

                Spacer()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Backdrop Layer with Wipe Animation

    private var backdropLayerWithWipe: some View {
        GeometryReader { _ in
            ZStack(alignment: .leading) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    LinearGradient(
                        colors: card.backdropGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: getBackdropWidth(for: index))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipped()
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
        ScrollViewReader { _ in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    // Left spacer for centering first card
                    Spacer()
                        .frame(width: (screenWidth - cardWidth) / 2)

                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        GeometryReader { geo in
                            let offset = geo.frame(in: .global).minX
                            let centerOffset = (screenWidth - cardWidth) / 2
                            let normalizedOffset = (offset - centerOffset) / cardWidth

                            Button {
                                navigationDestination = card.destination
                            } label: {
                                AnimatedExploreCard(
                                    card: card,
                                    cardWidth: cardWidth,
                                    cardHeight: cardHeight,
                                    translateY: getTranslateY(for: normalizedOffset)
                                )
                                .padding(.top, 80) // Extra padding to show rounded corners
                                .padding(.bottom, -80) // Negative padding to keep position
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onChange(of: offset) { _, _ in
                                // Track scroll position for backdrop animation
                                if abs(normalizedOffset) < 0.5 {
                                    scrollOffset = CGFloat(index) * cardWidth
                                }
                            }
                        }
                        .frame(width: cardWidth)
                    }

                    // Right spacer for centering last card
                    Spacer()
                        .frame(width: (screenWidth - cardWidth) / 2)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
        }
    }

    // MARK: - Page Indicators

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            let currentIndex = Int(round(scrollOffset / cardWidth))
            ForEach(0..<cards.count, id: \.self) { index in
                Circle()
                    .fill(currentIndex == index ? cards[index].accentColor : Color.gray.opacity(0.3))
                    .frame(
                        width: currentIndex == index ? 10 : 8,
                        height: currentIndex == index ? 10 : 8
                    )
                    .animation(.spring(response: 0.3), value: currentIndex)
            }
        }
    }

    // MARK: - Helper Functions

    /// Calculate backdrop width for sliding wipe effect
    private func getBackdropWidth(for index: Int) -> CGFloat {
        let currentCardIndex = Int(round(scrollOffset / cardWidth))

        if index < currentCardIndex {
            return screenWidth // Previous cards full width
        } else if index == currentCardIndex {
            return screenWidth // Current card full width
        } else if index == currentCardIndex + 1 {
            // Next card - animate width based on scroll progress
            let progress = (scrollOffset / cardWidth) - CGFloat(currentCardIndex)
            return screenWidth * progress
        } else {
            return 0 // Future cards hidden
        }
    }

    /// Calculate vertical bounce offset for cards
    private func getTranslateY(for normalizedOffset: CGFloat) -> CGFloat {
        // Center card: 0 offset → translateY = -50 (raised)
        // Side cards: ±1 offset → translateY = 0 (lowered)
        let absOffset = abs(normalizedOffset)
        return (absOffset * 50) - 50
    }
}

#Preview("Animated Carousel") {
    struct PreviewWrapper: View {
        @State private var destination: ExploreDestination?

        var body: some View {
            VStack {
                AnimatedExploreCarousel(navigationDestination: $destination)

                if let dest = destination {
                    Text("Selected: \(String(describing: dest))")
                        .padding()
                }
            }
            .background(Color(hex: "#90EE90").opacity(0.4))
        }
    }

    return PreviewWrapper()
}
