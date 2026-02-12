//
//  ExploreCarouselCard.swift
//  Billix
//
//  Carousel card component for the Explore page
//

import SwiftUI

// MARK: - Explore Carousel Card

struct ExploreCarouselCard: View {
    let feature: ExploreFeatureCard
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon and category
                HStack {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: feature.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)

                        Image(systemName: feature.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Category badge
                    Text(feature.category.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(feature.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(feature.accentColor.opacity(0.12))
                        )
                }

                // Title
                Text(feature.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ExploreTheme.primaryText)
                    .lineLimit(2)

                // Description
                Text(feature.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ExploreTheme.secondaryText)
                    .lineSpacing(4)
                    .lineLimit(2)

                Spacer()

                // Sub-features preview
                HStack(spacing: 8) {
                    ForEach(feature.subFeatures.prefix(3)) { subFeature in
                        HStack(spacing: 4) {
                            Image(systemName: subFeature.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(subFeature.title.components(separatedBy: " ").first ?? "")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(ExploreTheme.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#F3F4F6"))
                        )
                    }
                }

                // Explore button
                HStack {
                    Text("Explore")
                        .font(.system(size: 14, weight: .semibold))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: feature.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ExploreTheme.cardBackground)
            .cornerRadius(ExploreTheme.cornerRadius)
            .shadow(
                color: isActive ? feature.accentColor.opacity(0.2) : ExploreTheme.shadowColor,
                radius: isActive ? 16 : 10,
                x: 0,
                y: isActive ? 8 : 4
            )
        }
        .buttonStyle(CarouselCardButtonStyle())
    }
}

// MARK: - Button Style

private struct CarouselCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Explore Carousel View

struct ExploreCarouselView: View {
    @Binding var selectedFeature: ExploreFeatureCard?
    @Binding var showFeatureSheet: Bool
    @State private var currentIndex: Int = 0

    private let features = ExploreFeatureCard.allFeatures

    var body: some View {
        VStack(spacing: 16) {
            // Carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                    ExploreCarouselCard(
                        feature: feature,
                        isActive: currentIndex == index,
                        onTap: {
                            selectedFeature = feature
                            showFeatureSheet = true
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 320)

            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<features.count, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? features[index].accentColor : Color(hex: "#D1D5DB"))
                        .frame(width: currentIndex == index ? 8 : 6, height: currentIndex == index ? 8 : 6)
                        .animation(.spring(response: 0.3), value: currentIndex)
                }
            }
        }
    }
}

// MARK: - Preview

struct ExploreCarouselCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        ExploreTheme.background.ignoresSafeArea()
        
        ExploreCarouselView(
        selectedFeature: .constant(nil),
        showFeatureSheet: .constant(false)
        )
        }
    }
}
