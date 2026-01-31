import SwiftUI

struct AnimatedBackground: View {
    @State private var coins: [FloatingCoin] = []

    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: [
                    Color.billixMoneyGreen,
                    Color.billixMoneyGreen.opacity(0.85),
                    Color.billixDarkTeal.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating coins
            ForEach(coins) { coin in
                CoinView(coin: coin)
            }

            // Subtle pattern overlay
            GeometryReader { geometry in
                Path { path in
                    let rows = 20
                    let cols = 10
                    let cellWidth = geometry.size.width / CGFloat(cols)
                    let cellHeight = geometry.size.height / CGFloat(rows)

                    for row in 0..<rows {
                        for col in 0..<cols {
                            if (row + col) % 3 == 0 {
                                let x = CGFloat(col) * cellWidth
                                let y = CGFloat(row) * cellHeight
                                path.addEllipse(in: CGRect(x: x, y: y, width: 3, height: 3))
                            }
                        }
                    }
                }
                .fill(Color.billixGoldenAmber.opacity(0.05))
            }
        }
        .onAppear {
            generateCoins()
        }
    }

    private func generateCoins() {
        coins = (0..<12).map { index in
            FloatingCoin(
                id: UUID(),
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 20...50),
                duration: Double.random(in: 15...25),
                delay: Double(index) * 0.5,
                isGold: index % 3 == 0
            )
        }
    }
}

struct FloatingCoin: Identifiable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let duration: Double
    let delay: Double
    let isGold: Bool
}

struct CoinView: View {
    let coin: FloatingCoin
    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0.1
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            CoinShape()
                .fill(
                    LinearGradient(
                        colors: coin.isGold ? [
                            Color.billixGoldenAmber,
                            Color.billixGold,
                            Color.billixGoldenAmber
                        ] : [
                            Color.billixCopper,
                            Color.billixCopper.opacity(0.8),
                            Color.billixCopper
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: coin.size, height: coin.size)
                .overlay(
                    CoinShape()
                        .stroke(
                            coin.isGold ? Color.billixGold : Color.billixCopper.opacity(0.6),
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: (coin.isGold ? Color.billixGoldenAmber : Color.billixCopper).opacity(0.3),
                    radius: 5,
                    x: 0,
                    y: 2
                )
                .opacity(opacity)
                .rotationEffect(.degrees(rotation))
                .position(
                    x: coin.x * geometry.size.width,
                    y: coin.y * geometry.size.height + offset
                )
                .onAppear {
                    isAnimating = true
                    withAnimation(
                        .linear(duration: coin.duration)
                        .repeatForever(autoreverses: false)
                        .delay(coin.delay)
                    ) {
                        if isAnimating {
                            offset = -geometry.size.height - 100
                        }
                    }

                    withAnimation(
                        .linear(duration: coin.duration / 2)
                        .repeatForever(autoreverses: true)
                        .delay(coin.delay)
                    ) {
                        if isAnimating {
                            rotation = 360
                        }
                    }

                    withAnimation(
                        .easeInOut(duration: 2)
                        .delay(coin.delay)
                    ) {
                        if isAnimating {
                            opacity = coin.isGold ? 0.2 : 0.15
                        }
                    }
                }
                .onDisappear {
                    isAnimating = false
                    offset = 0
                    rotation = 0
                    opacity = 0.1
                }
        }
    }
}

// MARK: - Particle Effects

struct MoneyParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var symbol: String
}

struct MoneyParticlesEffect: View {
    @State private var particles: [MoneyParticle] = []
    let trigger: Bool

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Text(particle.symbol)
                    .font(.system(size: 20))
                    .foregroundColor(particle.symbol == "$" ? .billixGoldenAmber : .billixGold)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onChange(of: trigger) { _, _ in
            generateParticles()
        }
    }

    private func generateParticles() {
        particles = (0..<20).map { index in
            MoneyParticle(
                x: CGFloat.random(in: 50...350),
                y: CGFloat.random(in: 100...400),
                scale: 1.0,
                opacity: 1.0,
                symbol: index % 2 == 0 ? "$" : "💰"
            )
        }

        for index in particles.indices {
            withAnimation(
                .easeOut(duration: 1.5)
                .delay(Double(index) * 0.05)
            ) {
                particles[index].y -= CGFloat.random(in: 50...150)
                particles[index].scale = 0.5
                particles[index].opacity = 0
            }
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            particles.removeAll()
        }
    }
}
