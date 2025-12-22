//
//  ProgressBarView.swift
//  Billix
//
//  Created by Claude Code
//  Displays question progress (e.g., "Question 1 of 12")
//

import SwiftUI

struct ProgressBarView: View {

    let currentQuestion: Int
    let totalQuestions: Int

    var progress: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(currentQuestion) / Double(totalQuestions)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Progress text
            Text("Q\(currentQuestion)/\(totalQuestions)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(minWidth: 42)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)

                    // Filled progress
                    Capsule()
                        .fill(Color.billixMoneyGreen)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            ProgressBarView(currentQuestion: 1, totalQuestions: 12)
            ProgressBarView(currentQuestion: 4, totalQuestions: 12)
            ProgressBarView(currentQuestion: 8, totalQuestions: 12)
            ProgressBarView(currentQuestion: 12, totalQuestions: 12)
        }
        .padding()
    }
}
