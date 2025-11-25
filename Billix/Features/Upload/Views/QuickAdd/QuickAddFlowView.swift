//
//  QuickAddFlowView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

/// Container for the 4-step Quick Add flow with modern design
struct QuickAddFlowView: View {
    @StateObject private var viewModel = QuickAddViewModel()
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation
    @State private var showProgress = true
    let onComplete: () -> Void
    var onSwitchToFullAnalysis: (() -> Void)?

    var body: some View {
        NavigationView {
            ZStack {
                // Clean solid background
                Color.billixLightGreen
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Custom Header with Progress
                    headerView
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    // Step Content
                    ZStack {
                        switch viewModel.currentStep {
                        case .billType:
                            QuickAddStep1BillType(viewModel: viewModel, namespace: animation)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .provider:
                            QuickAddStep2Provider(
                                viewModel: viewModel,
                                namespace: animation,
                                onSwitchToFullAnalysis: {
                                    dismiss()
                                    onSwitchToFullAnalysis?()
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        case .amount:
                            QuickAddStep3Amount(viewModel: viewModel, namespace: animation)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .result:
                            QuickAddStep4Result(viewModel: viewModel, namespace: animation, onComplete: {
                                onComplete()
                                dismiss()
                            })
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentStep)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.onAppear()
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        ZStack {
            // Center: Progress percentage indicator (hide on result screen)
            if viewModel.currentStep != .result && showProgress {
                PercentageProgressIndicator(
                    currentStep: viewModel.currentStep.rawValue,
                    totalSteps: QuickAddViewModel.Step.allCases.count
                )
                .transition(.scale.combined(with: .opacity))
            }

            // Left & Right buttons
            HStack {
                // Back button
                if viewModel.currentStep != .billType {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.previousStep()
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.billixDarkGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.billixMoneyGreen.opacity(0.1))
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                }

                Spacer()

                // Cancel button
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixMediumGreen)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.billixMoneyGreen.opacity(0.1))
                        )
                }
            }
        }
    }
}

// MARK: - Circular Progress Indicator

struct PercentageProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    private var progress: Double {
        // Progress from 0% (step 1) to 100% (step 3)
        // Step 1: 0%, Step 2: 50%, Step 3: 100%
        let progressSteps = totalSteps - 1  // Exclude result step
        let adjustedStep = currentStep - 1   // Start from 0
        return min(Double(adjustedStep) / Double(progressSteps - 1), 1.0)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.billixMoneyGreen.opacity(0.15), lineWidth: 4)
                .frame(width: 44, height: 44)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.billixMoneyGreen, .billixChartBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)

            // Percentage text
            Text("\(percentage)%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.billixDarkGreen)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
        }
        .padding(8)
        .background(
            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    QuickAddFlowView(onComplete: {})
}
