//
//  StreakCounter.swift
//  Billix
//
//  Streak counter badge for rewards header
//  Shows daily play streak with fire emoji and at-risk pulsing
//

import SwiftUI

struct StreakCounter: View {
    let streakCount: Int
    let isAtRisk: Bool  // < 2 hours until midnight
    let onTap: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                // Fire emoji
                Text("🔥")
                    .font(.system(size: 14))
                    .scaleEffect(isPulsing ? 1.1 : 1.0)

                // Streak count
                Text("\(streakCount)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isAtRisk ? .billixStreakOrange : .white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        isAtRisk ?
                        Color.billixStreakOrange.opacity(0.25) :
                        Color.billixStreakOrange
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.billixStreakOrange, lineWidth: isAtRisk ? 2 : 0)
                    )
            )
            .shadow(
                color: .billixStreakOrange.opacity(isPulsing ? 0.6 : 0.3),
                radius: isPulsing ? 8 : 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
        .onAppear {
            if isAtRisk {
                // Pulse animation when streak is at risk
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Active Streak") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack(spacing: 20) {
            StreakCounter(streakCount: 7, isAtRisk: false, onTap: {})
            StreakCounter(streakCount: 23, isAtRisk: false, onTap: {})
        }
    }
}

#Preview("At Risk") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        StreakCounter(streakCount: 12, isAtRisk: true, onTap: {})
    }
}
