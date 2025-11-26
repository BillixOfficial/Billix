//
//  LeaderboardSection.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Zone D: Top savers leaderboard with rank badges
//

import SwiftUI

struct LeaderboardSection: View {
    let topSavers: [LeaderboardEntry]
    let currentUser: LeaderboardEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            HStack {
                Text("Top Savers This Week")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Circle()
                    .fill(Color.billixLeaderGold)
                    .frame(width: 8, height: 8)

                Spacer()

                // Location indicator
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                    Text("Your Area")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.billixMediumGreen)
            }

            // Leaderboard card
            VStack(spacing: 0) {
                // Top 3 entries
                ForEach(Array(topSavers.prefix(3).enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRow(entry: entry)

                    if index < min(topSavers.count, 3) - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }

                // Separator
                if !currentUser.isCurrentUser || currentUser.rank > 3 {
                    HStack {
                        ForEach(0..<3) { _ in
                            Circle()
                                .fill(Color.billixMediumGreen.opacity(0.3))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // Current user row (pinned)
                    LeaderboardRow(entry: currentUser)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.billixMoneyGreen.opacity(0.08))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                        )
                }
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
            )
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                if entry.rank <= 3 {
                    // Medal for top 3
                    Circle()
                        .fill(entry.rankBadgeColor)
                        .frame(width: 32, height: 32)

                    Text("\(entry.rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    // Regular rank number
                    Circle()
                        .fill(Color.billixMediumGreen.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Text("#\(entry.rank)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.billixMediumGreen)
                }
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        entry.isCurrentUser
                            ? Color.billixMoneyGreen.opacity(0.2)
                            : Color.billixChartBlue.opacity(0.15)
                    )
                    .frame(width: 40, height: 40)

                Text(entry.avatarInitials)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(
                        entry.isCurrentUser
                            ? .billixMoneyGreen
                            : .billixChartBlue
                    )
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 14, weight: entry.isCurrentUser ? .bold : .semibold))
                    .foregroundColor(entry.isCurrentUser ? .billixMoneyGreen : .billixDarkGreen)

                if entry.isCurrentUser {
                    Text("That's you!")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixMoneyGreen)
                }
            }

            Spacer()

            // Points
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.billixArcadeGold)

                Text(entry.formattedPoints)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Rank Emoji Helper

extension LeaderboardEntry {
    var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        LeaderboardSection(
            topSavers: LeaderboardEntry.previewEntries,
            currentUser: LeaderboardEntry.currentUserEntry
        )
        .padding(20)
    }
}
