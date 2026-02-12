//
//  KarmaLeaderboardView.swift
//  Billix
//
//  Karma leaderboard with monthly hero card
//  and member rankings.
//

import SwiftUI

struct KarmaLeaderboardView: View {
    @ObservedObject var viewModel: HouseholdViewModel
    @StateObject private var karmaService = KarmaService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Monthly Hero Card
                if let hero = viewModel.monthlyHero {
                    HouseholdHeroCard(hero: hero)
                        .padding(.horizontal, 20)
                }

                // Leaderboard Header
                HStack {
                    Text("This Month's Standings")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Spacer()

                    // Balance indicator
                    let balance = viewModel.getBalanceStatus()
                    HStack(spacing: 4) {
                        Image(systemName: balance.icon)
                            .font(.system(size: 10))
                        Text(balance == .balanced ? "Balanced" : "Adjust")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(balance == .balanced ? Color(hex: "#4CAF7A") : Color(hex: "#E8A54B"))
                }
                .padding(.horizontal, 20)

                // Leaderboard Rows
                VStack(spacing: 0) {
                    ForEach(viewModel.leaderboard) { entry in
                        KarmaLeaderboardRow(entry: entry)

                        if entry.rank < viewModel.leaderboard.count {
                            Divider()
                                .padding(.leading, 70)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)

                // Karma Events History
                if !karmaService.recentEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            ForEach(karmaService.recentEvents.prefix(10)) { event in
                                KarmaEventRow(event: event)

                                if event.id != karmaService.recentEvents.prefix(10).last?.id {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)
                    }
                }

                // Karma Guide
                karmaGuide
                    .padding(.horizontal, 20)

                Spacer().frame(height: 100)
            }
            .padding(.top, 16)
        }
    }

    private var karmaGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#E8A54B"))
                Text("How to Earn Karma")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))
            }

            VStack(spacing: 8) {
                ForEach(KarmaEventType.allCases, id: \.self) { type in
                    HStack(spacing: 12) {
                        Image(systemName: type.icon)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#5B8A6B"))
                            .frame(width: 28, height: 28)
                            .background(Color(hex: "#5B8A6B").opacity(0.12))
                            .cornerRadius(8)

                        Text(type.displayName)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        Spacer()

                        Text("+\(type.karmaPoints)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "#4CAF7A"))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#E8A54B").opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#E8A54B").opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Household Hero Card

struct HouseholdHeroCard: View {
    let hero: HouseholdHero

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
                Text("HOUSEHOLD HERO")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Color(hex: "#E8A54B"))
                Spacer()
                Text(hero.month)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            HStack(spacing: 16) {
                // Avatar with crown
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#E8A54B"), Color(hex: "#F5D28B")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)

                    Text(hero.member.effectiveDisplayName.prefix(1).uppercased())
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    // Crown badge
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.yellow)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .offset(y: -45)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(hero.member.effectiveDisplayName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                            Text("\(hero.totalKarma)")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "#E8A54B"))

                        if let achievement = hero.topAchievement {
                            HStack(spacing: 4) {
                                Image(systemName: achievement.icon)
                                    .font(.system(size: 10))
                                Text(achievement.displayName)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(Color(hex: "#5B8A6B"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#5B8A6B").opacity(0.12))
                            .cornerRadius(6)
                        }
                    }

                    Text("Most karma earned this month!")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: "#FFF9E6"), Color(hex: "#FFFDF5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "#E8A54B").opacity(0.3), lineWidth: 2)
        )
        .shadow(color: Color(hex: "#E8A54B").opacity(0.2), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Karma Leaderboard Row

struct KarmaLeaderboardRow: View {
    let entry: KarmaLeaderboardEntry

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if entry.rank <= 3 {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 32, height: 32)

                    Text("\(entry.rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(entry.rank)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#8B9A94"))
                        .frame(width: 32)
                }
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(entry.isCurrentUser
                        ? Color(hex: "#5B8A6B").opacity(0.15)
                        : Color(hex: "#E8E8E8"))
                    .frame(width: 44, height: 44)

                Text(entry.member.effectiveDisplayName.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(entry.isCurrentUser
                        ? Color(hex: "#5B8A6B")
                        : Color(hex: "#8B9A94"))
            }

            // Name and role
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.member.effectiveDisplayName)
                        .font(.system(size: 15, weight: entry.isCurrentUser ? .bold : .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    if entry.isCurrentUser {
                        Text("(You)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#5B8A6B"))
                    }
                }

                if entry.member.role != .member {
                    HStack(spacing: 4) {
                        Image(systemName: entry.member.role.icon)
                            .font(.system(size: 9))
                        Text(entry.member.role.displayName)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#8B9A94"))
                }
            }

            Spacer()

            // Karma score
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                    Text("\(entry.member.monthlyKarma)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(Color(hex: "#E8A54B"))

                // Rank change indicator
                if let change = entry.rankChange, change != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 8, weight: .bold))
                        Text("\(abs(change))")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(change > 0 ? Color(hex: "#4CAF7A") : Color(hex: "#E07A6B"))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(entry.isCurrentUser ? Color(hex: "#5B8A6B").opacity(0.05) : Color.clear)
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color(hex: "#E8A54B") // Gold
        case 2: return Color(hex: "#A8B0B8") // Silver
        case 3: return Color(hex: "#CD7F32") // Bronze
        default: return Color(hex: "#8B9A94")
        }
    }
}

// MARK: - Karma Event Row

struct KarmaEventRow: View {
    let event: KarmaEvent

    var body: some View {
        HStack(spacing: 12) {
            // Event icon
            ZStack {
                Circle()
                    .fill(Color(hex: "#5B8A6B").opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: event.eventType.icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#5B8A6B"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.eventType.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#2D3B35"))

                if let description = event.description {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#8B9A94"))
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(event.karmaChange)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#4CAF7A"))

                Text(timeAgo(event.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

struct KarmaLeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        KarmaLeaderboardView(viewModel: HouseholdViewModel())
    }
}
