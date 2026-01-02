//
//  HomeBanners.swift
//  Billix
//

import SwiftUI

// MARK: - All Clear Banner

struct AllClearBanner: View {
    private let hasUrgentItems = false
    private let nextActionDays = 5

    private var hour: Int { Calendar.current.component(.hour, from: Date()) }
    private var isEvening: Bool { hour >= 18 || hour < 6 }
    private var dayOfWeek: Int { Calendar.current.component(.weekday, from: Date()) }
    private var isWeekend: Bool { dayOfWeek == 1 || dayOfWeek == 7 }

    private var closureMessage: String {
        if hasUrgentItems {
            return "You have \(nextActionDays) day\(nextActionDays == 1 ? "" : "s") until your next action."
        } else if isWeekend {
            return "You handled everything that could impact you this week."
        } else if isEvening {
            return "You're all set — nothing urgent right now."
        } else {
            return "Everything's on track. We'll alert you if anything changes."
        }
    }

    private var closureIcon: String {
        if hasUrgentItems { return "clock.fill" }
        else if isWeekend { return "checkmark.seal.fill" }
        else { return "checkmark.shield.fill" }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: closureIcon)
                .font(.system(size: HomeTheme.iconMedium))
                .foregroundColor(HomeTheme.success)

            Text(closureMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(HomeTheme.secondaryText)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 11))
                Text("Alerts on")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(HomeTheme.accent.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [HomeTheme.success.opacity(0.06), HomeTheme.accent.opacity(0.04)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(HomeTheme.success.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, HomeTheme.horizontalPadding)
    }
}

// MARK: - Financial Narrative Banner

struct FinancialNarrativeBanner: View {
    @State private var isExpanded = false

    private let weeklyHighlight = "avoided a $22 spike"
    private let weeklySavings = 8
    private let causeAttribution = "Mostly from timing, not switching"
    private let streakMessage = "You've been ahead of your bills for 6 days"

    var body: some View {
        Button {
            haptic()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [HomeTheme.accent, HomeTheme.success],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: HomeTheme.avatarMedium, height: HomeTheme.avatarMedium)

                        Image(systemName: "text.book.closed.fill")
                            .font(.system(size: HomeTheme.iconMedium))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("This Week's Story")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(HomeTheme.accent)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("You \(weeklyHighlight) and saved $\(weeklySavings) proactively.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(HomeTheme.primaryText)
                                .lineLimit(2)

                            Text(causeAttribution)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(HomeTheme.success)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(HomeTheme.accent)
                }
                .padding(14)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()

                        HStack(spacing: 10) {
                            Image(systemName: "chart.pie.fill")
                                .font(.system(size: HomeTheme.iconSmall))
                                .foregroundColor(HomeTheme.info)
                                .frame(width: 28, height: 28)
                                .background(HomeTheme.info.opacity(0.12))
                                .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("How You Saved")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(HomeTheme.secondaryText)

                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Circle().fill(HomeTheme.success).frame(width: 6, height: 6)
                                        Text("Timing: $6")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    HStack(spacing: 4) {
                                        Circle().fill(HomeTheme.info).frame(width: 6, height: 6)
                                        Text("Avoidance: $2")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                }
                                .foregroundColor(HomeTheme.primaryText)
                            }
                        }

                        HStack(spacing: 10) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: HomeTheme.iconSmall))
                                .foregroundColor(HomeTheme.danger)
                                .frame(width: 28, height: 28)
                                .background(HomeTheme.danger.opacity(0.12))
                                .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your Streak")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(HomeTheme.secondaryText)
                                Text(streakMessage)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(HomeTheme.primaryText)
                            }
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                            Text("You're someone who stays ahead of their bills.")
                                .font(.system(size: 12, weight: .semibold))
                                .italic()
                        }
                        .foregroundColor(HomeTheme.accent)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(
                LinearGradient(
                    colors: [HomeTheme.accent.opacity(0.08), HomeTheme.success.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(HomeTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: HomeTheme.cornerRadius)
                    .stroke(HomeTheme.accent.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, HomeTheme.horizontalPadding)
    }
}

// MARK: - Invite Earn Banner

struct InviteEarnBanner: View {
    var body: some View {
        Button { haptic(.medium) } label: {
            HStack(spacing: 14) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 28))
                    .foregroundColor(HomeTheme.purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Give $5, Get $5")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(HomeTheme.primaryText)
                    Text("Invite friends to verify their bills")
                        .font(.system(size: 13))
                        .foregroundColor(HomeTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: HomeTheme.iconMedium, weight: .semibold))
                    .foregroundColor(HomeTheme.purple)
            }
            .padding(HomeTheme.cardPadding)
            .background(
                LinearGradient(
                    colors: [HomeTheme.purple.opacity(0.1), HomeTheme.purple.opacity(0.15)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(HomeTheme.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
        .padding(.horizontal, HomeTheme.horizontalPadding)
    }
}
