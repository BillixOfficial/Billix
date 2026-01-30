//
//  WeeklyGiveawayCard.swift
//  Billix
//
//  Premium "High-Stakes Ticket" design for weekly sweepstakes
//  Features dark gradient, massive typography, ticket stepper, and social proof
//

import SwiftUI

struct WeeklyGiveawayCard: View {
    let userEntries: Int
    let totalEntries: Int
    let currentTier: RewardsTier
    let isComingSoon: Bool
    let onBuyEntries: () -> Void
    let onHowToEarn: () -> Void

    @State private var timeRemaining: TimeInterval = 0
    @State private var timerTask: Task<Void, Never>?
    @State private var ticketCount: Int = 1
    @State private var shimmerOffset: CGFloat = -300
    @State private var showOfficialRules: Bool = false

    var isEligible: Bool {
        true  // Draw available to everyone
    }

    var body: some View {
        VStack(spacing: 0) {
            // Draw is available to everyone (isEligible always true)
            eligibleCard
                .overlay(
                    Group {
                        if isComingSoon {
                            comingSoonOverlay
                        }
                    }
                )
        }
        .padding(.horizontal, 20)
        .sheet(isPresented: $showOfficialRules) {
            SweepstakesOfficialRulesView()
        }
        .onAppear {
            if !isComingSoon {
                calculateTimeRemaining()
                startTimer()
                startShimmer()
            }
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }

    // MARK: - Eligible Card (Premium Design)

    private var eligibleCard: some View {
        ZStack {
            // Dark Premium Gradient Background
            LinearGradient(
                colors: [
                    Color.billixDarkGreen,
                    Color.billixMoneyGreen,
                    Color.billixArcadeGold
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Confetti Pattern Overlay
            ConfettiPattern()
                .opacity(0.15)

            // Shimmer effect
            LinearGradient(
                colors: [.clear, .white.opacity(0.15), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: shimmerOffset)

            VStack(spacing: 20) {
                // HEADER: Top badges
                HStack {
                    // "WEEKLY SWEEPSTAKES" badge
                    Text("WEEKLY SWEEPSTAKES")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.billixArcadeGold)
                        .tracking(1)

                    // Info button for official rules
                    Button(action: {
                        showOfficialRules = true
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    // Countdown pill
                    HStack(spacing: 6) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 12, weight: .bold))

                        Text("Ends in \(formatTimeRemaining())")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.9))
                    )
                }

                // HERO SECTION: The Prize
                VStack(spacing: 12) {
                    // 3D Bill Graphic
                    ZStack {
                        // Bill shadow layers for depth
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.2))
                            .frame(width: 100, height: 60)
                            .offset(x: 4, y: 4)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 100, height: 60)
                            .offset(x: 2, y: 2)

                        // Main bill
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white, Color(hex: "#f0f0f0")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 60)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.billixMediumGreen.opacity(0.3))

                                    Text("BILL")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.billixMediumGreen.opacity(0.5))
                                }
                            )

                        // Giant "PAID" stamp
                        Text("PAID")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.billixMoneyGreen.opacity(0.9))
                            .rotationEffect(.degrees(-15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.billixMoneyGreen, lineWidth: 3)
                                    .padding(-6)
                            )
                    }

                    // Massive Prize Typography
                    Text("Win $50")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("Off Your Bill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.billixArcadeGold)
                }
                .padding(.vertical, 8)

                // TICKET BOOTH: Interactive Stepper
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Minus button
                        Button {
                            if ticketCount > 1 {
                                ticketCount -= 1
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(ticketCount > 1 ? .white : .white.opacity(0.3))
                        }
                        .disabled(ticketCount <= 1)

                        // Ticket display
                        HStack(spacing: 8) {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.billixArcadeGold)

                            Text("\(ticketCount)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(minWidth: 40)

                            Text(ticketCount == 1 ? "Ticket" : "Tickets")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                        )

                        // Plus button
                        Button {
                            if ticketCount < 10 {
                                ticketCount += 1
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(ticketCount < 10 ? .white : .white.opacity(0.3))
                        }
                        .disabled(ticketCount >= 10)
                    }

                    // Cost label
                    Text("100 points per entry")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                // CLIMAX: Massive Enter Button
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    onBuyEntries()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20, weight: .bold))

                        Text("ENTER DRAW (\(ticketCount * 100) PTS)")
                            .font(.system(size: 18, weight: .black))
                            .tracking(0.5)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "#1e3a8a"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        ZStack {
                            // Neon glow layers
                            Capsule()
                                .fill(Color.billixArcadeGold)
                                .shadow(color: .billixArcadeGold.opacity(0.8), radius: 20)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "#FFD700"), // Gold
                                            Color(hex: "#FFA500")  // Orange
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    )
                }
                .buttonStyle(PulseButtonStyle())

                // SOCIAL PROOF: FOMO Section
                HStack(spacing: 8) {
                    // Avatar pile
                    HStack(spacing: -8) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: ["#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A"][index]),
                                            Color(hex: ["#FF8E8E", "#6FE0D8", "#67C9E3", "#FFBC9C"][index])
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "#1e3a8a"), lineWidth: 2)
                                )
                        }
                    }

                    Text("Users entered this week")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Spacer()

                    // Your entries badge
                    if userEntries > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.billixMoneyGreen)

                            Text("You: \(userEntries)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
        }
        .cornerRadius(20)
        .shadow(color: .purple.opacity(0.4), radius: 20, x: 0, y: 10)
    }

    // MARK: - Coming Soon Overlay

    private var comingSoonOverlay: some View {
        ZStack {
            // Semi-transparent dark overlay
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))

            VStack(spacing: 16) {
                // Icon
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.billixArcadeGold)

                // Coming Soon text
                Text("COMING SOON")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2)

                // Description
                Text("Weekly Sweepstakes")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Text("Win $50 off your bill every week")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(24)
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
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                if Task.isCancelled { break }
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    calculateTimeRemaining()
                }
            }
        }
    }

    func startShimmer() {
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 400
        }
    }

    func formatTimeRemaining() -> String {
        let days = Int(timeRemaining) / 86400
        let hours = (Int(timeRemaining) % 86400) / 3600

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "Soon"
        }
    }
}

// MARK: - Confetti Pattern

struct ConfettiPattern: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<30) { index in
                let randomX = CGFloat.random(in: 0...geometry.size.width)
                let randomY = CGFloat.random(in: 0...geometry.size.height)
                let randomRotation = Double.random(in: 0...360)
                let shapes = ["triangle.fill", "circle.fill", "diamond.fill", "star.fill"]
                let randomShape = shapes[index % shapes.count]

                Image(systemName: randomShape)
                    .font(.system(size: CGFloat.random(in: 8...16)))
                    .foregroundColor(.white.opacity(Double.random(in: 0.1...0.3)))
                    .rotationEffect(.degrees(randomRotation))
                    .position(x: randomX, y: randomY)
            }
        }
    }
}

// MARK: - Pulse Button Style

struct PulseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Premium Eligible") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        ScrollView {
            WeeklyGiveawayCard(
                userEntries: 5,
                totalEntries: 1240,
                currentTier: .silver,
                isComingSoon: false,
                onBuyEntries: {},
                onHowToEarn: {}
            )
            .padding(.top, 20)
        }
    }
}

#Preview("Coming Soon") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        ScrollView {
            WeeklyGiveawayCard(
                userEntries: 0,
                totalEntries: 0,
                currentTier: .bronze,
                isComingSoon: true,
                onBuyEntries: {},
                onHowToEarn: {}
            )
            .padding(.top, 20)
        }
    }
}
