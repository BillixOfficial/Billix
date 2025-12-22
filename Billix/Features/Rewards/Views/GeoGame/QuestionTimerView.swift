//
//  QuestionTimerView.swift
//  Billix
//
//  Created by Claude Code
//  Countdown timer with circular progress ring for Price Guessr game phases
//  Design based on UX research: visual urgency cues, color transitions, pulse animations
//

import SwiftUI

struct QuestionTimerView: View {
    let timeRemaining: Double
    let progress: Double  // 0.0 to 1.0
    let color: Color
    let shouldPulse: Bool

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: 4
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)

            // Time text
            VStack(spacing: 2) {
                Text("\(Int(ceil(timeRemaining)))")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(color)

                Text("sec")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(color.opacity(0.7))
            }
        }
        .frame(width: 60, height: 60)
        .scaleEffect(shouldPulse ? pulseScale : 1.0)
        .onChange(of: shouldPulse) { _, isPulsing in
            if isPulsing {
                startPulseAnimation()
            }
        }
        .onAppear {
            if shouldPulse {
                startPulseAnimation()
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 0.5)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.1
        }
    }
}

// MARK: - Compact Timer Badge (for floating card header)

struct CompactTimerBadge: View {
    let timeRemaining: Double
    let color: Color
    let shouldPulse: Bool

    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: 13, weight: .semibold))

            Text("\(Int(ceil(timeRemaining)))s")
                .font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(shouldPulse ? pulseOpacity : 0.3), lineWidth: 2)
                )
        )
        .onChange(of: shouldPulse) { _, isPulsing in
            if isPulsing {
                startPulseAnimation()
            }
        }
        .onAppear {
            if shouldPulse {
                startPulseAnimation()
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
        ) {
            pulseOpacity = 0.8
        }
    }
}

// MARK: - Preview

#Preview("Timer States") {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        VStack(spacing: 40) {
            VStack(spacing: 16) {
                Text("Circular Timer")
                    .font(.headline)

                HStack(spacing: 30) {
                    VStack {
                        QuestionTimerView(
                            timeRemaining: 25,
                            progress: 0.7,
                            color: .billixMoneyGreen,
                            shouldPulse: false
                        )
                        Text("Plenty of time")
                            .font(.caption)
                    }

                    VStack {
                        QuestionTimerView(
                            timeRemaining: 8,
                            progress: 0.3,
                            color: .orange,
                            shouldPulse: false
                        )
                        Text("Warning")
                            .font(.caption)
                    }

                    VStack {
                        QuestionTimerView(
                            timeRemaining: 3,
                            progress: 0.1,
                            color: .red,
                            shouldPulse: true
                        )
                        Text("Urgent!")
                            .font(.caption)
                    }
                }
            }

            VStack(spacing: 16) {
                Text("Compact Badge")
                    .font(.headline)

                VStack(spacing: 12) {
                    CompactTimerBadge(
                        timeRemaining: 18,
                        color: .billixMoneyGreen,
                        shouldPulse: false
                    )

                    CompactTimerBadge(
                        timeRemaining: 7,
                        color: .orange,
                        shouldPulse: false
                    )

                    CompactTimerBadge(
                        timeRemaining: 2,
                        color: .red,
                        shouldPulse: true
                    )
                }
            }
        }
        .padding()
    }
}
