//
//  SwapProgressTimeline.swift
//  Billix
//
//  5-step visual progress timeline for swap tracking
//  Offer → Locked → Payment → Proof → Complete
//

import SwiftUI

// MARK: - Swap Progress Step

enum SwapProgressStep: Int, CaseIterable {
    case offer = 0
    case locked = 1
    case payment = 2
    case proof = 3
    case complete = 4

    var label: String {
        switch self {
        case .offer: return "Offer"
        case .locked: return "Locked"
        case .payment: return "Payment"
        case .proof: return "Proof"
        case .complete: return "Complete"
        }
    }

    var icon: String {
        switch self {
        case .offer: return "hand.raised.fill"
        case .locked: return "lock.fill"
        case .payment: return "creditcard.fill"
        case .proof: return "checkmark.seal.fill"
        case .complete: return "star.fill"
        }
    }

    /// Map swap status string to progress step
    static func from(status: String) -> SwapProgressStep {
        switch status.lowercased() {
        case "offered", "pending", "countered":
            return .offer
        case "locked", "accepted":
            return .locked
        case "awaiting_payment", "paying", "payment_pending":
            return .payment
        case "awaiting_proof", "proving", "proof_pending", "proof_submitted", "reviewing":
            return .proof
        case "completed", "verified", "done":
            return .complete
        default:
            return .offer
        }
    }
}

// MARK: - Timeline Styles

enum TimelineStyle {
    case compact   // Small dots, no labels (for cards)
    case standard  // Medium circles with labels below
    case expanded  // Large circles with icons and labels
}

// MARK: - Swap Progress Timeline

struct SwapProgressTimeline: View {
    let currentStep: SwapProgressStep
    var style: TimelineStyle = .standard
    var timeRemaining: String? = nil

    @State private var animateCurrentStep = false

    var body: some View {
        VStack(spacing: style == .compact ? 0 : 8) {
            // Timeline
            HStack(spacing: 0) {
                ForEach(SwapProgressStep.allCases, id: \.rawValue) { step in
                    stepView(for: step)

                    if step != .complete {
                        connectorLine(after: step)
                    }
                }
            }

            // Labels (not for compact)
            if style != .compact {
                HStack(spacing: 0) {
                    ForEach(SwapProgressStep.allCases, id: \.rawValue) { step in
                        stepLabel(for: step)
                    }
                }
            }

            // Time remaining (only for expanded)
            if style == .expanded, let timeRemaining = timeRemaining {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                    Text(timeRemaining)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(BillSwapTheme.statusPending)
                .padding(.top, 4)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animateCurrentStep = true
            }
        }
    }

    // MARK: - Step View

    @ViewBuilder
    private func stepView(for step: SwapProgressStep) -> some View {
        let isCompleted = step.rawValue < currentStep.rawValue
        let isCurrent = step == currentStep
        let isPending = step.rawValue > currentStep.rawValue

        ZStack {
            // Background circle
            Circle()
                .fill(stepBackgroundColor(isCompleted: isCompleted, isCurrent: isCurrent))
                .frame(width: stepSize, height: stepSize)

            // Pulse animation for current step
            if isCurrent && style != .compact {
                Circle()
                    .stroke(BillSwapTheme.accent.opacity(0.3), lineWidth: 2)
                    .frame(width: stepSize + 8, height: stepSize + 8)
                    .scaleEffect(animateCurrentStep ? 1.2 : 1.0)
                    .opacity(animateCurrentStep ? 0 : 0.5)
            }

            // Icon or checkmark
            if style == .expanded {
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: stepSize * 0.4, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: step.icon)
                        .font(.system(size: stepSize * 0.35))
                        .foregroundColor(isCurrent ? .white : BillSwapTheme.secondaryText)
                }
            } else if style == .standard {
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: stepSize * 0.45, weight: .bold))
                        .foregroundColor(.white)
                } else if isCurrent {
                    Circle()
                        .fill(Color.white)
                        .frame(width: stepSize * 0.4, height: stepSize * 0.4)
                }
            } else {
                // Compact: just filled or empty dot
                if isCompleted || isCurrent {
                    Circle()
                        .fill(Color.white)
                        .frame(width: stepSize * 0.5, height: stepSize * 0.5)
                }
            }
        }
        .frame(width: stepSize, height: stepSize)
    }

    // MARK: - Connector Line

    private func connectorLine(after step: SwapProgressStep) -> some View {
        let isCompleted = step.rawValue < currentStep.rawValue

        return Rectangle()
            .fill(isCompleted ? BillSwapTheme.accent : BillSwapTheme.secondaryText.opacity(0.3))
            .frame(height: lineHeight)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Step Label

    private func stepLabel(for step: SwapProgressStep) -> some View {
        let isCompleted = step.rawValue < currentStep.rawValue
        let isCurrent = step == currentStep

        return Text(step.label)
            .font(.system(size: labelFontSize, weight: isCurrent ? .semibold : .regular))
            .foregroundColor(isCompleted || isCurrent ? BillSwapTheme.primaryText : BillSwapTheme.mutedText)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func stepBackgroundColor(isCompleted: Bool, isCurrent: Bool) -> Color {
        if isCompleted {
            return BillSwapTheme.statusComplete
        } else if isCurrent {
            return BillSwapTheme.accent
        } else {
            return BillSwapTheme.secondaryText.opacity(0.2)
        }
    }

    private var stepSize: CGFloat {
        switch style {
        case .compact: return 10
        case .standard: return 24
        case .expanded: return 40
        }
    }

    private var lineHeight: CGFloat {
        switch style {
        case .compact: return 2
        case .standard: return 3
        case .expanded: return 4
        }
    }

    private var labelFontSize: CGFloat {
        switch style {
        case .compact: return 9
        case .standard: return 11
        case .expanded: return 12
        }
    }
}

// MARK: - Mini Timeline (for cards)

struct MiniSwapTimeline: View {
    let currentStep: SwapProgressStep

    var body: some View {
        HStack(spacing: 3) {
            ForEach(SwapProgressStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(dotColor(for: step))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func dotColor(for step: SwapProgressStep) -> Color {
        if step.rawValue < currentStep.rawValue {
            return BillSwapTheme.statusComplete
        } else if step == currentStep {
            return BillSwapTheme.accent
        } else {
            return BillSwapTheme.secondaryText.opacity(0.3)
        }
    }
}

// MARK: - Timeline Hero Card (for detail view)

struct TimelineHeroCard: View {
    let currentStep: SwapProgressStep
    let partnerName: String
    let statusMessage: String
    var timeRemaining: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            // Partner info
            VStack(spacing: 4) {
                Text("Trading with")
                    .font(.system(size: 12))
                    .foregroundColor(BillSwapTheme.secondaryText)

                Text("@\(partnerName)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(BillSwapTheme.primaryText)
            }

            Divider()

            // Timeline
            SwapProgressTimeline(
                currentStep: currentStep,
                style: .expanded,
                timeRemaining: timeRemaining
            )
            .padding(.horizontal, 8)

            Divider()

            // Status message
            HStack {
                Image(systemName: statusIcon)
                    .font(.system(size: 14))
                    .foregroundColor(BillSwapTheme.statusColor(for: currentStep.label))

                Text(statusMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(BillSwapTheme.primaryText)
            }
        }
        .padding(20)
        .background(BillSwapTheme.cardBackground)
        .cornerRadius(BillSwapTheme.cardCornerRadius)
        .shadow(
            color: BillSwapTheme.cardShadow,
            radius: BillSwapTheme.cardShadowRadius,
            x: 0,
            y: BillSwapTheme.cardShadowY
        )
    }

    private var statusIcon: String {
        switch currentStep {
        case .offer: return "clock.fill"
        case .locked: return "lock.fill"
        case .payment: return "creditcard.fill"
        case .proof: return "doc.viewfinder.fill"
        case .complete: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Previews

#Preview("Standard Timeline") {
    VStack(spacing: 40) {
        SwapProgressTimeline(currentStep: .offer, style: .standard)
        SwapProgressTimeline(currentStep: .locked, style: .standard)
        SwapProgressTimeline(currentStep: .payment, style: .standard)
        SwapProgressTimeline(currentStep: .proof, style: .standard)
        SwapProgressTimeline(currentStep: .complete, style: .standard)
    }
    .padding()
    .background(BillSwapTheme.background)
}

#Preview("Expanded Timeline") {
    VStack(spacing: 30) {
        SwapProgressTimeline(
            currentStep: .payment,
            style: .expanded,
            timeRemaining: "23h remaining"
        )
    }
    .padding()
    .background(BillSwapTheme.background)
}

#Preview("Compact Timeline") {
    VStack(spacing: 20) {
        MiniSwapTimeline(currentStep: .offer)
        MiniSwapTimeline(currentStep: .locked)
        MiniSwapTimeline(currentStep: .payment)
        MiniSwapTimeline(currentStep: .complete)
    }
    .padding()
    .background(BillSwapTheme.background)
}

#Preview("Hero Card") {
    TimelineHeroCard(
        currentStep: .payment,
        partnerName: "johndoe",
        statusMessage: "Awaiting your payment",
        timeRemaining: "23h 45m"
    )
    .padding()
    .background(BillSwapTheme.background)
}
