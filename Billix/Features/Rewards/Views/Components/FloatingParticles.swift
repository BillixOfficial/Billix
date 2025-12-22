//
//  FloatingParticles.swift
//  Billix
//
//  Created by Claude Code on 11/29/25.
//  Floating particle system for magical ambiance
//

import SwiftUI

struct FloatingParticlesBackground: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let particleCount: Int
    let colors: [Color]

    init(particleCount: Int = 7, colors: [Color] = [.white, Color.billixArcadeGold]) {
        self.particleCount = particleCount
        self.colors = colors
    }

    var body: some View {
        if !reduceMotion {
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<particleCount, id: \.self) { index in
                        FloatingParticle(
                            geometry: geometry,
                            color: colors.randomElement() ?? .white,
                            delay: Double(index) * 0.3
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Individual Floating Particle

struct FloatingParticle: View {
    let geometry: GeometryProxy
    let color: Color
    let delay: Double

    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 0.0

    // Randomized properties
    private let size: CGFloat = CGFloat.random(in: 4...6)
    private let startX: CGFloat
    private let startY: CGFloat
    private let duration: Double = Double.random(in: 6...10)
    private let waveAmplitude: CGFloat = CGFloat.random(in: 5...15)
    private let finalOpacity: Double = Double.random(in: 0.15...0.25)

    init(geometry: GeometryProxy, color: Color, delay: Double) {
        self.geometry = geometry
        self.color = color
        self.delay = delay

        // Random starting position
        self.startX = CGFloat.random(in: 0...geometry.size.width)
        self.startY = geometry.size.height + 20 // Start below view
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 1)
            .opacity(opacity)
            .position(
                x: startX + xOffset,
                y: startY + yOffset
            )
            .onAppear {
                // Upward drift
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    yOffset = -(geometry.size.height + 40)
                }

                // Horizontal waver (sine wave effect)
                withAnimation(
                    .easeInOut(duration: duration / 3)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    xOffset = waveAmplitude
                }

                // Fade in/out
                withAnimation(
                    .easeIn(duration: 1.0)
                    .delay(delay)
                ) {
                    opacity = finalOpacity
                }

                // Fade out at the end
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + duration - 1.5) {
                    withAnimation(.easeOut(duration: 1.5)) {
                        opacity = 0.0
                    }
                }

                // Restart particle after it completes
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + duration + 0.5) {
                    restartParticle()
                }
            }
    }

    private func restartParticle() {
        // Reset to starting position
        yOffset = 0
        xOffset = 0
        opacity = 0.0

        // Restart animations
        withAnimation(
            .linear(duration: duration)
            .repeatForever(autoreverses: false)
        ) {
            yOffset = -(geometry.size.height + 40)
        }

        withAnimation(
            .easeInOut(duration: duration / 3)
            .repeatForever(autoreverses: true)
        ) {
            xOffset = waveAmplitude
        }

        withAnimation(.easeIn(duration: 1.0)) {
            opacity = finalOpacity
        }

        // Schedule fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + duration - 1.5) {
            withAnimation(.easeOut(duration: 1.5)) {
                opacity = 0.0
            }
        }

        // Schedule next restart
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
            restartParticle()
        }
    }
}

// MARK: - Preview

#Preview("Floating Particles") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "#6B2DD6"), Color(hex: "#8B5CF6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        FloatingParticlesBackground(particleCount: 8)

        VStack {
            Spacer()
            Text("Floating Particles Demo")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text("Watch the subtle particles float upward")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
    }
}
