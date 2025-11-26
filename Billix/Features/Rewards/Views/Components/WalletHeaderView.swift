//
//  WalletHeaderView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Zone A: Sticky wallet header with point balance and slot-machine animation
//

import SwiftUI

struct WalletHeaderView: View {
    let points: Int
    let cashEquivalent: Double
    let onHistoryTapped: () -> Void

    @State private var animatedPoints: Int = 0
    @State private var showShimmer = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Points Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.billixArcadeGold, .billixPrizeOrange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: .billixArcadeGold.opacity(0.4), radius: 8, x: 0, y: 4)

                    Image(systemName: "star.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Points Balance
                VStack(alignment: .leading, spacing: 4) {
                    // Big rolling number
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(points)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.billixDarkGreen)
                            .contentTransition(.numericText(value: Double(points)))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: points)

                        Text("pts")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.billixMediumGreen)
                    }

                    // Cash equivalent
                    Text("≈ \(String(format: "$%.2f", cashEquivalent)) value")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                }

                Spacer()

                // History Button
                Button(action: onHistoryTapped) {
                    ZStack {
                        Circle()
                            .fill(Color.billixDarkGreen.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.billixDarkGreen)
                    }
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.9))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            Color.billixArcadeGold.opacity(0.15),
                            Color.billixPrizeOrange.opacity(0.08),
                            Color.billixLightGreen
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Decorative elements
                    GeometryReader { geometry in
                        Circle()
                            .fill(Color.billixArcadeGold.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .offset(x: geometry.size.width - 60, y: -30)

                        Circle()
                            .fill(Color.billixPrizeOrange.opacity(0.08))
                            .frame(width: 60, height: 60)
                            .offset(x: geometry.size.width - 40, y: 50)
                    }

                    // Bottom border
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.billixArcadeGold.opacity(0.3), .billixPrizeOrange.opacity(0.2), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 2)
                    }
                }
            )
        }
    }
}

// MARK: - Animated Points Text (Alternative to contentTransition)

struct RollingNumberView: View {
    let value: Int
    let font: Font
    let color: Color

    @State private var displayedValue: Int = 0

    var body: some View {
        Text("\(displayedValue)")
            .font(font)
            .foregroundColor(color)
            .onChange(of: value) { oldValue, newValue in
                animateValueChange(from: oldValue, to: newValue)
            }
            .onAppear {
                displayedValue = value
            }
    }

    private func animateValueChange(from oldValue: Int, to newValue: Int) {
        let difference = newValue - oldValue
        let steps = min(abs(difference), 30)
        let stepDuration: TimeInterval = 0.5 / Double(max(steps, 1))

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let progress = Double(i) / Double(max(steps, 1))
                let easedProgress = 1 - pow(1 - progress, 3) // Ease out cubic
                displayedValue = oldValue + Int(Double(difference) * easedProgress)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        WalletHeaderView(
            points: 1450,
            cashEquivalent: 14.50,
            onHistoryTapped: {}
        )

        Spacer()
    }
    .background(Color.billixLightGreen)
}
