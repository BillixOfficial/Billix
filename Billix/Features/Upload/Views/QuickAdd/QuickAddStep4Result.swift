//
//  QuickAddStep4Result.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct QuickAddStep4Result: View {
    @ObservedObject var viewModel: QuickAddViewModel
    var namespace: Namespace.ID
    let onComplete: () -> Void
    var onSeeWhatImMissing: (() -> Void)?

    @State private var appeared = false
    @State private var showConfetti = false
    @State private var animatedUserAmount: Double = 0
    @State private var animatedAvgAmount: Double = 0
    @State private var animatedPercent: Double = 0

    var body: some View {
        ZStack {
            // Confetti overlay
            if let result = viewModel.result {
                ConfettiView(
                    isActive: showConfetti,
                    type: confettiType(for: result.status)
                )
                .ignoresSafeArea()
            }

            ScrollView(showsIndicators: false) {
                if let result = viewModel.result {
                    VStack(spacing: 24) {
                        // Status Header
                        statusHeader(result: result)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appeared)

                        // Comparison Card
                        comparisonCard(result: result)
                            .padding(.horizontal, 20)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appeared)

                        // Savings Card (if applicable)
                        if let savings = result.potentialSavings, savings > 0 {
                            savingsCard(savings: savings)
                                .padding(.horizontal, 20)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 30)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: appeared)
                        }

                        // CTA Section
                        ctaSection(result: result)
                            .padding(.horizontal, 20)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: appeared)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }

            // Auto-save the Quick Add result immediately
            Task {
                do {
                    try await viewModel.saveQuickAddResult()
                } catch {
                    print("Failed to auto-save Quick Add result: \(error)")
                }
            }

            // Trigger confetti after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
                triggerHapticFeedback()
            }

            // Animate numbers
            if let result = viewModel.result {
                withAnimation(.easeOut(duration: 1.2).delay(0.5)) {
                    animatedUserAmount = result.amount
                    animatedAvgAmount = result.areaAverage
                    animatedPercent = abs(result.percentDifference)
                }
            }
        }
    }

    // MARK: - Status Header

    private func statusHeader(result: QuickAddResult) -> some View {
        VStack(spacing: 16) {
            // Status Icon with solid color
            ZStack {
                Circle()
                    .fill(statusColor(for: result.status))
                    .frame(width: 80, height: 80)
                    .shadow(color: statusColor(for: result.status).opacity(0.35), radius: 12, y: 6)

                Image(systemName: result.statusIcon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: appeared)

            // Status Message
            VStack(spacing: 8) {
                Text(statusTitle(for: result.status))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)

                HStack(spacing: 4) {
                    Text(String(format: "%.0f%%", animatedPercent))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(statusColor(for: result.status))
                        .contentTransition(.numericText())

                    Text(statusSubtitle(for: result.status))
                        .font(.system(size: 16))
                        .foregroundColor(.billixMediumGreen)
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Comparison Card

    private func comparisonCard(result: QuickAddResult) -> some View {
        SolidCard(cornerRadius: 24, padding: 24, shadowRadius: 15) {
            VStack(spacing: 24) {
                // Amount comparison
                HStack {
                    // Your Bill
                    VStack(spacing: 6) {
                        Text("Your Bill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.billixMediumGreen)

                        Text(String(format: "$%.2f", animatedUserAmount))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(statusColor(for: result.status))
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)

                    // VS Divider
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 8, height: 8)
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 1, height: 30)
                        Text("vs")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 1, height: 30)
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 8, height: 8)
                    }

                    // Area Average
                    VStack(spacing: 6) {
                        Text("Area Avg")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.billixMediumGreen)

                        Text(String(format: "$%.2f", animatedAvgAmount))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.billixDarkGreen.opacity(0.7))
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)
                }

                // Visual Comparison Bar
                AnimatedComparisonBar(
                    userAmount: result.amount,
                    averageAmount: result.areaAverage
                )
            }
        }
    }

    // MARK: - Savings Card

    private func savingsCard(savings: Double) -> some View {
        AccentCard(color: .billixMoneyGreen, cornerRadius: 20, padding: 20) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "star.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Potential Savings")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    Text(String(format: "$%.2f/month", savings))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // MARK: - CTA Section

    private func ctaSection(result: QuickAddResult) -> some View {
        VStack(spacing: 16) {
            // Tip text
            HStack(spacing: 8) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.billixChartBlue)

                Text("Get hidden fees, line-by-line breakdown & more savings")
                    .font(.system(size: 13))
                    .foregroundColor(.billixMediumGreen)
            }
            .padding(.horizontal, 8)

            // Primary CTA - See What I'm Missing
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onSeeWhatImMissing?()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))

                    Text("See What I'm Missing")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.billixChartBlue)
                )
                .shadow(color: Color.billixChartBlue.opacity(0.35), radius: 12, y: 6)
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))

            // Secondary CTA - Done (data already auto-saved on appear)
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onComplete()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.billixBorderGreen, lineWidth: 1.5)
                    )
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))
        }
    }

    // MARK: - Helper Functions

    private func statusColor(for status: QuickAddResult.Status) -> Color {
        switch status {
        case .overpaying: return .statusOverpaying
        case .underpaying: return .statusUnderpaying
        case .average: return .statusNeutral
        }
    }

    private func statusTitle(for status: QuickAddResult.Status) -> String {
        switch status {
        case .overpaying: return "You're paying more"
        case .underpaying: return "Great deal!"
        case .average: return "Right on target"
        }
    }

    private func statusSubtitle(for status: QuickAddResult.Status) -> String {
        switch status {
        case .overpaying: return "above average"
        case .underpaying: return "below average"
        case .average: return "close to average"
        }
    }

    private func confettiType(for status: QuickAddResult.Status) -> ConfettiView.ConfettiType {
        switch status {
        case .overpaying: return .warning
        case .underpaying: return .celebration
        case .average: return .neutral
        }
    }

    private func triggerHapticFeedback() {
        guard let result = viewModel.result else { return }

        switch result.status {
        case .overpaying:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .underpaying:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .average:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var viewModel = QuickAddViewModel()
        @Namespace private var namespace

        var body: some View {
            ZStack {
                Color.billixLightGreen.ignoresSafeArea()
                QuickAddStep4Result(viewModel: viewModel, namespace: namespace, onComplete: {}, onSeeWhatImMissing: {})
            }
            .onAppear {
                // Create mock result
                let mockBillType = BillType(id: "electric", name: "Electric", icon: "bolt.fill", category: "Utilities")
                let mockProvider = BillProvider(id: "dte", name: "DTE Energy", category: "utilities", avgAmount: 125.00, sampleSize: 47)

                viewModel.result = QuickAddResult(
                    billType: mockBillType,
                    provider: mockProvider,
                    amount: 145.50,
                    frequency: .monthly,
                    areaAverage: 125.00,
                    percentDifference: 16.4,
                    status: .overpaying,
                    potentialSavings: 14.35,
                    message: "You're paying 16% more than average",
                    ctaMessage: "Upload your bill for more details"
                )
            }
        }
    }

    return PreviewWrapper()
}
