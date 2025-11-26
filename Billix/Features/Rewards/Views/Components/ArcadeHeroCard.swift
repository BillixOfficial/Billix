//
//  ArcadeHeroCard.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Zone B: Daily Price Guessr game entry card
//

import SwiftUI

struct ArcadeHeroCard: View {
    let game: DailyGame?
    let result: GameResult?
    let hasPlayedToday: Bool
    let timeRemaining: String
    let onPlay: () -> Void

    @State private var isPulsing = false
    @State private var showGameInfo = false

    var body: some View {
        ZStack {
            // Background with gradient and decorative elements
            backgroundLayer

            // Content
            VStack(alignment: .leading, spacing: 0) {
                // Top: Category badge and info
                HStack {
                    categoryBadge

                    Spacer()

                    // Info button
                    Button {
                        showGameInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .popover(isPresented: $showGameInfo, arrowEdge: .top) {
                        GameInfoPopover()
                            .presentationCompactAdaptation(.popover)
                    }
                }
                .padding(.bottom, 16)

                // Title and Subject
                VStack(alignment: .leading, spacing: 6) {
                    Text("Daily Price Guessr")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    if let game = game {
                        Text("Guess the price of **\(game.subject)**")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                            Text(game.location)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                // Bottom: Action area
                HStack {
                    if hasPlayedToday, let result = result {
                        // Played state - show result
                        playedStateView(result: result)
                    } else {
                        // Unplayed state - show CTA
                        unplayedStateView
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .billixGamePurple.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            if !hasPlayedToday {
                isPulsing = true
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Main gradient
            LinearGradient(
                colors: [
                    Color.billixGamePurple,
                    Color.billixGamePurple.opacity(0.8),
                    Color(hex: "#6366F1")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .offset(x: geometry.size.width - 80, y: -40)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .offset(x: geometry.size.width - 50, y: 80)

                Circle()
                    .fill(Color.billixArcadeGold.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .offset(x: -20, y: geometry.size.height - 40)
            }

            // Category-specific illustration on the right
            GeometryReader { geometry in
                categoryIllustration
                    .offset(x: geometry.size.width - 100, y: 20)
            }
        }
    }

    // MARK: - Category Illustration

    private var categoryIllustration: some View {
        ZStack {
            // Glowing backdrop
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)

            // Main illustration based on category
            if let game = game {
                switch game.category {
                case .grocery:
                    GroceryIllustration()
                case .rent:
                    RentIllustration()
                case .utility:
                    UtilityIllustration()
                case .subscription:
                    SubscriptionIllustration()
                case .gas:
                    GasIllustration()
                }
            } else {
                // Default illustration
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }

    // MARK: - Category Badge

    private var categoryBadge: some View {
        HStack(spacing: 6) {
            if let game = game {
                Image(systemName: game.category.icon)
                    .font(.system(size: 11, weight: .semibold))

                Text(game.category.rawValue)
                    .font(.system(size: 11, weight: .semibold))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.2))
        )
    }

    // MARK: - Unplayed State

    private var unplayedStateView: some View {
        HStack {
            // Reward badge
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.billixArcadeGold)

                Text("Win up to 100 pts")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.2))
            )

            Spacer()

            // Play button with pulse
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onPlay()
            }) {
                ZStack {
                    // Pulsing ring
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 56, height: 56)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .opacity(isPulsing ? 0 : 1)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: isPulsing)

                    // Button
                    HStack(spacing: 6) {
                        Text("Play")
                            .font(.system(size: 15, weight: .bold))

                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.billixGamePurple)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.white)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.95))
        }
    }

    // MARK: - Played State

    private func playedStateView(result: GameResult) -> some View {
        HStack {
            // Score display
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Score:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Text("\(result.accuracyPercentage)/100")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.billixArcadeGold)

                    Text("+\(result.pointsEarned) pts")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.billixArcadeGold)
                }
            }

            Spacer()

            // Countdown
            VStack(alignment: .trailing, spacing: 4) {
                Text("Next game in")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))

                    Text(timeRemaining)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                )
            }
        }
    }
}

// MARK: - Game Info Popover

struct GameInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Play")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.billixDarkGreen)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "1.circle.fill", text: "Guess the price using the slider")
                InfoRow(icon: "2.circle.fill", text: "Lock in your guess")
                InfoRow(icon: "3.circle.fill", text: "See how close you were!")
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Scoring")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                HStack(spacing: 12) {
                    ScoreBadge(label: "Perfect", points: "100", color: .billixArcadeGold)
                    ScoreBadge(label: "Close", points: "50", color: .billixMoneyGreen)
                    ScoreBadge(label: "Miss", points: "10", color: .billixMediumGreen)
                }
            }
        }
        .padding(14)
        .frame(width: 240)
        .background(Color.white)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.billixGamePurple)

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.billixDarkGreen)
        }
    }
}

struct ScoreBadge: View {
    let label: String
    let points: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.billixMediumGreen)

            Text("+\(points)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Category Illustrations

struct GroceryIllustration: View {
    var body: some View {
        ZStack {
            // Shopping bag
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.25))
                .frame(width: 50, height: 55)
                .offset(y: 5)

            // Bag handle
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                .frame(width: 24, height: 16)
                .offset(y: -22)

            // Items peeking out
            VStack(spacing: 2) {
                // Carrot/vegetable
                Capsule()
                    .fill(Color.orange.opacity(0.6))
                    .frame(width: 8, height: 20)
                    .rotationEffect(.degrees(-15))
                    .offset(x: -10, y: -8)

                // Bread/baguette
                Capsule()
                    .fill(Color.yellow.opacity(0.5))
                    .frame(width: 6, height: 18)
                    .rotationEffect(.degrees(10))
                    .offset(x: 8, y: -12)
            }

            // Milk carton
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.4))
                .frame(width: 14, height: 22)
                .offset(x: 0, y: -5)
        }
    }
}

struct RentIllustration: View {
    var body: some View {
        ZStack {
            // Building base
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.25))
                .frame(width: 55, height: 60)
                .offset(y: 5)

            // Roof
            RoofTriangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 65, height: 20)
                .offset(y: -35)

            // Windows grid
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    WindowShape()
                    WindowShape()
                }
                HStack(spacing: 8) {
                    WindowShape()
                    WindowShape()
                }
            }
            .offset(y: 0)

            // Door
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.billixArcadeGold.opacity(0.5))
                .frame(width: 12, height: 18)
                .offset(y: 22)
        }
    }
}

struct UtilityIllustration: View {
    var body: some View {
        ZStack {
            // Light bulb outer
            Circle()
                .fill(Color.billixArcadeGold.opacity(0.3))
                .frame(width: 50, height: 50)

            // Light bulb inner glow
            Circle()
                .fill(Color.billixArcadeGold.opacity(0.5))
                .frame(width: 35, height: 35)

            // Bulb icon
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.9))

            // Rays
            ForEach(0..<6) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.billixArcadeGold.opacity(0.4))
                    .frame(width: 3, height: 12)
                    .offset(y: -38)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
        }
    }
}

struct SubscriptionIllustration: View {
    var body: some View {
        ZStack {
            // TV/Screen
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.2))
                .frame(width: 55, height: 40)

            // Screen content
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 33)

            // Play button
            Image(systemName: "play.fill")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))

            // Stand
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.2))
                .frame(width: 20, height: 8)
                .offset(y: 26)
        }
    }
}

struct GasIllustration: View {
    var body: some View {
        ZStack {
            // Pump body
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.25))
                .frame(width: 40, height: 55)

            // Display
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.green.opacity(0.4))
                .frame(width: 30, height: 15)
                .offset(y: -12)

            // Nozzle hook area
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                .frame(width: 20, height: 20)
                .offset(x: 25, y: -5)

            // Hose
            Path { path in
                path.move(to: CGPoint(x: 20, y: 0))
                path.addQuadCurve(to: CGPoint(x: 40, y: -20),
                                  control: CGPoint(x: 35, y: 5))
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 4)

            // Dollar sign
            Text("$")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.billixArcadeGold.opacity(0.7))
                .offset(y: 15)
        }
    }
}

// Helper shapes
struct RoofTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct WindowShape: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.cyan.opacity(0.4))
            .frame(width: 12, height: 12)
    }
}

// MARK: - Preview

#Preview("Unplayed") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        ArcadeHeroCard(
            game: .preview,
            result: nil,
            hasPlayedToday: false,
            timeRemaining: "14h 20m",
            onPlay: {}
        )
        .padding(20)
    }
}

#Preview("Played") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        ArcadeHeroCard(
            game: .preview,
            result: .preview,
            hasPlayedToday: true,
            timeRemaining: "14h 20m",
            onPlay: {}
        )
        .padding(20)
    }
}
