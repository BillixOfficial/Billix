//
//  RadialProgressIndicator.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

/// A circular/radial progress indicator for multi-step flows
/// Shows current step with animated progress ring
struct RadialProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    var size: CGFloat = 50
    var lineWidth: CGFloat = 4
    var showStepLabel: Bool = true

    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }

    private var isComplete: Bool {
        currentStep >= totalSteps
    }

    var body: some View {
        HStack(spacing: 12) {
            // Radial progress ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        Color.billixMoneyGreen.opacity(0.2),
                        lineWidth: lineWidth
                    )

                // Progress arc with solid color
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        Color.billixMoneyGreen,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Center content
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundColor(.billixMoneyGreen)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("\(currentStep)")
                        .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)
                }
            }
            .frame(width: size, height: size)

            // Step label
            if showStepLabel {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isComplete ? "Complete" : "Step \(currentStep) of \(totalSteps)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixDarkGreen)

                    Text(stepDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.billixMediumGreen)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
        .onChange(of: currentStep) { _, _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
    }

    private var stepDescription: String {
        if isComplete {
            return "All done!"
        }
        switch currentStep {
        case 1: return "Select bill type"
        case 2: return "Choose provider"
        case 3: return "Enter amount"
        case 4: return "See results"
        default: return ""
        }
    }
}

/// Horizontal step indicator with dots
struct HorizontalStepIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    var dotSize: CGFloat = 10
    var spacing: CGFloat = 8

    @Namespace private var animation

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.billixMoneyGreen : Color.billixMoneyGreen.opacity(0.2))
                    .frame(width: step == currentStep ? dotSize * 1.4 : dotSize, height: dotSize)
                    .overlay {
                        if step == currentStep {
                            Circle()
                                .stroke(Color.billixMoneyGreen.opacity(0.3), lineWidth: 2)
                                .frame(width: dotSize * 2, height: dotSize * 2)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)

                if step < totalSteps {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(step < currentStep ? Color.billixMoneyGreen : Color.billixMoneyGreen.opacity(0.2))
                        .frame(width: 20, height: 2)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1), value: currentStep)
                }
            }
        }
    }
}

/// Pill-style progress indicator
struct PillProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    @Namespace private var animation

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                if step == currentStep {
                    Capsule()
                        .fill(Color.billixMoneyGreen)
                        .frame(width: 24, height: 8)
                        .matchedGeometryEffect(id: "activePill", in: animation)
                } else {
                    Circle()
                        .fill(step < currentStep ? Color.billixMoneyGreen : Color.billixMoneyGreen.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
    }
}

/// Compact step counter for navigation bar
struct CompactStepCounter: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("\(currentStep)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.billixDarkGreen)
                .contentTransition(.numericText())

            Text("/")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.billixMediumGreen)

            Text("\(totalSteps)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.billixMediumGreen)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.billixMoneyGreen.opacity(0.1))
        )
    }
}

// MARK: - Preview

struct RadialProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
        // Radial indicator
        VStack(spacing: 20) {
        Text("Radial Progress")
        .font(.headline)
        
        HStack(spacing: 30) {
        RadialProgressIndicator(currentStep: 1, totalSteps: 4, showStepLabel: false)
        RadialProgressIndicator(currentStep: 2, totalSteps: 4, showStepLabel: false)
        RadialProgressIndicator(currentStep: 3, totalSteps: 4, showStepLabel: false)
        RadialProgressIndicator(currentStep: 4, totalSteps: 4, showStepLabel: false)
        }
        
        RadialProgressIndicator(currentStep: 2, totalSteps: 4)
        }
        
        Divider()
        
        // Horizontal dots
        VStack(spacing: 20) {
        Text("Horizontal Dots")
        .font(.headline)
        
        HorizontalStepIndicator(currentStep: 2, totalSteps: 4)
        }
        
        Divider()
        
        // Pill indicator
        VStack(spacing: 20) {
        Text("Pill Progress")
        .font(.headline)
        
        PillProgressIndicator(currentStep: 2, totalSteps: 4)
        }
        
        Divider()
        
        // Compact counter
        VStack(spacing: 20) {
        Text("Compact Counter")
        .font(.headline)
        
        CompactStepCounter(currentStep: 2, totalSteps: 4)
        }
        }
        .padding()
    }
}
