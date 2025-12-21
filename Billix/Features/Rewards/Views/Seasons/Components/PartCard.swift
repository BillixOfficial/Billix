//
//  PartCard.swift
//  Billix
//
//  Redesigned as "Expedition Ticket" - Clean, intentional journey metaphor
//

import SwiftUI

struct PartCard: View {
    let part: SeasonPart
    let progress: PartCompletionStats
    let isUnlocked: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    private var requiredPart: Int? {
        guard !isUnlocked, part.partNumber > 1 else { return nil }
        return part.partNumber - 1
    }

    var body: some View {
        Button(action: {
            if isUnlocked {
                onTap()
            }
        }) {
            ZStack {
                // Stack effect (back card) - only for unlocked cards
                if isUnlocked {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .rotationEffect(.degrees(-3))
                        .scaleEffect(0.95)
                        .opacity(0.5)
                        .offset(y: -8)
                }

                // Main card content
                VStack(alignment: .leading, spacing: 12) {
                    // Three-column grid
                    HStack(spacing: 16) {
                        // Left Column: Icon Box
                        ExpeditionIconBox(
                            partNumber: part.partNumber,
                            isUnlocked: isUnlocked
                        )

                        // Middle Column: Metadata
                        VStack(alignment: .leading, spacing: 8) {
                            // Part title
                            Text(part.title)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isUnlocked ? Color(hex: "#1F2937") : .gray)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .fixedSize(horizontal: false, vertical: true)

                            // Metadata pills (wrap if needed on narrow screens)
                            pillsView
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Right Column: Action Button (visual cue, but entire card is tappable)
                        ExpeditionActionButton(
                            isUnlocked: isUnlocked,
                            requiredPart: requiredPart
                        )
                    }

                    // Timeline progress bar
                    if isUnlocked {
                        TimelineProgressBar(progress: progress.progressPercent)
                            .frame(height: 2)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(
                    color: .black.opacity(isUnlocked ? 0.15 : 0.1),
                    radius: isUnlocked ? 8 : 2,
                    y: isUnlocked ? 4 : 2
                )
                .opacity(isUnlocked ? 1.0 : 0.6)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    @ViewBuilder
    private var pillsView: some View {
        // Use FlexBox-style wrapping HStack with adaptive layout
        ViewThatFits(alignment: .leading) {
            // Try horizontal first
            HStack(spacing: 8) {
                pillContent
            }

            // Fallback: Wrap to vertical on narrow screens
            VStack(alignment: .leading, spacing: 6) {
                pillContent
            }
        }
    }

    @ViewBuilder
    private var pillContent: some View {
        if progress.isSessionBased {
            // Session-Based Pills
            MetadataPillView(icon: "shuffle", text: "Randomized")

            if let attempts = progress.attempts, attempts > 0 {
                if let passed = progress.hasPassed, passed {
                    // Passed state
                    MetadataPillView(icon: "trophy.fill", text: "Passed!")
                } else {
                    // Attempts count
                    MetadataPillView(icon: "gamecontroller.fill", text: "\(attempts) \(attempts == 1 ? "play" : "plays")")
                }
            } else {
                // Not started
                MetadataPillView(icon: "gamecontroller.fill", text: "0 plays")
            }
        } else {
            // Location-Based Pills
            MetadataPillView(icon: "target", text: "\(progress.total) Stops")
            MetadataPillView(icon: "arrow.right", text: "Sequential")
        }
    }
}

// MARK: - Preview

#Preview("Part Card - Session Mode") {
    ZStack {
        Color(hex: "#FAFAFA")
            .ignoresSafeArea()

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
                onTap: { print("Tapped Part 1") }
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
                onTap: { print("Tapped Part 1") }
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
                onTap: { print("Tapped Part 1") }
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
                onTap: { print("Locked!") }
            )
            .padding(.horizontal, 20)
        }
    }
}

#Preview("Part Card - Location Mode") {
    ZStack {
        Color(hex: "#FAFAFA")
            .ignoresSafeArea()

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
                onTap: { print("Tapped Part 1") }
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
                onTap: { print("Tapped Part 2") }
            )
            .padding(.horizontal, 20)

            // Locked location part
            PartCard(
                part: SeasonPart(
                    id: UUID(),
                    seasonId: UUID(),
                    partNumber: 3,
                    title: "Southern States",
                    totalLocations: 10,
                    unlockRequirement: 20,
                    createdAt: Date()
                ),
                progress: PartCompletionStats(
                    completed: 0,
                    total: 10,
                    isSessionBased: false,
                    attempts: nil,
                    hasPassed: nil
                ),
                isUnlocked: false,
                onTap: { print("Locked!") }
            )
            .padding(.horizontal, 20)
        }
    }
}
