//
//  BillCoachFlowView.swift
//  Billix
//
//  Main coordinator for the progressive Bill Coach flow.
//  THE GOLDEN RULE: User experiences ONE interaction type at a time.
//

import SwiftUI

// MARK: - Theme

private enum CoachTheme {
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let accent = Color(hex: "#5B8A6B")
    static let success = Color(hex: "#4CAF7A")
    static let warning = Color(hex: "#E8A54B")
    static let info = Color(hex: "#5BA4D4")
}

// MARK: - Main Flow View

struct BillCoachFlowView: View {
    @StateObject private var session: CoachingSession
    @Environment(\.dismiss) private var dismiss

    init(topic: CoachingTopic) {
        _session = StateObject(wrappedValue: CoachingSession(topic: topic))
    }

    var body: some View {
        ZStack {
            CoachTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with progress
                CoachHeader(session: session, onClose: { dismiss() })

                // Main content - ONE step at a time
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        switch session.currentStep {
                        case .billWalkthrough:
                            BillWalkthroughView(session: session)

                        case .whatIfSlider:
                            WhatIfSliderView(session: session)

                        case .communityComparison:
                            CommunityComparisonView(session: session)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }

                // Bottom action button
                CoachBottomAction(session: session)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Coach Header

private struct CoachHeader: View {
    @ObservedObject var session: CoachingSession
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(CoachTheme.secondaryText)
                        .frame(width: 36, height: 36)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 4)
                }

                Spacer()

                // Topic badge
                HStack(spacing: 6) {
                    Image(systemName: session.topic.icon)
                        .font(.system(size: 12))
                    Text(session.topic.title)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(session.topic.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(session.topic.color.opacity(0.1))
                .cornerRadius(16)

                Spacer()

                // Spacer for balance
                Color.clear.frame(width: 36, height: 36)
            }

            // Progress dots (subtle)
            HStack(spacing: 8) {
                ForEach(CoachingStep.allCases, id: \.rawValue) { step in
                    Circle()
                        .fill(stepColor(for: step))
                        .frame(width: 8, height: 8)
                        .scaleEffect(step == session.currentStep ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: session.currentStep)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    private func stepColor(for step: CoachingStep) -> Color {
        if session.completedSteps.contains(step) {
            return CoachTheme.success
        } else if step == session.currentStep {
            return session.topic.color
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

// MARK: - Bottom Action

private struct CoachBottomAction: View {
    @ObservedObject var session: CoachingSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                // Secondary action (if applicable)
                if session.currentStep != .billWalkthrough {
                    Button {
                        // Skip/Later action
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if session.currentStep == .communityComparison {
                            dismiss()
                        } else {
                            session.advanceStep()
                        }
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(CoachTheme.secondaryText)
                    }
                }

                Spacer()

                // Primary action
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if session.currentStep == .communityComparison {
                        dismiss()
                    } else {
                        session.advanceStep()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(buttonText)
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: session.currentStep == .communityComparison ? "checkmark" : "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(session.topic.color)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }

    private var buttonText: String {
        switch session.currentStep {
        case .billWalkthrough: return "I understand"
        case .whatIfSlider: return "Continue"
        case .communityComparison: return "Done"
        }
    }
}

// MARK: - Step 1: Bill Walkthrough

private struct BillWalkthroughView: View {
    @ObservedObject var session: CoachingSession
    @State private var highlightedIndex: Int = 0
    @State private var showTip = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Contextual intro
            VStack(alignment: .leading, spacing: 8) {
                Text("Let's understand your bill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(CoachTheme.primaryText)

                Text("I'll highlight areas where you might find savings opportunities.")
                    .font(.system(size: 16))
                    .foregroundColor(CoachTheme.secondaryText)
            }

            // Bill visualization
            VStack(spacing: 0) {
                // Bill header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your \(session.topic.title.replacingOccurrences(of: "Negotiate ", with: "").replacingOccurrences(of: "Lower ", with: "").replacingOccurrences(of: "Cancel ", with: "")) Bill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(CoachTheme.primaryText)
                        Text("Common bill components")
                            .font(.system(size: 13))
                            .foregroundColor(CoachTheme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: session.topic.icon)
                        .font(.system(size: 24))
                        .foregroundColor(session.topic.color)
                }
                .padding(16)
                .background(Color.gray.opacity(0.05))

                Divider()

                // Line items
                ForEach(Array(session.billLineItems.enumerated()), id: \.element.id) { index, item in
                    BillLineItemRow(
                        item: item,
                        isHighlighted: item.isHighlighted && index == highlightedIndex,
                        onTap: {
                            if item.isHighlighted {
                                withAnimation(.spring(response: 0.4)) {
                                    highlightedIndex = index
                                    showTip = true
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    )

                    if index < session.billLineItems.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)

            // Savings tip callout (appears on tap)
            if showTip, let tip = session.billLineItems[highlightedIndex].savingsTip {
                TipCallout(tip: tip, color: session.topic.color)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            // Instruction card
            HStack(spacing: 12) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 18))
                    .foregroundColor(session.topic.color)

                Text("Tap highlighted items to learn about savings opportunities")
                    .font(.system(size: 14))
                    .foregroundColor(CoachTheme.secondaryText)
            }
            .padding(16)
            .background(session.topic.color.opacity(0.08))
            .cornerRadius(12)
        }
        .onAppear {
            // Auto-show first tip after a moment
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000)
                withAnimation {
                    showTip = true
                }
            }
        }
    }
}

private struct BillLineItemRow: View {
    let item: BillLineItem
    let isHighlighted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(CoachTheme.primaryText)

                        if item.isHighlighted {
                            Image(systemName: "sparkle")
                                .font(.system(size: 10))
                                .foregroundColor(CoachTheme.warning)
                        }
                    }

                    Text(item.description)
                        .font(.system(size: 13))
                        .foregroundColor(CoachTheme.secondaryText)
                }

                Spacer()

                if item.isHighlighted {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(CoachTheme.secondaryText)
                }
            }
            .padding(16)
            .background(isHighlighted ? CoachTheme.warning.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

private struct TipCallout: View {
    let tip: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(tip)
                .font(.system(size: 15))
                .foregroundColor(CoachTheme.primaryText)
                .lineSpacing(4)
        }
        .padding(16)
        .background(color.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Step 2: Usage Assessment

private struct WhatIfSliderView: View {
    @ObservedObject var session: CoachingSession
    @State private var selectedOptionId: UUID?

    private var assessment: UsageAssessment {
        session.usageAssessment
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(assessment.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(CoachTheme.primaryText)

                Text(assessment.question)
                    .font(.system(size: 16))
                    .foregroundColor(CoachTheme.secondaryText)
            }

            // Usage options
            VStack(spacing: 12) {
                ForEach(assessment.options) { option in
                    UsageOptionCard(
                        option: option,
                        isSelected: selectedOptionId == option.id,
                        color: session.topic.color,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedOptionId = option.id
                                session.selectedUsageOption = option
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    )
                }
            }

            // Feedback card (appears after selection)
            if let selectedOption = session.selectedUsageOption {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 18))
                            .foregroundColor(session.topic.color)

                        Text("Based on your usage")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(CoachTheme.primaryText)
                    }

                    Text(selectedOption.feedback)
                        .font(.system(size: 14))
                        .foregroundColor(CoachTheme.secondaryText)
                        .lineSpacing(4)
                }
                .padding(16)
                .background(session.topic.color.opacity(0.08))
                .cornerRadius(12)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
    }
}

private struct UsageOptionCard: View {
    let option: UsageOption
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: option.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? color : color.opacity(0.12))
                    .cornerRadius(12)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(CoachTheme.primaryText)

                    Text(option.description)
                        .font(.system(size: 13))
                        .foregroundColor(CoachTheme.secondaryText)
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? color : Color.gray.opacity(0.3))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? color.opacity(0.15) : .clear, radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Step 3: Community Comparison

private struct CommunityComparisonView: View {
    @ObservedObject var session: CoachingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("You're not alone")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(CoachTheme.primaryText)

                Text("Here's what others in your situation have done.")
                    .font(.system(size: 16))
                    .foregroundColor(CoachTheme.secondaryText)
            }

            // Community insights
            VStack(spacing: 16) {
                ForEach(session.communityInsights) { insight in
                    CommunityInsightCard(insight: insight, color: session.topic.color)
                }
            }

            // Encouragement card
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18))
                        .foregroundColor(CoachTheme.success)

                    Text("You've got this")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(CoachTheme.primaryText)
                }

                Text("Small steps lead to real change. You've taken the first one by learning how your bill works.")
                    .font(.system(size: 14))
                    .foregroundColor(CoachTheme.secondaryText)
                    .lineSpacing(4)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [CoachTheme.success.opacity(0.08), session.topic.color.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(CoachTheme.success.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

private struct CommunityInsightCard: View {
    let insight: CommunityInsight
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: insight.icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(CoachTheme.primaryText)

                Text(insight.description)
                    .font(.system(size: 13))
                    .foregroundColor(CoachTheme.secondaryText)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Preview

#Preview {
    BillCoachFlowView(topic: .negotiateInternet)
}
