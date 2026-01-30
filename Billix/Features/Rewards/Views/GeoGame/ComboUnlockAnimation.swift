//
//  ComboUnlockAnimation.swift
//  Billix
//
//  Created by Claude Code
//  Center-screen celebration animation when player unlocks a combo multiplier
//

import SwiftUI

struct ComboUnlockAnimation: View {

    let comboStreak: Int
    let onComplete: () -> Void

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var animationTask: Task<Void, Never>?

    var multiplier: Double {
        // Combo system removed - return 1.0 (this view is no longer used)
        return 1.0
    }

    var multiplierText: String {
        String(format: "%.0f", multiplier)
    }

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.orange.opacity(0.6), .red.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .opacity(glowOpacity)
                .blur(radius: 20)

            VStack(spacing: 12) {
                // Fire icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .shadow(color: .orange.opacity(0.8), radius: 10)

                // Combo text
                Text("\(comboStreak)X COMBO!")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                // Multiplier badge
                HStack(spacing: 4) {
                    Text("\(multiplierText)X")
                        .font(.system(size: 24, weight: .bold))
                    Text("POINTS")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .orange.opacity(0.5), radius: 10, y: 4)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            performAnimation()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }

    private func performAnimation() {
        // Phase 1: Appear and grow (0.0 - 0.4s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
            glowOpacity = 1.0
        }

        // Phase 2-4: Sequential animations
        animationTask = Task { @MainActor in
            // Phase 2: Pulse (0.6s - 1.2s)
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeInOut(duration: 0.3).repeatCount(2, autoreverses: true)) {
                scale = 1.1
                glowOpacity = 0.7
            }

            // Phase 3: Shrink and fade out (1.5s - 1.8s)
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                scale = 0.3
                opacity = 0
                glowOpacity = 0
            }

            // Complete and dismiss (2.0s)
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            onComplete()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            ComboUnlockAnimation(comboStreak: 2) {
            }
        }
    }
}
