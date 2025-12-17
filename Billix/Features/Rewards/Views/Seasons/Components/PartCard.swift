//
//  PartCard.swift
//  Billix
//
//  Created by Claude Code
//  Card component for displaying season part (chapter) information
//

import SwiftUI

struct PartCard: View {
    let part: SeasonPart
    let progress: (completed: Int, total: Int)
    let isUnlocked: Bool
    let onTap: () -> Void

    private var progressPercent: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.completed) / Double(progress.total)
    }

    private var isCompleted: Bool {
        progress.completed == progress.total && progress.total > 0
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Left side: Part number badge
                ZStack {
                    Circle()
                        .fill(
                            isUnlocked
                                ? LinearGradient(
                                    colors: [Color(hex: "#6B2DD6"), Color(hex: "#8B5CF6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [.gray.opacity(0.3), .gray.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 60, height: 60)

                    if isUnlocked {
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(part.partNumber)")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                // Right side: Part info
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(part.displayTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isUnlocked ? .billixDarkGreen : .gray)
                        .lineLimit(1)

                    // Progress info
                    if isUnlocked {
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
                                        .frame(width: geometry.size.width * progressPercent, height: 5)
                                }
                            }
                            .frame(height: 5)

                            // Progress text
                            Text("\(progress.completed)/\(progress.total)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.billixMediumGreen)
                                .frame(width: 40, alignment: .trailing)
                        }

                        // Status text
                        if isCompleted {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.billixArcadeGold)

                                Text("Complete!")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.billixMoneyGreen)
                            }
                        }
                    } else {
                        // Unlock requirement text
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)

                            Text("Complete \(part.unlockRequirement) locations to unlock")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()

                // Right arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isUnlocked ? .billixMediumGreen : .gray.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isUnlocked)
    }
}

// MARK: - Preview

#Preview("Part Card") {
    VStack(spacing: 16) {
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
            progress: (completed: 7, total: 10),
            isUnlocked: true,
            onTap: {}
        )
        .padding(.horizontal, 20)

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
            progress: (completed: 0, total: 10),
            isUnlocked: false,
            onTap: {}
        )
        .padding(.horizontal, 20)

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
            progress: (completed: 10, total: 10),
            isUnlocked: true,
            onTap: {}
        )
        .padding(.horizontal, 20)
    }
    .background(Color.billixLightGreen)
}
