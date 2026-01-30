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
    @State private var isAnimating = false

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
                isAnimating = true
                startAnimations()
            }
            .onDisappear {
                isAnimating = false
                // Reset state to stop animations
                yOffset = 0
                xOffset = 0
                opacity = 0.0
            }
    }

    private func startAnimations() {
        guard isAnimating else { return }

        // Upward drift
        withAnimation(
            .linear(duration: duration)
            .repeatForever(autoreverses: false)
            .delay(delay)
        ) {
            if isAnimating {
                yOffset = -(geometry.size.height + 40)
            }
        }

        // Horizontal waver (sine wave effect)
        withAnimation(
            .easeInOut(duration: duration / 3)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            if isAnimating {
                xOffset = waveAmplitude
            }
        }

        // Fade in/out
        withAnimation(
            .easeIn(duration: 1.0)
            .delay(delay)
        ) {
            if isAnimating {
                opacity = finalOpacity
            }
        }

        // Fade out at the end
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((delay + duration - 1.5) * 1_000_000_000))
            guard isAnimating else { return }
            withAnimation(.easeOut(duration: 1.5)) {
                opacity = 0.0
            }
        }

        // Restart particle after it completes
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((delay + duration + 0.5) * 1_000_000_000))
            guard isAnimating else { return }
            restartParticle()
        }
    }

    private func restartParticle() {
        guard isAnimating else { return }

        // Reset to starting position
        yOffset = 0
        xOffset = 0
        opacity = 0.0

        // Restart animations
        withAnimation(
            .linear(duration: duration)
            .repeatForever(autoreverses: false)
        ) {
            if isAnimating {
                yOffset = -(geometry.size.height + 40)
            }
        }

        withAnimation(
            .easeInOut(duration: duration / 3)
            .repeatForever(autoreverses: true)
        ) {
            if isAnimating {
                xOffset = waveAmplitude
            }
        }

        withAnimation(.easeIn(duration: 1.0)) {
            if isAnimating {
                opacity = finalOpacity
            }
        }

        // Schedule fade out
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((duration - 1.5) * 1_000_000_000))
            guard isAnimating else { return }
            withAnimation(.easeOut(duration: 1.5)) {
                opacity = 0.0
            }
        }

        // Schedule next restart
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((duration + 0.5) * 1_000_000_000))
            guard isAnimating else { return }
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
