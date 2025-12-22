//
//  HealthBarView.swift
//  Billix
//
//  Created by Claude Code
//  Displays health/lives as hearts (❤️ and 🖤)
//

import SwiftUI

struct HealthBarView: View {

    let currentHealth: Int
    let maxHealth: Int = 3

    @State private var shake: CGFloat = 0
    @State private var previousHealth: Int?
    @State private var heartScales: [CGFloat] = [1.0, 1.0, 1.0]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxHealth, id: \.self) { index in
                Image(systemName: index < currentHealth ? "heart.fill" : "heart")
                    .font(.system(size: 18))
                    .foregroundColor(index < currentHealth ? .red : .gray.opacity(0.3))
                    .scaleEffect((index < currentHealth ? 1.0 : 0.8) * heartScales[index])
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentHealth)
                    .shadow(color: index < currentHealth ? .red.opacity(0.5) : .clear, radius: 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
        )
        .offset(x: shake)
        .onChange(of: currentHealth) { oldValue, newValue in
            // Trigger animations when health decreases
            if let prev = previousHealth, newValue < prev {
                // Shake animation
                withAnimation(.linear(duration: 0.1).repeatCount(3, autoreverses: true)) {
                    shake = 5
                }

                // Pulse out the lost heart
                let lostHeartIndex = newValue  // The heart that was just lost
                withAnimation(.easeOut(duration: 0.2)) {
                    heartScales[lostHeartIndex] = 1.5
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeIn(duration: 0.1)) {
                        heartScales[lostHeartIndex] = 1.0
                    }
                }

                // Haptic feedback for heart loss
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)

                // Reset shake after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shake = 0
                }
            } else if let prev = previousHealth, newValue > prev {
                // Heart gained - pulse in the new heart
                let gainedHeartIndex = newValue - 1
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    heartScales[gainedHeartIndex] = 1.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        heartScales[gainedHeartIndex] = 1.0
                    }
                }
            }
            previousHealth = newValue
        }
        .onAppear {
            previousHealth = currentHealth
            // Pulse animation for active hearts
            startHeartbeatAnimation()
        }
    }

    private func startHeartbeatAnimation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            guard currentHealth > 0 else { return }

            // Subtle heartbeat for all active hearts
            for i in 0..<currentHealth {
                withAnimation(.easeInOut(duration: 0.15)) {
                    heartScales[i] = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        heartScales[i] = 1.0
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            HealthBarView(currentHealth: 3)
            HealthBarView(currentHealth: 2)
            HealthBarView(currentHealth: 1)
            HealthBarView(currentHealth: 0)
        }
    }
}
