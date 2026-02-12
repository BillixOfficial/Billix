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
                // Top: Badge
                HStack {
                    rewardBadge

                    Spacer()
                }
                .padding(.bottom, 16)

                // Large Title
                Text("Daily Price\nGuessr")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .lineSpacing(2)
                    .padding(.bottom, 8)

                // Subtitle
                if let game = game {
                    Text("Can you guess the price of\n**\(game.subject)**?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                } else {
                    Text("Can you guess the price of\n**[Today's Item]**?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }

                Spacer()

                // Bottom: Action area
                HStack {
                    if hasPlayedToday, let result = result {
                        // Played state - show result
                        playedStateView(result: result)
                    } else {
                        // Unplayed state - show CTA
                        playButton
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
            // Main gradient - darker navy/purple
            LinearGradient(
                colors: [
                    Color(hex: "#1e3d40"),
                    Color(hex: "#2d5a5e"),
                    Color(hex: "#3a6e6e")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative elements on the right
            GeometryReader { geometry in
                // Bar chart visualization
                HStack(alignment: .bottom, spacing: 4) {
                    BarColumn(height: 30, colors: [Color(hex: "#3b82f6"), Color(hex: "#60a5fa")])
                    BarColumn(height: 45, colors: [Color(hex: "#8b5cf6"), Color(hex: "#a78bfa")])
                    BarColumn(height: 25, colors: [Color(hex: "#ec4899"), Color(hex: "#f472b6")])
                    BarColumn(height: 50, colors: [Color(hex: "#3b82f6"), Color(hex: "#60a5fa")])
                    BarColumn(height: 35, colors: [Color(hex: "#8b5cf6"), Color(hex: "#a78bfa")])
                }
                .frame(width: 120, height: 60)
                .opacity(0.6)
                .offset(x: geometry.size.width - 150, y: geometry.size.height / 2 - 30)

                // Trending arrow
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#3b82f6").opacity(0.7))
                    .offset(x: geometry.size.width - 40, y: geometry.size.height / 2 - 50)
            }

            // Floating coins
            GeometryReader { geometry in
                ForEach(0..<6, id: \.self) { index in
                    CoinView()
                        .offset(
                            x: coinPositions[index].x * geometry.size.width,
                            y: coinPositions[index].y * geometry.size.height
                        )
                }
            }

            // Price tag icons
            GeometryReader { geometry in
                PriceTagIcon(rotation: -15)
                    .offset(x: geometry.size.width - 60, y: 20)

                PriceTagIcon(rotation: 10)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 50)
            }
        }
    }

    // Coin positions (percentage of width/height)
    private let coinPositions: [(x: CGFloat, y: CGFloat)] = [
        (0.15, 0.1),
        (0.75, 0.05),
        (0.85, 0.3),
        (0.2, 0.7),
        (0.65, 0.75),
        (0.9, 0.85)
    ]

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

    // MARK: - Reward Badge

    private var rewardBadge: some View {
        Text("WIN UP TO 200 PTS")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Color(hex: "#1e3d40"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.billixArcadeGold)
            )
    }

    // MARK: - Play Button

    private var playButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onPlay()
        }) {
            HStack(spacing: 6) {
                Text("PLAY NOW")
                    .font(.system(size: 15, weight: .bold))

                Image(systemName: "play.fill")
                    .font(.system(size: 12))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#3b82f6"), Color(hex: "#2563eb")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: Color(hex: "#3b82f6").opacity(0.5), radius: 12, y: 6)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
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

// MARK: - Decorative Components

struct CoinView: View {
    // Read tab active state from environment to pause animations when tab is hidden
    @Environment(\.isRewardsTabActive) private var isTabActive

    @State private var isAnimating = false
    @State private var isVisible = false

    var body: some View {
        ZStack {
            // Coin shadow
            Ellipse()
                .fill(Color.billixArcadeGold.opacity(0.3))
                .frame(width: 20, height: 20)
                .blur(radius: 2)
                .offset(y: 2)

            // Coin body
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.billixArcadeGold, Color(hex: "#d4a574")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(Color(hex: "#d4a574"), lineWidth: 1.5)
                )

            // Coin detail
            Text("$")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color(hex: "#1e3d40").opacity(0.6))
        }
        .rotationEffect(.degrees(isAnimating ? 360 : 0))
        .animation(isVisible && isTabActive ? .linear(duration: 8).repeatForever(autoreverses: false) : .default, value: isAnimating)
        .task(id: isTabActive) {
            // Only run animation when tab is active
            guard isTabActive else {
                PerformanceMonitor.shared.animationStopped("rotation", in: "CoinView (tab inactive)")
                isVisible = false
                isAnimating = false
                return
            }

            PerformanceMonitor.shared.viewAppeared("CoinView")
            PerformanceMonitor.shared.animationStarted("rotation", in: "CoinView")
            isVisible = true
            isAnimating = true
        }
        .onDisappear {
            PerformanceMonitor.shared.animationStopped("rotation", in: "CoinView")
            PerformanceMonitor.shared.viewDisappeared("CoinView")
            isVisible = false
            isAnimating = false
        }
    }
}

struct BarColumn: View {
    let height: CGFloat
    let colors: [Color]

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 12, height: height)
    }
}

struct PriceTagIcon: View {
    let rotation: Double

    var body: some View {
        ZStack {
            // Tag body
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.billixArcadeGold.opacity(0.25))
                .frame(width: 35, height: 45)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.billixArcadeGold.opacity(0.5), lineWidth: 2)
                )

            // Question mark
            Text("?")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white.opacity(0.8))

            // Hole for tag string
            Circle()
                .fill(Color(hex: "#1e3d40"))
                .frame(width: 6, height: 6)
                .offset(y: -16)
        }
        .rotationEffect(.degrees(rotation))
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

struct ArcadeHeroCard_Unplayed_Previews: PreviewProvider {
    static var previews: some View {
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
}

struct ArcadeHeroCard_Played_Previews: PreviewProvider {
    static var previews: some View {
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
}
