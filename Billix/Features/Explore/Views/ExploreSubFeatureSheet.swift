//
//  ExploreSubFeatureSheet.swift
//  Billix
//
//  Bottom sheet matching HomePage clean design
//

import SwiftUI

struct ExploreSubFeatureSheet: View {
    let feature: ExploreFeatureCard
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationDestination: CarouselDestination?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                ExploreTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header section
                        headerSection
                            .padding(.top, 8)

                        // Sub-feature cards
                        VStack(spacing: 12) {
                            ForEach(feature.subFeatures) { subFeature in
                                SubFeatureCard(
                                    subFeature: subFeature,
                                    onTap: {
                                        navigationDestination = subFeature.destination
                                        dismiss()
                                    }
                                )
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, ExploreTheme.horizontalPadding)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                ExploreTheme.secondaryText.opacity(0.5),
                                ExploreTheme.secondaryText.opacity(0.1)
                            )
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color(hex: "#F5F7F6"))
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(feature.accentColor.opacity(0.1))
                    .frame(width: 64, height: 64)

                Image(systemName: feature.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(feature.accentColor)
            }

            // Title & Category
            VStack(spacing: 8) {
                Text(feature.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ExploreTheme.primaryText)

                Text(feature.category.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(feature.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(feature.accentColor.opacity(0.1))
                    )
            }

            // Description
            Text(feature.description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ExploreTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 16)
        }
    }
}

// MARK: - Sub-Feature Card

struct SubFeatureCard: View {
    let subFeature: ExploreSubFeature
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(subFeature.iconColor.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: subFeature.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(subFeature.iconColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(subFeature.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ExploreTheme.primaryText)

                    Text(subFeature.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ExploreTheme.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ExploreTheme.secondaryText.opacity(0.5))
            }
            .padding(14)
            .background(ExploreTheme.cardBackground)
            .cornerRadius(14)
            .shadow(color: ExploreTheme.shadowColor, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(SubFeatureButtonStyle())
    }
}

// MARK: - Button Style

private struct SubFeatureButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            ExploreSubFeatureSheet(
                feature: ExploreFeatureCard.allFeatures[0],
                navigationDestination: .constant(nil)
            )
        }
}
