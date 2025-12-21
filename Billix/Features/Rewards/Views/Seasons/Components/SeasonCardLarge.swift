//
//  SeasonCardLarge.swift
//  Billix
//
//  Created by Claude Code
//  Large horizontal season card for TabView
//

import SwiftUI

struct SeasonCardLarge: View {
    let season: Season
    let progress: SeasonCompletionStats
    let isLocked: Bool
    let onTap: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var progressPercent: Double {
        guard progress.total > 0 else { return 0 }

        if progress.isSessionBased {
            // For session-based: percentage of parts passed
            return Double(progress.passedParts) / Double(progress.total)
        } else {
            // For location-based: percentage of locations completed
            return Double(progress.completed) / Double(progress.total)
        }
    }

    private var starsEarned: Int {
        if progress.isSessionBased {
            // Progression-based stars for session-based seasons
            // ⭐ 0 Stars = Not started (no legitimate attempts)
            // ⭐ 1 Star = In Progress (at least 1 attempt, but no parts passed)
            // ⭐⭐ 2 Stars = Halfway (at least 1 part passed, but not all)
            // ⭐⭐⭐ 3 Stars = Complete (all parts passed)

            if progress.passedParts >= progress.total && progress.total > 0 {
                return 3  // All parts passed
            } else if progress.passedParts > 0 {
                return 2  // At least 1 part passed
            } else if progress.attempts > 0 {
                return 1  // At least 1 attempt
            } else {
                return 0  // Not started
            }
        } else {
            // Percentage-based stars for location-based seasons
            if progressPercent >= 0.9 {
                return 3
            } else if progressPercent >= 0.5 {
                return 2
            } else if progressPercent > 0.0 {
                return 1
            } else {
                return 0
            }
        }
    }

    private var gradientColors: [Color] {
        switch season.seasonNumber {
        case 1:
            // USA Roadtrip: Sunset gradient (Orange to Rose Red)
            return [Color(hex: "#F97316"), Color(hex: "#E11D48")]
        case 2:
            // Global: Electric Indigo to Sky Blue
            return [Color(hex: "#4F46E5"), Color(hex: "#0EA5E9")]
        default:
            return [Color(hex: "#F97316"), Color(hex: "#E11D48")]
        }
    }

    var body: some View {
        Button(action: {
            if !isLocked {
                onTap()
            }
        }) {
            VStack(spacing: 0) {
                // Hero section with gradient background
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: isLocked ? [.gray.opacity(0.3), .gray.opacity(0.5)] : gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // No dark overlay - let the gradient shine

                    // Season icon with progress ring
                    VStack {
                        Spacer()

                        ZStack {
                            // Clean white watermark circle (not a shadow)
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 140, height: 140)

                            // Progress ring
                            if !isLocked {
                                CircularProgressRing(
                                    progress: progressPercent,
                                    colors: [.white, .white.opacity(0.9)],
                                    lineWidth: 8
                                )
                                .frame(width: 115, height: 115)
                            }

                            // Season icon with multi-layer shadow for depth
                            Image(systemName: isLocked ? "lock.fill" : season.iconName)
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }

                        Spacer()
                    }
                }
                .frame(height: 200)

                // Info section
                VStack(spacing: 0) {
                    // Star display (pushed up with more space below)
                    if !isLocked {
                        StarDisplay(starsEarned: starsEarned, maxStars: 3, size: 28)
                            .padding(.top, 16)
                            .padding(.bottom, 12)
                    }

                    // Title & Description grouped together
                    VStack(spacing: 6) {
                        // Title - Dark Charcoal
                        Text(season.title)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(isLocked ? Color(hex: "#9CA3AF") : Color(hex: "#1F2937"))
                            .multilineTextAlignment(.center)

                        // Description - Cool Grey
                        if let description = season.description {
                            Text(isLocked ? "Coming Soon" : description)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "#6B7280"))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding(.bottom, 14)

                    // Progress stats with optical alignment
                    if !isLocked {
                        HStack(spacing: 16) {
                            if progress.isSessionBased {
                                // Session-based: Show attempts
                                HStack(spacing: 5) {
                                    Image(systemName: "gamecontroller.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#6B7280"))

                                    Text("\(progress.attempts) \(progress.attempts == 1 ? "play" : "plays")")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: "#1F2937"))
                                        .lineLimit(1)
                                        .offset(y: -0.5)
                                }
                                .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }

                                Text("•")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#6B7280").opacity(0.5))

                                // Parts passed
                                HStack(spacing: 5) {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#6B7280"))

                                    Text("\(progress.passedParts)/\(progress.total) passed")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: "#1F2937"))
                                        .lineLimit(1)
                                        .offset(y: -0.5)
                                }
                            } else {
                                // Location-based: Show locations completed
                                HStack(spacing: 5) {
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#6B7280"))

                                    Text("\(progress.completed)/\(progress.total)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: "#1F2937"))
                                        .lineLimit(1)
                                        .offset(y: -0.5)
                                }
                                .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }

                                Text("•")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#6B7280").opacity(0.5))

                                // Progress percentage
                                HStack(spacing: 5) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#6B7280"))

                                    Text("\(Int(progressPercent * 100))%")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: "#1F2937"))
                                        .lineLimit(1)
                                        .offset(y: -0.5)
                                }
                                .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
                            }
                        }
                    } else {
                        // Release date info for locked seasons
                        if let releaseDate = season.releaseDate {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)

                                Text("Releases \(releaseDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white)  // Pure white card body
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.all, 8)
            .scaleEffect(appeared ? 1.0 : 0.9)
            .opacity(appeared ? 1.0 : 0.0)
            .animation(
                reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8),
                value: appeared
            )
        }
        .buttonStyle(SeasonCardButtonStyle())
        .disabled(isLocked)
        .onAppear {
            appeared = true
        }
    }
}

// MARK: - Button Style

struct SeasonCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Unlocked Season with Progress") {
    SeasonCardLarge(
        season: Season(
            id: UUID(),
            seasonNumber: 1,
            title: "USA Roadtrip",
            description: "Explore prices across America",
            isReleased: true,
            releaseDate: Date(),
            totalParts: 3,
            iconName: "flag.fill",
            createdAt: Date()
        ),
        progress: SeasonCompletionStats(
            completed: 4,
            total: 2,
            attempts: 4,
            passedParts: 0,
            isSessionBased: true
        ),
        isLocked: false,
        onTap: {}
    )
    .padding(.horizontal, 32)
}

#Preview("Locked Season") {
    SeasonCardLarge(
        season: Season(
            id: UUID(),
            seasonNumber: 2,
            title: "Global",
            description: "Price adventure around the world",
            isReleased: false,
            releaseDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            totalParts: 5,
            iconName: "globe.americas.fill",
            createdAt: Date()
        ),
        progress: SeasonCompletionStats(
            completed: 0,
            total: 30,
            attempts: 0,
            passedParts: 0,
            isSessionBased: false
        ),
        isLocked: true,
        onTap: {}
    )
    .padding(.horizontal, 32)
}

#Preview("Complete Season") {
    SeasonCardLarge(
        season: Season(
            id: UUID(),
            seasonNumber: 1,
            title: "USA Roadtrip",
            description: "Explore prices across America",
            isReleased: true,
            releaseDate: Date(),
            totalParts: 3,
            iconName: "flag.fill",
            createdAt: Date()
        ),
        progress: SeasonCompletionStats(
            completed: 10,
            total: 2,
            attempts: 10,
            passedParts: 2,
            isSessionBased: true
        ),
        isLocked: false,
        onTap: {}
    )
    .padding(.horizontal, 32)
}
