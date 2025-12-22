//
//  WeeklyGiveawayCard.swift
//  Billix
//
//  Created by Claude Code
//  Standalone card for weekly giveaway with live countdown
//

import SwiftUI

struct WeeklyGiveawayCard: View {
    let userEntries: Int
    let totalEntries: Int
    let currentTier: RewardsTier
    let onBuyEntries: () -> Void
    let onHowToEarn: () -> Void

    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?

    var isEligible: Bool {
        currentTier.rawValue != "Bronze"
    }

    var odds: Double {
        guard totalEntries > 0, userEntries > 0 else { return 0 }
        return (Double(userEntries) / Double(totalEntries)) * 100
    }

    var formattedOdds: String {
        if odds < 0.01 {
            return "<0.01%"
        } else if odds < 1 {
            return String(format: "%.2f%%", odds)
        } else {
            return String(format: "%.1f%%", odds)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.billixArcadeGold.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.billixArcadeGold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Giveaway")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.billixDarkGreen)

                    Text("Win real prizes every Sunday")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.billixMediumGreen)
                }

                Spacer()
            }
            .padding(.horizontal, 20)

            // Card
            VStack(spacing: 0) {
                if isEligible {
                    // Eligible state
                    VStack(spacing: 16) {
                        // Countdown banner
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.billixArcadeGold)

                            Text("Draw in: \(formatTimeRemaining())")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.billixDarkGreen)

                            Spacer()

                            Text("🎁 Sunday 8pm ET")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.billixMediumGreen)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.billixArcadeGold.opacity(0.1))
                        )

                        // Prize info and user stats in one compact row
                        HStack(spacing: 16) {
                            // Prize tiers - compact
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.billixArcadeGold)

                                VStack(alignment: .leading, spacing: 0) {
                                    Text("1st: $2.50")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.billixDarkGreen)
                                    Text("2nd-3rd: $1")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.billixMediumGreen)
                                }
                            }

                            Divider()
                                .frame(height: 30)

                            // Your entries
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Entries")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.billixMediumGreen)
                                Text("\(userEntries)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.billixMoneyGreen)
                            }

                            Divider()
                                .frame(height: 30)

                            // Your odds
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Odds")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.billixMediumGreen)
                                Text(formattedOdds)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.billixChartBlue)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)

                        // Buy more entries CTA
                        Button(action: onBuyEntries) {
                            HStack(spacing: 8) {
                                Image(systemName: "ticket.fill")
                                    .font(.system(size: 15, weight: .semibold))

                                Text("Buy More Entries")
                                    .font(.system(size: 15, weight: .semibold))

                                Spacer()

                                Text("100 pts")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [.billixArcadeGold, .billixPrizeOrange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle(scale: 0.97))
                    }
                    .padding(18)
                } else {
                    // Locked state
                    VStack(spacing: 16) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.billixMediumGreen.opacity(0.5))

                        VStack(spacing: 6) {
                            Text("Unlock at Silver Tier")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.billixDarkGreen)

                            Text("Reach 8,000 points to enter")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.billixMediumGreen)
                        }
                    }
                    .padding(.vertical, 30)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
        }
        .onAppear {
            calculateTimeRemaining()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Timer Functions

    func calculateTimeRemaining() {
        let now = Date()
        let calendar = Calendar.current

        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: now)
        let currentWeekday = components.weekday ?? 1
        let daysUntilSunday = currentWeekday == 1 ? 0 : (8 - currentWeekday)

        if let nextDraw = calendar.date(byAdding: .day, value: daysUntilSunday, to: now) {
            var drawComponents = calendar.dateComponents([.year, .month, .day], from: nextDraw)
            drawComponents.hour = 20
            drawComponents.minute = 0
            drawComponents.second = 0
            drawComponents.timeZone = TimeZone(identifier: "America/New_York")

            if let drawDate = calendar.date(from: drawComponents) {
                if drawDate < now {
                    if let nextWeekDraw = calendar.date(byAdding: .day, value: 7, to: drawDate) {
                        timeRemaining = nextWeekDraw.timeIntervalSince(now)
                        return
                    }
                }
                timeRemaining = drawDate.timeIntervalSince(now)
            }
        }
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                calculateTimeRemaining()
            }
        }
    }

    func formatTimeRemaining() -> String {
        let days = Int(timeRemaining) / 86400
        let hours = (Int(timeRemaining) % 86400) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Prize Tier Compact

struct PrizeTierCompact: View {
    let place: String
    let prize: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(place)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Text(prize)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.billixMoneyGreen)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Eligible with Entries") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        ScrollView {
            WeeklyGiveawayCard(
                userEntries: 5,
                totalEntries: 1247,
                currentTier: .silver,
                onBuyEntries: {},
                onHowToEarn: {}
            )
            .padding(.top, 20)
        }
    }
}

#Preview("Locked (Bronze Tier)") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        ScrollView {
            WeeklyGiveawayCard(
                userEntries: 0,
                totalEntries: 1247,
                currentTier: .bronze,
                onBuyEntries: {},
                onHowToEarn: {}
            )
            .padding(.top, 20)
        }
    }
}
