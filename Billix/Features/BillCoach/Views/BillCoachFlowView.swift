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
    @State private var showConfetti = false

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

                        case .decisionQuiz:
                            DecisionQuizView(session: session)

                        case .coachMission:
                            CoachMissionView(session: session)

                        case .confidenceScore:
                            ConfidenceScoreView(session: session)

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

            if showConfetti {
                CoachConfettiView()
            }
        }
        .navigationBarHidden(true)
        .onChange(of: session.currentStep) { _, newStep in
            if newStep == .confidenceScore {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showConfetti = false
                }
            }
        }
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

                // Ambient confidence indicator (subtle, not loud)
                if session.confidenceScore > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("\(Int(session.confidenceScore))%")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(CoachTheme.success.opacity(0.8))
                    .frame(width: 36)
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
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

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                // Secondary action (if applicable)
                if session.currentStep != .billWalkthrough {
                    Button {
                        // Skip/Later action
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        session.advanceStep()
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
                    session.advanceStep()
                } label: {
                    HStack(spacing: 8) {
                        Text(buttonText)
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
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
        case .whatIfSlider: return "See what I can save"
        case .decisionQuiz: return "Continue"
        case .coachMission: return "I'll do this"
        case .confidenceScore: return "Almost done"
        case .communityComparison: return "Finish"
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
                Text("Let's look at your bill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(CoachTheme.primaryText)

                Text("I'll highlight the parts where you might be overpaying.")
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
                        Text("Current monthly total")
                            .font(.system(size: 13))
                            .foregroundColor(CoachTheme.secondaryText)
                    }
                    Spacer()
                    Text("$\(String(format: "%.2f", session.totalBillAmount))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(CoachTheme.primaryText)
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
                TipCallout(
                    tip: tip,
                    savings: session.billLineItems[highlightedIndex].potentialSavings,
                    color: session.topic.color
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            // Potential savings summary
            VStack(spacing: 8) {
                HStack {
                    Text("Potential Monthly Savings")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CoachTheme.secondaryText)
                    Spacer()
                    Text("$\(String(format: "%.2f", session.totalPotentialSavings))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(CoachTheme.success)
                }

                Text("Tap highlighted items to learn more")
                    .font(.system(size: 13))
                    .foregroundColor(CoachTheme.secondaryText.opacity(0.7))
            }
            .padding(16)
            .background(CoachTheme.success.opacity(0.08))
            .cornerRadius(12)
        }
        .onAppear {
            // Auto-show first tip after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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

                Text("$\(String(format: "%.2f", item.amount))")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(CoachTheme.primaryText)
            }
            .padding(16)
            .background(isHighlighted ? CoachTheme.warning.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

private struct TipCallout: View {
    let tip: String
    let savings: Double?
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 8) {
                Text(tip)
                    .font(.system(size: 15))
                    .foregroundColor(CoachTheme.primaryText)
                    .lineSpacing(4)

                if let savings = savings {
                    HStack(spacing: 4) {
                        Text("Potential savings:")
                            .font(.system(size: 13))
                            .foregroundColor(CoachTheme.secondaryText)
                        Text("$\(String(format: "%.2f", savings))/mo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(CoachTheme.success)
                    }
                }
            }
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

// MARK: - Step 2: What-If Sliders

private struct WhatIfSliderView: View {
    @ObservedObject var session: CoachingSession
    @State private var currentScenarioIndex = 0
    @State private var sliderValue: Double = 0
    @State private var animatedSavings: Double = 0

    private var currentScenario: WhatIfScenario {
        session.whatIfScenarios[currentScenarioIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("What if you changed this?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(CoachTheme.primaryText)

                Text("Drag the slider to see real savings.")
                    .font(.system(size: 16))
                    .foregroundColor(CoachTheme.secondaryText)
            }

            // Animated bill total
            VStack(spacing: 8) {
                Text("Your New Bill")
                    .font(.system(size: 14))
                    .foregroundColor(CoachTheme.secondaryText)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("$")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(CoachTheme.primaryText)

                    Text(String(format: "%.2f", session.totalBillAmount - animatedSavings))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(CoachTheme.primaryText)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: animatedSavings)
                }

                if animatedSavings > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 12, weight: .bold))
                        Text("Saving $\(String(format: "%.2f", animatedSavings))/mo")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(CoachTheme.success)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)

            // Scenario card
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentScenario.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(CoachTheme.primaryText)

                    Text(currentScenario.description)
                        .font(.system(size: 14))
                        .foregroundColor(CoachTheme.secondaryText)
                }

                // Slider
                VStack(spacing: 12) {
                    HStack {
                        Text("\(Int(currentScenario.minValue)) \(currentScenario.unit)")
                            .font(.system(size: 12))
                            .foregroundColor(CoachTheme.secondaryText)
                        Spacer()
                        Text("\(Int(sliderValue)) \(currentScenario.unit)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(session.topic.color)
                        Spacer()
                        Text("\(Int(currentScenario.maxValue)) \(currentScenario.unit)")
                            .font(.system(size: 12))
                            .foregroundColor(CoachTheme.secondaryText)
                    }

                    Slider(
                        value: $sliderValue,
                        in: currentScenario.minValue...currentScenario.maxValue,
                        step: 1
                    )
                    .tint(session.topic.color)
                    .onChange(of: sliderValue) { _, newValue in
                        let savings = (currentScenario.currentValue - newValue) * currentScenario.savingsPerUnit
                        withAnimation(.spring(response: 0.3)) {
                            animatedSavings = max(0, savings)
                        }
                        session.sliderValues[currentScenario.id] = newValue
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }

                    // Suggested value callout
                    if sliderValue != currentScenario.suggestedValue {
                        Button {
                            withAnimation {
                                sliderValue = currentScenario.suggestedValue
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                Text("Try recommended: \(Int(currentScenario.suggestedValue)) \(currentScenario.unit)")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(session.topic.color)
                        }
                    }
                }

                // Scenario navigation dots
                if session.whatIfScenarios.count > 1 {
                    HStack {
                        Spacer()
                        ForEach(0..<session.whatIfScenarios.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentScenarioIndex ? session.topic.color : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .onTapGesture {
                                    withAnimation {
                                        currentScenarioIndex = index
                                        sliderValue = session.whatIfScenarios[index].currentValue
                                    }
                                }
                        }
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        }
        .onAppear {
            sliderValue = currentScenario.currentValue
        }
    }
}

// MARK: - Step 3: Decision Quiz

private struct DecisionQuizView: View {
    @ObservedObject var session: CoachingSession
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: Int?
    @State private var showResult = false
    @State private var isCorrect = false

    private var currentQuestion: CoachQuizQuestion {
        session.quizQuestions[currentQuestionIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("Quick check")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(CoachTheme.primaryText)

                    // Question counter
                    Text("\(currentQuestionIndex + 1)/\(session.quizQuestions.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CoachTheme.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }

                Text("Let's make sure you've got this.")
                    .font(.system(size: 16))
                    .foregroundColor(CoachTheme.secondaryText)
            }

            // Question card
            VStack(alignment: .leading, spacing: 20) {
                Text(currentQuestion.question)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(CoachTheme.primaryText)
                    .lineSpacing(4)

                // Answer options
                VStack(spacing: 12) {
                    ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                        AnswerOption(
                            text: option,
                            isSelected: selectedAnswer == index,
                            isCorrect: showResult && index == currentQuestion.correctIndex,
                            isWrong: showResult && selectedAnswer == index && index != currentQuestion.correctIndex,
                            onTap: {
                                if !showResult {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedAnswer = index
                                        session.quizAnswers[currentQuestion.id] = index
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()

                                    // Auto-reveal after selection
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation {
                                            showResult = true
                                            isCorrect = index == currentQuestion.correctIndex
                                        }
                                        UINotificationFeedbackGenerator().notificationOccurred(
                                            isCorrect ? .success : .warning
                                        )
                                    }
                                }
                            }
                        )
                    }
                }

                // Result feedback
                if showResult {
                    ResultFeedback(
                        isCorrect: isCorrect,
                        explanation: currentQuestion.explanation,
                        encouragement: currentQuestion.encouragement,
                        color: session.topic.color
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)

            // Next question button (if more questions)
            if showResult && currentQuestionIndex < session.quizQuestions.count - 1 {
                Button {
                    withAnimation {
                        currentQuestionIndex += 1
                        selectedAnswer = nil
                        showResult = false
                    }
                } label: {
                    HStack {
                        Text("Next Question")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(session.topic.color)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

private struct AnswerOption: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .strokeBorder(borderColor, lineWidth: 2)
                    .background(Circle().fill(fillColor))
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isCorrect {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else if isWrong {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(CoachTheme.primaryText)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var borderColor: Color {
        if isCorrect { return CoachTheme.success }
        if isWrong { return Color.red }
        if isSelected { return CoachTheme.info }
        return Color.gray.opacity(0.3)
    }

    private var fillColor: Color {
        if isCorrect { return CoachTheme.success }
        if isWrong { return Color.red }
        if isSelected { return CoachTheme.info }
        return .clear
    }

    private var backgroundColor: Color {
        if isCorrect { return CoachTheme.success.opacity(0.08) }
        if isWrong { return Color.red.opacity(0.08) }
        return .clear
    }
}

private struct ResultFeedback: View {
    let isCorrect: Bool
    let explanation: String
    let encouragement: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isCorrect ? CoachTheme.success : CoachTheme.warning)

                Text(isCorrect ? "Correct!" : "Good try!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isCorrect ? CoachTheme.success : CoachTheme.warning)
            }

            Text(explanation)
                .font(.system(size: 14))
                .foregroundColor(CoachTheme.primaryText)
                .lineSpacing(4)

            Text(encouragement)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .italic()
        }
        .padding(16)
        .background(isCorrect ? CoachTheme.success.opacity(0.08) : CoachTheme.warning.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Step 4: Coach Mission

private struct CoachMissionView: View {
    @ObservedObject var session: CoachingSession
    @State private var expandedStepIndex: Int?
    @State private var showScript = false

    private var mission: CoachMission {
        session.mission
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("Your mission")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(CoachTheme.primaryText)

                    // Points badge
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("+\(mission.pointsReward) pts")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(CoachTheme.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(CoachTheme.warning.opacity(0.15))
                    .cornerRadius(8)
                }

                Text("Based on your bill, here's exactly what to do.")
                    .font(.system(size: 16))
                    .foregroundColor(CoachTheme.secondaryText)
            }

            // Mission card
            VStack(alignment: .leading, spacing: 20) {
                // Mission header
                HStack(spacing: 14) {
                    Image(systemName: "target")
                        .font(.system(size: 24))
                        .foregroundColor(session.topic.color)
                        .frame(width: 48, height: 48)
                        .background(session.topic.color.opacity(0.12))
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mission.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(CoachTheme.primaryText)

                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 11))
                                Text(mission.estimatedTime)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(CoachTheme.secondaryText)
                        }
                    }
                }

                Text(mission.description)
                    .font(.system(size: 14))
                    .foregroundColor(CoachTheme.secondaryText)
                    .lineSpacing(4)

                // Steps
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(mission.steps.enumerated()), id: \.offset) { index, step in
                        MissionStepRow(
                            number: index + 1,
                            text: step,
                            isExpanded: expandedStepIndex == index,
                            onTap: {
                                withAnimation(.spring(response: 0.3)) {
                                    expandedStepIndex = expandedStepIndex == index ? nil : index
                                }
                            }
                        )
                    }
                }

                // Script template (if available)
                if let script = mission.scriptTemplate {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation {
                                showScript.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: 14))
                                Text("What to say")
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                                Image(systemName: showScript ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(session.topic.color)
                        }

                        if showScript {
                            Text("\"\(script)\"")
                                .font(.system(size: 14).italic())
                                .foregroundColor(CoachTheme.primaryText)
                                .padding(14)
                                .background(session.topic.color.opacity(0.08))
                                .cornerRadius(10)
                                .transition(.opacity.combined(with: .move(edge: .top)))

                            Button {
                                UIPasteboard.general.string = script
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                    Text("Copy to clipboard")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(session.topic.color)
                            }
                        }
                    }
                }

                // Start mission button
                Button {
                    session.missionStarted = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: session.missionStarted ? "checkmark.circle.fill" : "play.fill")
                        Text(session.missionStarted ? "Mission accepted!" : "Start this mission")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(session.missionStarted ? CoachTheme.success : session.topic.color)
                    .cornerRadius(12)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)

            // Reassurance note
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(session.topic.color)

                Text("No pressure - do this when you're ready.")
                    .font(.system(size: 13))
                    .foregroundColor(CoachTheme.secondaryText)
            }
            .padding(14)
            .background(session.topic.color.opacity(0.08))
            .cornerRadius(10)
        }
    }
}

private struct MissionStepRow: View {
    let number: Int
    let text: String
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(CoachTheme.accent)
                    .clipShape(Circle())

                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(CoachTheme.primaryText)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 5: Confidence Score

private struct ConfidenceScoreView: View {
    @ObservedObject var session: CoachingSession
    @State private var animatedScore: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("You're building confidence")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(CoachTheme.primaryText)

                Text("Every small step counts. You're in control.")
                    .font(.system(size: 16))
                    .foregroundColor(CoachTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Ambient confidence meter
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 16)
                    .frame(width: 180, height: 180)

                // Progress arc
                Circle()
                    .trim(from: 0, to: animatedScore / 100)
                    .stroke(
                        LinearGradient(
                            colors: [session.topic.color, CoachTheme.success],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: 4) {
                    Text("\(Int(animatedScore))%")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(CoachTheme.primaryText)
                        .contentTransition(.numericText())

                    Text("confident")
                        .font(.system(size: 14))
                        .foregroundColor(CoachTheme.secondaryText)
                }
            }
            .padding(.vertical, 20)

            // Progress milestones
            VStack(spacing: 16) {
                ConfidenceMilestone(
                    icon: "book.fill",
                    title: "Understood your bill",
                    isComplete: session.completedSteps.contains(.billWalkthrough)
                )

                ConfidenceMilestone(
                    icon: "slider.horizontal.3",
                    title: "Saw potential savings",
                    isComplete: session.completedSteps.contains(.whatIfSlider)
                )

                ConfidenceMilestone(
                    icon: "checkmark.circle.fill",
                    title: "Tested your knowledge",
                    isComplete: session.completedSteps.contains(.decisionQuiz)
                )

                ConfidenceMilestone(
                    icon: "target",
                    title: "Have an action plan",
                    isComplete: session.missionStarted
                )
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)

            // Encouraging message
            Text("Paycheck-to-paycheck is a situation, not an identity. You're proving that right now.")
                .font(.system(size: 14))
                .foregroundColor(CoachTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animatedScore = session.confidenceScore
            }
        }
    }
}

private struct ConfidenceMilestone: View {
    let icon: String
    let title: String
    let isComplete: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isComplete ? CoachTheme.success : Color.gray.opacity(0.4))
                .frame(width: 32, height: 32)
                .background(isComplete ? CoachTheme.success.opacity(0.12) : Color.gray.opacity(0.08))
                .cornerRadius(8)

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(isComplete ? CoachTheme.primaryText : CoachTheme.secondaryText)

            Spacer()

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(CoachTheme.success)
            }
        }
    }
}

// MARK: - Step 6: Community Comparison

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

            // Community insights (never leaderboard - just inline callouts)
            VStack(spacing: 16) {
                ForEach(session.communityInsights) { insight in
                    CommunityInsightCard(insight: insight, color: session.topic.color)
                }
            }

            // Final summary card
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(CoachTheme.success)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your potential savings")
                            .font(.system(size: 14))
                            .foregroundColor(CoachTheme.secondaryText)

                        Text("$\(String(format: "%.2f", session.totalPotentialSavings))/month")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(CoachTheme.success)

                        Text("$\(String(format: "%.2f", session.totalPotentialSavings * 12))/year")
                            .font(.system(size: 14))
                            .foregroundColor(CoachTheme.secondaryText)
                    }
                }

                Divider()

                Text("Small wins add up. You've got this.")
                    .font(.system(size: 14))
                    .foregroundColor(CoachTheme.secondaryText)
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
            // Percentage badge
            Text("\(insight.percentage)%")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(insight.percentage)% of \(insight.context)")
                    .font(.system(size: 13))
                    .foregroundColor(CoachTheme.secondaryText)

                Text(insight.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(CoachTheme.primaryText)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Coach Confetti View

private struct CoachConfettiView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<50, id: \.self) { index in
                CoachConfettiPiece(
                    size: geo.size,
                    index: index
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct CoachConfettiPiece: View {
    let size: CGSize
    let index: Int

    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    var body: some View {
        Rectangle()
            .fill(colors[index % colors.count])
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(rotation))
            .position(position)
            .opacity(opacity)
            .onAppear {
                position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                )

                withAnimation(.linear(duration: Double.random(in: 2...3))) {
                    position = CGPoint(
                        x: position.x + CGFloat.random(in: -100...100),
                        y: size.height + 50
                    )
                    rotation = Double.random(in: 360...720)
                }

                withAnimation(.linear(duration: 2).delay(1)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview

#Preview {
    BillCoachFlowView(topic: .negotiateInternet)
}
