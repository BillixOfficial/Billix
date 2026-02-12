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

    // Read tab active state from environment to pause animations when tab is hidden
    @Environment(\.isRewardsTabActive) private var isTabActive

    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 0.0

    // Randomized properties (computed once at init)
    private let size: CGFloat
    private let startX: CGFloat
    private let startY: CGFloat
    private let duration: Double
    private let waveAmplitude: CGFloat
    private let finalOpacity: Double

    init(geometry: GeometryProxy, color: Color, delay: Double) {
        self.geometry = geometry
        self.color = color
        self.delay = delay

        // Random starting position - computed once
        self.size = CGFloat.random(in: 4...6)
        self.startX = CGFloat.random(in: 0...geometry.size.width)
        self.startY = geometry.size.height + 20 // Start below view
        self.duration = Double.random(in: 6...10)
        self.waveAmplitude = CGFloat.random(in: 5...15)
        self.finalOpacity = Double.random(in: 0.15...0.25)
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
            .task(id: isTabActive) {
                // Only run animations when tab is active
                guard isTabActive else {
                    PerformanceMonitor.shared.taskCancelled("animationLoop", in: "FloatingParticle-\(delay) (tab inactive)")
                    // Reset state when tab becomes inactive
                    yOffset = 0
                    xOffset = 0
                    opacity = 0.0
                    return
                }

                PerformanceMonitor.shared.viewAppeared("FloatingParticle-\(delay)")
                PerformanceMonitor.shared.taskStarted("animationLoop", in: "FloatingParticle-\(delay)")

                // Use structured concurrency - all child tasks automatically cancelled when this task is cancelled
                await withTaskGroup(of: Void.self) { group in
                    // Initial delay before starting
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                    // Main animation loop task
                    group.addTask { @MainActor in
                        while !Task.isCancelled {
                            // Reset position for new cycle
                            yOffset = 0
                            xOffset = 0
                            opacity = 0.0

                            guard !Task.isCancelled else { return }

                            // Start upward drift animation
                            withAnimation(.linear(duration: duration)) {
                                yOffset = -(geometry.size.height + 40)
                            }

                            // Fade in
                            withAnimation(.easeIn(duration: 1.0)) {
                                opacity = finalOpacity
                            }

                            // Wait until near end of animation for fade out
                            try? await Task.sleep(nanoseconds: UInt64((duration - 1.5) * 1_000_000_000))
                            guard !Task.isCancelled else { return }

                            // Fade out
                            withAnimation(.easeOut(duration: 1.5)) {
                                opacity = 0.0
                            }

                            // Wait for animation to complete before restarting
                            try? await Task.sleep(nanoseconds: UInt64(2.0 * 1_000_000_000))
                        }
                    }

                    // Wave animation task (horizontal movement)
                    group.addTask { @MainActor in
                        var goingRight = true
                        while !Task.isCancelled {
                            withAnimation(.easeInOut(duration: duration / 6)) {
                                xOffset = goingRight ? waveAmplitude : -waveAmplitude
                            }
                            goingRight.toggle()
                            try? await Task.sleep(nanoseconds: UInt64((duration / 6) * 1_000_000_000))
                        }
                    }
                }

                PerformanceMonitor.shared.taskCancelled("animationLoop", in: "FloatingParticle-\(delay)")
            }
            .onDisappear {
                PerformanceMonitor.shared.viewDisappeared("FloatingParticle-\(delay)")
                // Reset state
                yOffset = 0
                xOffset = 0
                opacity = 0.0
            }
    }
}

// MARK: - Preview

#Preview("Floating Particles") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "#1e3d40"), Color(hex: "#2d5a5e")],
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
