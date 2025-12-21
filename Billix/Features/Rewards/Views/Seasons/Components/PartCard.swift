//
//  PartCard.swift
//  Billix
//
//  Created by Claude Code
//  Enhanced card component for displaying season part (chapter) information
//

import SwiftUI

struct PartCard: View {
    let part: SeasonPart
    let progress: PartCompletionStats  // Changed from tuple
    let isUnlocked: Bool
    let onTap: () -> Void

    private var isCompleted: Bool {
        if progress.isSessionBased {
            return progress.hasPassed ?? false
        } else {
            return progress.completed == progress.total && progress.total > 0
        }
    }

    private var starsEarned: Int {
        if progress.isSessionBased {
            // Session mode: 0-3 stars based on passes
            if let passed = progress.hasPassed, passed {
                return 3  // Passed = 3 stars
            } else if let attempts = progress.attempts, attempts > 0 {
                return 1  // At least attempted = 1 star
            } else {
                return 0  // Not started
            }
        } else {
            // Location mode: percentage-based stars
            let percent = progress.progressPercent
            if percent >= 0.9 {
                return 3
            } else if percent >= 0.5 {
                return 2
            } else if percent > 0.0 {
                return 1
            } else {
                return 0
            }
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Left side: Progress ring with part number
                PartProgressRing(
                    partNumber: part.partNumber,
                    progress: progress.progressPercent,
                    starsEarned: starsEarned,
                    isUnlocked: isUnlocked,
                    isCompleted: isCompleted
                )

                // Right side: Part info
                VStack(alignment: .leading, spacing: 10) {
                    // Title
                    Text(part.displayTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isUnlocked ? Color(hex: "#1F2937") : .gray)
                        .lineLimit(1)

                    // Stars display
                    if isUnlocked && starsEarned > 0 {
                        HStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { index in
                                Image(systemName: index < starsEarned ? "star.fill" : "star")
                                    .font(.system(size: 12))
                                    .foregroundColor(index < starsEarned ? .billixArcadeGold : .gray.opacity(0.3))
                            }
                        }
                    }

                    // Progress display (adapts to mode)
                    if isUnlocked {
                        if progress.isSessionBased {
                            // Session-based: Show attempts and pass status
                            VStack(alignment: .leading, spacing: 4) {
                                if let passed = progress.hasPassed, passed {
                                    HStack(spacing: 5) {
                                        Image(systemName: "trophy.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.billixMoneyGreen)

                                        Text("Passed!")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.billixMoneyGreen)
                                    }
                                } else {
                                    HStack(spacing: 5) {
                                        Image(systemName: "gamecontroller.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(hex: "#6B7280"))

                                        Text("\(progress.attempts ?? 0) \(progress.attempts == 1 ? "play" : "plays")")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(hex: "#1F2937"))
                                    }
                                }
                            }
                        } else {
                            // Location-based: Show locations completed
                            HStack(spacing: 8) {
                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 5)

                                        // Fill
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "#6B2DD6"), Color(hex: "#8B5CF6")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geometry.size.width * progress.progressPercent, height: 5)
                                            .animation(.easeInOut(duration: 0.5), value: progress.progressPercent)
                                    }
                                }
                                .frame(height: 5)

                                // Progress text
                                Text(progress.displayText)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "#6B7280"))
                                    .frame(width: 45, alignment: .trailing)
                            }
                        }
                    } else {
                        // Unlock requirement text
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)

                            Text(progress.isSessionBased
                                ? "Pass Part \(part.partNumber - 1) to unlock"
                                : "Complete \(part.unlockRequirement) locations to unlock")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Right arrow
                if isUnlocked {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
            }
            .padding(18)
            .background(
                ZStack {
                    // Glassmorphism background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isUnlocked
                                ? Color.white
                                : Color.white.opacity(0.7)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)

                    // Gradient border for unlocked parts
                    if isUnlocked && !isCompleted {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color(hex: "#6B2DD6").opacity(0.3), Color(hex: "#8B5CF6").opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}

// MARK: - Preview

#Preview("Part Card - Session Mode") {
    VStack(spacing: 20) {
        // Session mode - Not started
        PartCard(
            part: SeasonPart(
                id: UUID(),
                seasonId: UUID(),
                partNumber: 1,
                title: "Coast to Coast",
                totalLocations: 10,
                unlockRequirement: 0,
                createdAt: Date()
            ),
            progress: PartCompletionStats(
                completed: 0,
                total: 1,
                isSessionBased: true,
                attempts: 0,
                hasPassed: false
            ),
            isUnlocked: true,
            onTap: {}
        )
        .padding(.horizontal, 20)

        // Session mode - Attempted but not passed
        PartCard(
            part: SeasonPart(
                id: UUID(),
                seasonId: UUID(),
                partNumber: 1,
                title: "Coast to Coast",
                totalLocations: 10,
                unlockRequirement: 0,
                createdAt: Date()
            ),
            progress: PartCompletionStats(
                completed: 0,
                total: 1,
                isSessionBased: true,
                attempts: 4,
                hasPassed: false
            ),
            isUnlocked: true,
            onTap: {}
        )
        .padding(.horizontal, 20)

        // Session mode - Passed
        PartCard(
            part: SeasonPart(
                id: UUID(),
                seasonId: UUID(),
                partNumber: 1,
                title: "Coast to Coast",
                totalLocations: 10,
                unlockRequirement: 0,
                createdAt: Date()
            ),
            progress: PartCompletionStats(
                completed: 1,
                total: 1,
                isSessionBased: true,
                attempts: 7,
                hasPassed: true
            ),
            isUnlocked: true,
            onTap: {}
        )
        .padding(.horizontal, 20)

        // Locked part
        PartCard(
            part: SeasonPart(
                id: UUID(),
                seasonId: UUID(),
                partNumber: 2,
                title: "Deep Cuts",
                totalLocations: 10,
                unlockRequirement: 10,
                createdAt: Date()
            ),
            progress: PartCompletionStats(
                completed: 0,
                total: 1,
                isSessionBased: true,
                attempts: 0,
                hasPassed: false
            ),
            isUnlocked: false,
            onTap: {}
        )
        .padding(.horizontal, 20)
    }
    .background(Color.billixLightGreen)
}

#Preview("Part Card - Location Mode") {
    VStack(spacing: 20) {
        // Location mode - In progress
        PartCard(
            part: SeasonPart(
                id: UUID(),
                seasonId: UUID(),
                partNumber: 1,
                title: "Western States",
                totalLocations: 10,
                unlockRequirement: 0,
                createdAt: Date()
            ),
            progress: PartCompletionStats(
                completed: 7,
                total: 10,
                isSessionBased: false,
                attempts: nil,
                hasPassed: nil
            ),
            isUnlocked: true,
            onTap: {}
        )
        .padding(.horizontal, 20)

        // Location mode - Completed
        PartCard(
            part: SeasonPart(
                id: UUID(),
                seasonId: UUID(),
                partNumber: 2,
                title: "Eastern States",
                totalLocations: 10,
                unlockRequirement: 10,
                createdAt: Date()
            ),
            progress: PartCompletionStats(
                completed: 10,
                total: 10,
                isSessionBased: false,
                attempts: nil,
                hasPassed: nil
            ),
            isUnlocked: true,
            onTap: {}
        )
        .padding(.horizontal, 20)
    }
    .background(Color.billixLightGreen)
}
