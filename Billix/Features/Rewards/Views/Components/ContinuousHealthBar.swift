//
//  ContinuousHealthBar.swift
//  Billix
//
//  Created by Claude Code
//  Continuous health bar for Price Guessr game with integrated timer badge
//  Replaces discrete hearts for 30-question session system
//

import SwiftUI

struct ContinuousHealthBar: View {
    @ObservedObject var viewModel: GeoGameViewModel

    // Timer properties
    var timeRemaining: Double {
        viewModel.timeRemaining
    }

    var timerColor: Color {
        if timeRemaining <= 5 {
            return .red
        } else if timeRemaining <= 10 {
            return .orange
        } else {
            return .billixMoneyGreen
        }
    }

    var shouldPulse: Bool {
        timeRemaining <= 5
    }

    // Health properties
    var healthPercentage: Double {
        // Convert discrete hearts (0-3) to continuous percentage (0-100)
        Double(viewModel.session.health) / 3.0 * 100.0
    }

    var healthGradient: LinearGradient {
        let colors: [Color]

        if healthPercentage > 50 {
            colors = [.billixMoneyGreen, .billixMoneyGreen]
        } else if healthPercentage > 20 {
            colors = [.orange, .orange]
        } else {
            colors = [.red, .red]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                // Health fill (green→orange→red gradient)
                RoundedRectangle(cornerRadius: 4)
                    .fill(healthGradient)
                    .frame(width: calculateBarWidth(totalWidth: geometry.size.width), height: 8)
                    .animation(.easeInOut(duration: 0.3), value: healthPercentage)

                // Timer badge (center overlay)
                CompactTimerBadge(
                    timeRemaining: timeRemaining,
                    color: timerColor,
                    shouldPulse: shouldPulse
                )
                .position(x: geometry.size.width / 2, y: 4)
            }
        }
        .frame(height: 36)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health: \(Int(healthPercentage)) percent")
        .accessibilityValue(healthStatusText)
        .onChange(of: healthPercentage) { oldValue, newValue in
            announceHealthChange(from: oldValue, to: newValue)
        }
    }

    // MARK: - Helper Methods

    private func calculateBarWidth(totalWidth: CGFloat) -> CGFloat {
        return (healthPercentage / 100.0) * totalWidth
    }

    private var healthStatusText: String {
        if healthPercentage > 50 {
            return "Healthy"
        } else if healthPercentage > 20 {
            return "Low"
        } else {
            return "Critical"
        }
    }

    private func announceHealthChange(from oldValue: Double, to newValue: Double) {
        // Announce critical health state to VoiceOver users
        if newValue <= 20 && oldValue > 20 {
            UIAccessibility.post(
                notification: .announcement,
                argument: "Health critical"
            )
        }
    }
}

// MARK: - Preview

#Preview("Continuous Health Bar - Various States") {
    VStack(spacing: 40) {
        // High health (green)
        ContinuousHealthBar(viewModel: GeoGameViewModel())
            .padding(.horizontal, 20)

        // Medium health (orange)
        ContinuousHealthBar(viewModel: {
            let vm = GeoGameViewModel()
            vm.session.health = 1  // 33%
            return vm
        }())
        .padding(.horizontal, 20)

        // Low health (red)
        ContinuousHealthBar(viewModel: {
            let vm = GeoGameViewModel()
            vm.session.health = 0  // 0%
            return vm
        }())
        .padding(.horizontal, 20)
    }
    .padding(.vertical, 40)
    .background(Color.black.opacity(0.8))
}
