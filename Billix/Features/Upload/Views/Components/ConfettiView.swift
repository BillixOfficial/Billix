//
//  ConfettiView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

/// A celebratory confetti animation view
/// Shows particles falling/exploding based on the result type
struct ConfettiView: View {
    let isActive: Bool
    let type: ConfettiType

    @State private var particles: [ConfettiParticle] = []

    enum ConfettiType {
        case celebration // Green/gold for good results
        case warning     // Red/orange for overpaying
        case neutral     // Blue for average

        var colors: [Color] {
            switch self {
            case .celebration:
                return [.billixMoneyGreen, .billixSavingsYellow, .billixChartGreen, .green, .yellow]
            case .warning:
                return [.red, .orange, .billixPendingOrangeText, .pink]
            case .neutral:
                return [.billixChartBlue, .billixActiveBlueText, .blue, .cyan]
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiParticleView(particle: particle)
                }
            }
            .onAppear {
                if isActive {
                    createParticles(in: geometry.size)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    createParticles(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<50).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                color: type.colors.randomElement() ?? .billixMoneyGreen,
                shape: ConfettiShape.allCases.randomElement() ?? .circle,
                size: CGFloat.random(in: 6...14),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.5)
            )
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let shape: ConfettiShape
    let size: CGFloat
    let rotation: Double
    let delay: Double
}

enum ConfettiShape: CaseIterable {
    case circle
    case rectangle
    case triangle
}

struct ConfettiParticleView: View {
    let particle: ConfettiParticle

    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1

    var body: some View {
        particleShape
            .frame(width: particle.size, height: particle.shape == .rectangle ? particle.size * 0.5 : particle.size)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .opacity(opacity)
            .position(x: particle.x + offsetX, y: particle.y + offsetY)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 2.5)
                    .delay(particle.delay)
                ) {
                    offsetY = UIScreen.main.bounds.height + 100
                    offsetX = CGFloat.random(in: -100...100)
                    rotation = particle.rotation + Double.random(in: 360...720)
                }
                withAnimation(
                    .easeIn(duration: 1.5)
                    .delay(particle.delay + 1.0)
                ) {
                    opacity = 0
                }
                withAnimation(
                    .easeOut(duration: 0.3)
                    .delay(particle.delay)
                ) {
                    scale = 1.2
                }
            }
    }

    @ViewBuilder
    private var particleShape: some View {
        switch particle.shape {
        case .circle:
            Circle()
                .fill(particle.color)
        case .rectangle:
            RoundedRectangle(cornerRadius: 2)
                .fill(particle.color)
        case .triangle:
            Triangle()
                .fill(particle.color)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Animated comparison bar for results
struct AnimatedComparisonBar: View {
    let userAmount: Double
    let averageAmount: Double
    var height: CGFloat = 12
    var cornerRadius: CGFloat = 6

    @State private var animatedUserProgress: CGFloat = 0
    @State private var animatedAvgProgress: CGFloat = 0

    private var maxAmount: Double {
        max(userAmount, averageAmount) * 1.2
    }

    private var userProgress: CGFloat {
        CGFloat(userAmount / maxAmount)
    }

    private var avgProgress: CGFloat {
        CGFloat(averageAmount / maxAmount)
    }

    private var isOverpaying: Bool {
        userAmount > averageAmount * 1.1
    }

    private var isUnderpaying: Bool {
        userAmount < averageAmount * 0.9
    }

    var body: some View {
        VStack(spacing: 16) {
            // User's amount bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Your Bill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixDarkGreen)
                    Spacer()
                    Text(String(format: "$%.2f", userAmount))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(barColor)
                        .contentTransition(.numericText())
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.billixMoneyGreen.opacity(0.1))

                        // Progress bar with solid color
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(barColor)
                            .frame(width: geometry.size.width * animatedUserProgress)
                    }
                }
                .frame(height: height)
            }

            // Billix average bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Billix Average")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "$%.2f", averageAmount))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(.systemGray5))

                        // Progress
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(.systemGray3))
                            .frame(width: geometry.size.width * animatedAvgProgress)

                        // Marker line
                        Rectangle()
                            .fill(Color.billixDarkGreen.opacity(0.5))
                            .frame(width: 2)
                            .offset(x: geometry.size.width * animatedAvgProgress - 1)
                    }
                }
                .frame(height: height)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animatedUserProgress = userProgress
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4)) {
                animatedAvgProgress = avgProgress
            }
        }
    }

    private var barColor: Color {
        if isOverpaying { return .statusOverpaying }
        if isUnderpaying { return .statusUnderpaying }
        return .statusNeutral
    }
}

/// Animated counting number display
struct AnimatedNumber: View {
    let value: Double
    var prefix: String = "$"
    var decimals: Int = 2
    var duration: Double = 1.0
    var font: Font = .system(size: 32, weight: .bold, design: .rounded)
    var color: Color = .billixDarkGreen

    @State private var displayValue: Double = 0

    var body: some View {
        Text("\(prefix)\(formattedValue)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = value
                }
            }
    }

    private var formattedValue: String {
        String(format: "%.\(decimals)f", displayValue)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Confetti types
        ZStack {
            Color.billixLightGreen
            ConfettiView(isActive: true, type: .celebration)
        }
        .frame(height: 200)
        .cornerRadius(20)

        // Comparison bar
        AnimatedComparisonBar(
            userAmount: 145.50,
            averageAmount: 125.00
        )
        .padding()

        // Animated number
        AnimatedNumber(value: 145.50, color: .red)
    }
    .padding()
}
