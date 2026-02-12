//
//  SeasonCard.swift
//  Billix
//
//  Created by Claude Code
//  Card component for displaying season information in selection view
//

import SwiftUI

struct SeasonCard: View {
    let season: Season
    let progress: (completed: Int, total: Int)
    let isLocked: Bool
    let onTap: () -> Void

    @State private var animatedProgress: CGFloat = 0
    @State private var glowScale: CGFloat = 0.9
    @State private var rotation: Double = 0

    private var progressPercent: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.completed) / Double(progress.total)
    }

    private var gradientColors: [Color] {
        season.gradientColors
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Top section with gradient and animated icon
                ZStack(alignment: .topTrailing) {
                    // Gradient background
                    LinearGradient(
                        colors: isLocked ? [.gray.opacity(0.3), .gray.opacity(0.5)] : gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 140)

                    // Lock icon overlay
                    if isLocked {
                        VStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            Text("Coming Soon")
                                .font(.seasonFootnote)
                                .foregroundColor(.white.opacity(0.9))
                            Spacer()
                        }
                    } else {
                        // Animated season icon with glow
                        VStack {
                            Spacer()
                            ZStack {
                                // Animated glow background
                                Circle()
                                    .fill(RadialGradient(
                                        colors: [gradientColors[0].opacity(0.6), .clear],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 40
                                    ))
                                    .scaleEffect(glowScale)
                                    .blur(radius: 20)

                                // Rotating ring
                                Circle()
                                    .stroke(lineWidth: 3)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .rotationEffect(.degrees(rotation))
                                    .frame(width: 70, height: 70)

                                // Main icon
                                Image(systemName: season.iconName)
                                    .font(.system(size: 50, weight: .medium))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                            }
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true)
                                ) {
                                    glowScale = 1.1
                                }

                                withAnimation(
                                    .linear(duration: 8.0)
                                    .repeatForever(autoreverses: false)
                                ) {
                                    rotation = 360
                                }
                            }
                            Spacer()
                        }
                    }

                    // Season number badge
                    Text("Season \(season.seasonNumber)")
                        .font(.seasonFootnote)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                        .padding([.top, .trailing], Spacing.md)
                }
                .frame(height: 140)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 20
                    )
                )

                // Bottom section with info
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Title
                    Text(season.title)
                        .font(.seasonCardTitle)
                        .foregroundColor(isLocked ? .gray : .billixDarkGreen)
                        .lineLimit(1)

                    // Description
                    if let description = season.description {
                        Text(description)
                            .font(.seasonCaption)
                            .foregroundColor(isLocked ? .gray.opacity(0.7) : .billixMediumGreen)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Progress bar and info
                    if !isLocked {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            // Animated progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.progressNotStarted)
                                        .frame(height: 6)

                                    // Animated gradient fill
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: gradientColors,
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * animatedProgress, height: 6)
                                }
                            }
                            .frame(height: 6)
                            .onAppear {
                                withAnimation(
                                    .spring(response: 1.0, dampingFraction: 0.75)
                                    .delay(0.3)
                                ) {
                                    animatedProgress = progressPercent
                                }
                            }

                            // Progress text
                            HStack {
                                Text("\(progress.completed)/\(progress.total) locations")
                                    .font(.seasonFootnote)
                                    .foregroundColor(.billixMediumGreen)

                                Spacer()

                                if progress.completed == progress.total && progress.total > 0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.progressComplete)

                                        Text("Complete")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.progressComplete)
                                    }
                                } else {
                                    Text("\(Int(progressPercent * 100))%")
                                        .font(.seasonFootnote)
                                        .foregroundColor(.billixDarkGreen)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.lg)
                .background(Color.white)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: isLocked ?
                                        [.gray.opacity(0.3), .gray.opacity(0.1)] :
                                        [gradientColors[0].opacity(0.6), gradientColors[1].opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(0.03), radius: 1, y: 1)      // Ambient
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)      // Medium
                    .shadow(color: .black.opacity(0.12), radius: 24, y: 12)    // Focused
            )
        }
        .buttonStyle(PlainButtonStyle())
        .interactiveScale()
        .disabled(isLocked)
    }
}

// MARK: - Preview

struct SeasonCard_Season_Card___Unlocked_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.xl) {
        SeasonCard(
        season: Season(
        id: UUID(),
        seasonNumber: 1,
        title: "USA Roadtrip",
        description: "Explore grocery prices across America",
        isReleased: true,
        releaseDate: nil,
        totalParts: 2,
        iconName: "flag.fill",
        createdAt: Date()
        ),
        progress: (completed: 12, total: 20),
        isLocked: false,
        onTap: {}
        )
        .padding(.horizontal, Spacing.xl)
        
        SeasonCard(
        season: Season(
        id: UUID(),
        seasonNumber: 2,
        title: "Global",
        description: "Price adventure around the world",
        isReleased: false,
        releaseDate: nil,
        totalParts: 3,
        iconName: "globe",
        createdAt: Date()
        ),
        progress: (completed: 0, total: 30),
        isLocked: true,
        onTap: {}
        )
        .padding(.horizontal, Spacing.xl)
        }
        .background(Color.billixLightGreen)
    }
}
