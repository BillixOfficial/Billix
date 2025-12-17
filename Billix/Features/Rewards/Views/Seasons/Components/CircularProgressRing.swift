//
//  CircularProgressRing.swift
//  Billix
//
//  Created by Claude Code
//  Circular progress ring component for season cards
//

import SwiftUI

struct CircularProgressRing: View {
    let progress: Double  // 0.0 to 1.0
    let colors: [Color]
    let lineWidth: CGFloat

    @State private var animatedProgress: Double = 0

    init(progress: Double, colors: [Color] = [.billixDarkGreen, .billixMoneyGreen], lineWidth: CGFloat = 8) {
        self.progress = progress
        self.colors = colors
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: colors),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * animatedProgress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))  // Start from top
                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Preview

#Preview("Empty Ring") {
    CircularProgressRing(progress: 0.0)
        .frame(width: 120, height: 120)
        .padding()
}

#Preview("Half Progress") {
    CircularProgressRing(progress: 0.5)
        .frame(width: 120, height: 120)
        .padding()
}

#Preview("Full Progress") {
    CircularProgressRing(progress: 1.0)
        .frame(width: 120, height: 120)
        .padding()
}

#Preview("Custom Colors") {
    CircularProgressRing(
        progress: 0.75,
        colors: [.red, .orange, .yellow],
        lineWidth: 12
    )
    .frame(width: 140, height: 140)
    .padding()
}
