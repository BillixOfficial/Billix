//
//  GiveawayEntryCard.swift
//  Billix
//
//  Created by Claude Code
//  Weekly giveaway card displaying prizes, countdown, and entry info
//

import SwiftUI

struct GiveawayEntryCard: View {
    let userEntries: Int
    let totalEntries: Int
    let currentTier: RewardsTier
    let onBuyEntries: () -> Void
    let onHowToEarn: () -> Void

    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?

    var isEligible: Bool {
        true  // Draw available to everyone
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
        VStack(spacing: 0) {
            // Header with countdown
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.billixArcadeGold)

                    Text("Weekly Giveaway")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.billixDarkGreen)

                    Spacer()
                }

                // Countdown timer
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixMoneyGreen)

                    Text("Draw in: \(formatTimeRemaining())")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixMediumGreen)

                    Spacer()
                }
            }
            .padding(16)
            .background(Color.billixLightGreen)

            if isEligible {
                // Prize tiers
                VStack(spacing: 12) {
                    PrizeTierRow(
                        place: "1st Place",
                        prize: "$2.50 Starbucks Card",
                        icon: "crown.fill",
                        iconColor: .billixArcadeGold
                    )

                    Divider()
                        .padding(.horizontal, 8)

                    PrizeTierRow(
                        place: "2nd & 3rd",
                        prize: "$1.00 Bill Credit",
                        icon: "star.fill",
                        iconColor: .billixSilverTier
                    )
                }
                .padding(16)

                Divider()

                // User's entry info
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Entries")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.billixMediumGreen)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Text("\(userEntries)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.billixMoneyGreen)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Your Odds")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.billixMediumGreen)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Text(formattedOdds)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.billixChartBlue)
                        }
                    }

                    // Total entries indicator
                    HStack(spacing: 6) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.billixMediumGreen)

                        Text("\(totalEntries) total entries this week")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.billixMediumGreen)

                        Spacer()
                    }
                }
                .padding(16)

                // CTAs
                VStack(spacing: 10) {
                    // Buy more entries button
                    Button(action: onBuyEntries) {
                        HStack(spacing: 8) {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 16, weight: .semibold))

                            Text("Buy More Entries")
                                .font(.system(size: 16, weight: .semibold))

                            Spacer()

                            Text("100 pts each")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.billixMoneyGreen.opacity(0.9))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.billixMoneyGreen)
                        )
                    }

                    // How to earn free entries
                    Button(action: onHowToEarn) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))

                            Text("How to Earn Free Entries")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.billixMoneyGreen)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

            } else {
                // Locked state for Bronze tier
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.billixMediumGreen.opacity(0.5))

                    VStack(spacing: 8) {
                        Text("Unlock at Silver Tier")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.billixDarkGreen)

                        Text("Reach 8,000 points to enter weekly giveaways")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.billixMediumGreen)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: {
                        // Navigate to tier progress view
                    }) {
                        Text("View Tier Progress")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.billixMoneyGreen)
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
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

        // Get next Sunday at 8pm ET
        var components = calendar.dateComponents([.year, .month, .day, .weekday], from: now)

        // Calculate days until Sunday (weekday 1 = Sunday)
        let currentWeekday = components.weekday ?? 1
        let daysUntilSunday = currentWeekday == 1 ? 0 : (8 - currentWeekday)

        // Set to next Sunday at 8pm ET
        components.weekday = 1
        components.hour = 20 // 8pm
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "America/New_York")

        if let nextDraw = calendar.date(byAdding: .day, value: daysUntilSunday, to: now) {
            var drawComponents = calendar.dateComponents([.year, .month, .day], from: nextDraw)
            drawComponents.hour = 20
            drawComponents.minute = 0
            drawComponents.second = 0
            drawComponents.timeZone = TimeZone(identifier: "America/New_York")

            if let drawDate = calendar.date(from: drawComponents) {
                // If we're past Sunday 8pm, add 7 days
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
        let seconds = Int(timeRemaining) % 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Prize Tier Row Component

struct PrizeTierRow: View {
    let place: String
    let prize: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(place)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Text(prize)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Silver Tier - No Entries") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack {
            GiveawayEntryCard(
                userEntries: 0,
                totalEntries: 1247,
                currentTier: .silver,
                onBuyEntries: {
                },
                onHowToEarn: {
                }
            )
            .padding(20)

            Spacer()
        }
    }
}

#Preview("Silver Tier - 5 Entries") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack {
            GiveawayEntryCard(
                userEntries: 5,
                totalEntries: 1247,
                currentTier: .silver,
                onBuyEntries: {
                },
                onHowToEarn: {
                }
            )
            .padding(20)

            Spacer()
        }
    }
}

#Preview("Gold Tier - 25 Entries") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack {
            GiveawayEntryCard(
                userEntries: 25,
                totalEntries: 1247,
                currentTier: .gold,
                onBuyEntries: {
                },
                onHowToEarn: {
                }
            )
            .padding(20)

            Spacer()
        }
    }
}

#Preview("Bronze Tier - Locked") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack {
            GiveawayEntryCard(
                userEntries: 0,
                totalEntries: 1247,
                currentTier: .bronze,
                onBuyEntries: {
                },
                onHowToEarn: {
                }
            )
            .padding(20)

            Spacer()
        }
    }
}
