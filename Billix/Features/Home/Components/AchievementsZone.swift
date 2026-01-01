//
//  AchievementsZone.swift
//  Billix
//

import SwiftUI

// MARK: - Achievement Model

struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
    let isUnlocked: Bool
    let capability: String
    let capabilityIcon: String
    let benefit: String
    let progress: Double?
}

// MARK: - Achievement Badges Zone

struct AchievementBadgesZone: View {
    @State private var selectedAchievement: Achievement? = nil

    private let achievements = [
        Achievement(
            icon: "star.fill",
            title: "First Bill",
            color: HomeTheme.warning,
            isUnlocked: true,
            capability: "AI Bill Analysis",
            capabilityIcon: "brain.head.profile",
            benefit: "Get personalized savings recommendations on every bill",
            progress: nil
        ),
        Achievement(
            icon: "flame.fill",
            title: "7-Day Streak",
            color: HomeTheme.danger,
            isUnlocked: true,
            capability: "Premium Forecast",
            capabilityIcon: "chart.line.uptrend.xyaxis",
            benefit: "Unlock 30-day bill predictions and spike alerts",
            progress: nil
        ),
        Achievement(
            icon: "dollarsign.circle.fill",
            title: "$100 Saved",
            color: HomeTheme.success,
            isUnlocked: true,
            capability: "Boosted Flash Drops",
            capabilityIcon: "bolt.shield.fill",
            benefit: "Get 2x points on all Flash Drop offers",
            progress: nil
        ),
        Achievement(
            icon: "person.2.fill",
            title: "Referral Pro",
            color: HomeTheme.purple,
            isUnlocked: false,
            capability: "Early Access",
            capabilityIcon: "clock.badge.checkmark.fill",
            benefit: "See Flash Drops 24 hours before everyone else",
            progress: 0.4
        ),
        Achievement(
            icon: "crown.fill",
            title: "Bill Master",
            color: HomeTheme.info,
            isUnlocked: false,
            capability: "1-on-1 Coach Session",
            capabilityIcon: "person.crop.circle.badge.checkmark",
            benefit: "Free 30-min call with a bill negotiation expert",
            progress: 0.65
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16))
                        .foregroundColor(HomeTheme.warning)
                    Text("Achievements").sectionHeader()
                }
                Spacer()

                HStack(spacing: 6) {
                    Text("\(achievements.filter { $0.isUnlocked }.count)/\(achievements.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(HomeTheme.primaryText)

                    if let nextAchievement = achievements.first(where: { !$0.isUnlocked }) {
                        Text("· Next: \(nextAchievement.title)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(HomeTheme.accent)
                    }
                }
            }
            .padding(.horizontal, HomeTheme.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements) { achievement in
                        AchievementBadge(
                            achievement: achievement,
                            isSelected: selectedAchievement?.id == achievement.id,
                            onTap: {
                                haptic()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedAchievement?.id == achievement.id {
                                        selectedAchievement = nil
                                    } else {
                                        selectedAchievement = achievement
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, HomeTheme.horizontalPadding)
            }

            if let selected = selectedAchievement {
                AchievementDetailCard(achievement: selected)
                    .padding(.horizontal, HomeTheme.horizontalPadding)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let achievement: Achievement
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    if isSelected {
                        Circle()
                            .stroke(achievement.color, lineWidth: 2)
                            .frame(width: 62, height: 62)
                    }

                    Circle()
                        .fill(achievement.isUnlocked ? achievement.color.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: achievement.icon)
                        .font(.system(size: HomeTheme.iconLarge))
                        .foregroundColor(achievement.isUnlocked ? achievement.color : Color.gray.opacity(0.4))

                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: HomeTheme.iconSmall))
                            .foregroundColor(HomeTheme.success)
                            .background(Circle().fill(Color.white).frame(width: 12, height: 12))
                            .offset(x: 18, y: 18)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .offset(x: 18, y: 18)
                    }
                }

                VStack(spacing: 2) {
                    Text(achievement.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(achievement.isUnlocked ? HomeTheme.primaryText : HomeTheme.secondaryText)
                        .lineLimit(1)

                    if achievement.isUnlocked {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .bold))
                            Text("Active")
                                .font(.system(size: 8, weight: .semibold))
                        }
                        .foregroundColor(HomeTheme.success)
                    }
                }
            }
            .frame(width: 75)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Achievement Detail Card

struct AchievementDetailCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 22))
                        .foregroundColor(achievement.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(achievement.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(HomeTheme.primaryText)

                        if achievement.isUnlocked {
                            Text("UNLOCKED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(HomeTheme.success)
                                .cornerRadius(4)
                        }
                    }

                    if !achievement.isUnlocked, let progress = achievement.progress {
                        HStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 6)

                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(achievement.color)
                                        .frame(width: geo.size.width * progress, height: 6)
                                }
                            }
                            .frame(height: 6)

                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(achievement.color)
                        }
                    }
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(achievement.isUnlocked ? HomeTheme.success : HomeTheme.secondaryText)

                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(achievement.isUnlocked ? HomeTheme.success.opacity(0.1) : Color.gray.opacity(0.08))
                        .frame(width: 36, height: 36)

                    Image(systemName: achievement.capabilityIcon)
                        .font(.system(size: 16))
                        .foregroundColor(achievement.isUnlocked ? HomeTheme.success : HomeTheme.secondaryText)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(achievement.capability)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(achievement.isUnlocked ? HomeTheme.success : HomeTheme.primaryText)

                    Text(achievement.benefit)
                        .font(.system(size: 11))
                        .foregroundColor(HomeTheme.secondaryText)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(12)
            .background(achievement.isUnlocked ? HomeTheme.success.opacity(0.06) : Color.gray.opacity(0.04))
            .cornerRadius(12)
        }
        .padding(14)
        .background(HomeTheme.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(achievement.isUnlocked ? HomeTheme.success.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: HomeTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
}
