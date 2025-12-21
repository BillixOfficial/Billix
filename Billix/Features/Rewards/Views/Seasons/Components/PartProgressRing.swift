//
//  PartProgressRing.swift
//  Billix
//
//  Created by Claude Code
//  Circular progress indicator for part cards
//

import SwiftUI

struct PartProgressRing: View {
    let partNumber: Int
    let progress: Double        // 0.0 to 1.0
    let starsEarned: Int        // 0-3
    let isUnlocked: Bool
    let isCompleted: Bool

    @State private var animatedProgress: Double = 0

    private var ringColor: Color {
        if !isUnlocked {
            return .gray.opacity(0.3)
        } else if isCompleted {
            return .billixMoneyGreen
        } else {
            return Color(hex: "#6B2DD6")
        }
    }

    private var backgroundColor: Color {
        isUnlocked ? .white.opacity(0.2) : .gray.opacity(0.1)
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(backgroundColor, lineWidth: 4)
                .frame(width: 60, height: 60)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: animatedProgress)

            // Center content
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.billixMoneyGreen)
                    .transition(.scale.combined(with: .opacity))
            } else if isUnlocked {
                Text("\(partNumber)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            // Star overlay (positioned above ring)
            if isUnlocked && starsEarned > 0 {
                VStack {
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0..<starsEarned, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.billixArcadeGold)
                        }
                    }
                    .padding(.bottom, -8)
                }
                .frame(width: 60, height: 60)
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Preview

#Preview("Part Progress Ring") {
    VStack(spacing: 30) {
        // Unlocked, in progress (70%)
        PartProgressRing(
            partNumber: 1,
            progress: 0.7,
            starsEarned: 2,
            isUnlocked: true,
            isCompleted: false
        )

        // Completed (100%)
        PartProgressRing(
            partNumber: 2,
            progress: 1.0,
            starsEarned: 3,
            isUnlocked: true,
            isCompleted: true
        )

        // Locked
        PartProgressRing(
            partNumber: 3,
            progress: 0.0,
            starsEarned: 0,
            isUnlocked: false,
            isCompleted: false
        )

        // Just started (10%)
        PartProgressRing(
            partNumber: 1,
            progress: 0.1,
            starsEarned: 1,
            isUnlocked: true,
            isCompleted: false
        )
    }
    .padding()
    .background(Color.billixLightGreen)
}
