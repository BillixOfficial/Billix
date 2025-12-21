//
//  ComboStreakView.swift
//  Billix
//
//  Created by Claude Code
//  Displays combo streak badge when user gets 2+ questions correct in a row
//

import SwiftUI

struct ComboStreakView: View {

    let comboStreak: Int

    var multiplier: Double {
        GeoGameScoring.calculateComboMultiplier(comboStreak)
    }

    var isVisible: Bool {
        comboStreak >= 2
    }

    var body: some View {
        if isVisible {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)

                Text("\(comboStreak)x")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)

                Text("(\(String(format: "%.0f", multiplier * 100))%)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
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
            .shadow(color: .orange.opacity(0.5), radius: 6, y: 2)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: comboStreak)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            ComboStreakView(comboStreak: 0)  // Not visible
            ComboStreakView(comboStreak: 2)  // 1.25x (125%)
            ComboStreakView(comboStreak: 4)  // 1.5x (150%)
            ComboStreakView(comboStreak: 6)  // 2.0x (200%)
        }
    }
}
