//
//  BillAnalysisNewComponents.swift
//  Billix
//
//  Created by Claude Code on 11/28/25.
//  New components for enhanced bill analysis features
//

import SwiftUI

// MARK: - Plain English Summary Card

struct PlainEnglishSummaryCard: View {
    let summary: String
    @State private var appeared = false

    // Split summary into sentences for better readability
    private var summaryPoints: [String] {
        let sentences = summary.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return sentences.map { sentence in
            sentence.hasSuffix(".") ? sentence : sentence + "."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixChartBlue)

                Text("Quick Summary")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixDarkGreen)
            }

            // Display as bullet points
            VStack(alignment: .leading, spacing: 10) {
                ForEach(summaryPoints.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.billixChartBlue)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(summaryPoints[index])
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.billixDarkGreen)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.billixChartBlue.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.billixChartBlue.opacity(0.2), lineWidth: 1.5)
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Red Flags Alert Card

struct RedFlagsAlertCard: View {
    let redFlags: [BillAnalysis.RedFlag]
    @State private var isExpanded: Bool = false
    @State private var appeared = false

    private var displayedFlags: [BillAnalysis.RedFlag] {
        isExpanded ? redFlags : Array(redFlags.prefix(2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixVotePink)

                Text("Red Flags Detected")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixVotePink)

                Spacer()

                // Flag count badge
                Text("\(redFlags.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.billixVotePink))
            }

            VStack(spacing: 10) {
                ForEach(displayedFlags) { flag in
                    RedFlagRow(flag: flag)
                }
            }

            if redFlags.count > 2 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(isExpanded ? "Show Less" : "Show All (\(redFlags.count))")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.billixVotePink)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.billixVotePink.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.billixVotePink.opacity(0.3), lineWidth: 2)
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct RedFlagRow: View {
    let flag: BillAnalysis.RedFlag

    private var typeColor: Color {
        switch flag.type.lowercased() {
        case "high": return .billixVotePink
        case "medium": return .billixSavingsOrange
        case "low": return .billixSavingsYellow
        default: return .billixMediumGreen
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Type badge
                Text(flag.type.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(typeColor))

                VStack(alignment: .leading, spacing: 4) {
                    Text(flag.description)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.billixDarkGreen)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(flag.recommendation)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.billixMediumGreen)
                        .fixedSize(horizontal: false, vertical: true)

                    // Show potential savings if available
                    if let savings = flag.potentialSavings {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.billixMoneyGreen)
                            Text("Save ~$\(Int(savings))/mo")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.billixMoneyGreen)
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - What You Can Control Section

struct ControlAnalysisSection: View {
    let controlAnalysis: BillAnalysis.ControlAnalysis
    @State private var appeared = false

    private var totalCost: Double {
        controlAnalysis.fixedCosts.total + controlAnalysis.variableCosts.total
    }

    private var fixedPercentage: Double {
        totalCost > 0 ? (controlAnalysis.fixedCosts.total / totalCost) * 100 : 0
    }

    private var variablePercentage: Double {
        totalCost > 0 ? (controlAnalysis.variableCosts.total / totalCost) * 100 : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixChartBlue)

                Text("Cost Control Analysis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                // Show controllable percentage badge
                Text("\(Int(controlAnalysis.controllablePercentage))% controllable")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.billixMoneyGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.billixMoneyGreen.opacity(0.15))
                    )
            }

            // Detailed breakdown sections
            VStack(spacing: 16) {
                // Fixed Costs - What You Don't Control
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What You Don't Control")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.billixVotePink)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        HStack {
                            Text("Fixed Costs")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.billixVotePink)

                            Spacer()

                            Text("$\(String(format: "%.2f", controlAnalysis.fixedCosts.total))")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.billixVotePink)
                        }
                    }

                    Text(controlAnalysis.fixedCosts.explanation)
                        .font(.system(size: 12))
                        .foregroundColor(.billixLightGreenText)
                        .fixedSize(horizontal: false, vertical: true)

                    // Items list
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(controlAnalysis.fixedCosts.items, id: \.self) { item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.billixVotePink.opacity(0.6))
                                    .frame(width: 4, height: 4)

                                Text(item)
                                    .font(.system(size: 12))
                                    .foregroundColor(.billixLightGreenText)
                            }
                        }
                    }
                    .padding(.leading, 8)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.billixVotePink.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.billixVotePink.opacity(0.2), lineWidth: 1)
                        )
                )

                // Variable Costs - What You Control
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What You Control")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.billixMoneyGreen)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        HStack {
                            Text("Variable Costs")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.billixMoneyGreen)

                            Spacer()

                            Text("$\(String(format: "%.2f", controlAnalysis.variableCosts.total))")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.billixMoneyGreen)
                        }
                    }

                    Text(controlAnalysis.variableCosts.explanation)
                        .font(.system(size: 12))
                        .foregroundColor(.billixLightGreenText)
                        .fixedSize(horizontal: false, vertical: true)

                    // Items list
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(controlAnalysis.variableCosts.items, id: \.self) { item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.billixMoneyGreen.opacity(0.6))
                                    .frame(width: 4, height: 4)

                                Text(item)
                                    .font(.system(size: 12))
                                    .foregroundColor(.billixLightGreenText)
                            }
                        }
                    }
                    .padding(.leading, 8)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.billixMoneyGreen.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.billixMoneyGreen.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Line Item Badge Components

struct NegotiableBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 9))
            Text("NEGOTIABLE")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundColor(.billixSavingsOrange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.billixSavingsOrange.opacity(0.12))
        )
    }
}

struct AvoidableBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 9))
            Text("AVOIDABLE")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundColor(.billixMoneyGreen)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.billixMoneyGreen.opacity(0.12))
        )
    }
}

// MARK: - Ways to Save Section

struct WaysToSaveSection: View {
    let actionItems: [BillAnalysis.ActionItem]
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixMoneyGreen)

                Text("Ways to Save")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                // Total potential savings badge
                let totalSavings = actionItems.reduce(0.0) { $0 + ($1.potentialSavings ?? 0) }
                if totalSavings > 0 {
                    Text("+$\(Int(totalSavings))/mo")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.billixMoneyGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.billixMoneyGreen.opacity(0.15))
                        )
                }
            }

            VStack(spacing: 12) {
                ForEach(actionItems) { item in
                    ActionItemCard(item: item)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.billixMoneyGreen.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.billixMoneyGreen.opacity(0.2), lineWidth: 1.5)
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

struct ActionItemCard: View {
    let item: BillAnalysis.ActionItem

    private var difficultyColor: Color {
        switch item.difficulty.lowercased() {
        case "easy": return .billixMoneyGreen
        case "medium": return .billixSavingsYellow
        case "hard": return .billixSavingsOrange
        default: return .billixMediumGreen
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.action)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.billixDarkGreen)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        // Difficulty badge
                        Text(item.difficulty.uppercased())
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(difficultyColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(difficultyColor.opacity(0.15))
                            )

                        // Category badge
                        Text(item.category)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.billixChartBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.billixChartBlue.opacity(0.12))
                            )
                    }
                }

                Spacer()

                // Potential savings
                if let savings = item.potentialSavings {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(Int(savings))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.billixMoneyGreen)

                        Text("per month")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.billixLightGreenText)
                    }
                }
            }

            // Explanation
            Text(item.explanation)
                .font(.system(size: 13))
                .foregroundColor(.billixMediumGreen)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Jargon Decoder Section

struct JargonDecoderSection: View {
    let glossary: [BillAnalysis.GlossaryTerm]
    @State private var isExpanded: Bool = false
    @State private var searchText: String = ""
    @State private var appeared = false

    private var filteredTerms: [BillAnalysis.GlossaryTerm] {
        if searchText.isEmpty {
            return glossary.sorted { $0.term < $1.term }
        }
        return glossary.filter {
            $0.term.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.term < $1.term }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixChartBlue)

                    Text("Jargon Decoder")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.billixDarkGreen)

                    Spacer()

                    Text("\(glossary.count) terms")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.billixMediumGreen)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(spacing: 10) {
                    // Search bar
                    if glossary.count > 5 {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundColor(.billixMediumGreen)

                            TextField("Search terms...", text: $searchText)
                                .font(.system(size: 14))
                                .foregroundColor(.billixDarkGreen)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.billixLightGreen.opacity(0.5))
                        )
                    }

                    // Terms list
                    VStack(spacing: 0) {
                        ForEach(Array(filteredTerms.enumerated()), id: \.element.id) { index, term in
                            JargonTermRow(term: term)

                            if index < filteredTerms.count - 1 {
                                Divider()
                                    .background(Color.billixBorderGreen)
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

struct JargonTermRow: View {
    let term: BillAnalysis.GlossaryTerm
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(term.term)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.billixDarkGreen)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.billixChartBlue)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Text(term.definition)
                        .font(.system(size: 13))
                        .foregroundColor(.billixMediumGreen)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.billixChartBlue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Context:")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.billixMediumGreen)

                            Text(term.context)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.billixChartBlue)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.leading, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }
}

// MARK: - Comparison Bar Card

struct ComparisonBarCard: View {
    let position: BillAnalysis.MarketplaceComparison.Position
    let percentDiff: Double
    let areaAverage: Double
    let yourAmount: Double

    @State private var animatedPosition: CGFloat = 0.5

    private var userPosition: CGFloat {
        switch position {
        case .below:
            return max(0.15, 0.5 - (abs(percentDiff) / 100))
        case .average:
            return 0.5
        case .above:
            return min(0.85, 0.5 + (abs(percentDiff) / 100))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixChartBlue)

                Text("Marketplace Comparison")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixDarkGreen)
            }

            // Your Amount vs Average
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Bill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text("$\(String(format: "%.2f", yourAmount))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Area Average")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text("$\(String(format: "%.2f", areaAverage))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.billixMediumGreen)
                }
            }

            // Gradient bar with marker
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Gradient background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.billixMoneyGreen, .billixSavingsYellow, .statusOverpaying],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 12)

                        // Average marker (center)
                        Rectangle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 3, height: 18)
                            .offset(x: geometry.size.width * 0.5 - 1.5)

                        // User position marker
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(markerColor, lineWidth: 3)
                            )
                            .offset(x: geometry.size.width * animatedPosition - 10)
                    }
                }
                .frame(height: 20)
                .onAppear {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                        animatedPosition = userPosition
                    }
                }

                // Status text
                Text(statusMessage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(markerColor)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    private var markerColor: Color {
        switch position {
        case .below: return .billixMoneyGreen
        case .average: return .billixChartBlue
        case .above: return .statusOverpaying
        }
    }

    private var statusMessage: String {
        let diff = abs(percentDiff)
        switch position {
        case .below:
            return "Great news! You're paying \(String(format: "%.0f", diff))% below average"
        case .average:
            return "You're paying the area average"
        case .above:
            return "You're paying \(String(format: "%.0f", diff))% above average"
        }
    }
}

// MARK: - Previews

#Preview("Plain English Summary") {
    PlainEnglishSummaryCard(
        summary: "Your November electric bill is $142.50, due December 15th. You used 147 kWh of electricity, which is about average for a home your size."
    )
    .padding()
    .background(Color.billixLightGreen)
}

#Preview("Red Flags") {
    RedFlagsAlertCard(
        redFlags: [
            BillAnalysis.RedFlag(type: "high", description: "Service fee appears twice on your bill", recommendation: "Contact your provider to remove the duplicate charge", potentialSavings: 15.0),
            BillAnalysis.RedFlag(type: "medium", description: "Your electricity rate went up 15% since last month", recommendation: "Review rate change notice and consider switching plans", potentialSavings: 8.0),
            BillAnalysis.RedFlag(type: "low", description: "You were charged a $5 late fee", recommendation: "Set up autopay to avoid future late fees", potentialSavings: 5.0)
        ]
    )
    .padding()
    .background(Color.billixLightGreen)
}

#Preview("Control Analysis") {
    ControlAnalysisSection(
        controlAnalysis: BillAnalysis.ControlAnalysis(
            fixedCosts: BillAnalysis.ControlAnalysis.CostDetail(
                total: 45.0,
                items: ["Service Charge ($8.50)", "LIEAF Factor ($1.25)", "Sales Tax ($1.50)"],
                explanation: "These charges stay the same regardless of usage"
            ),
            variableCosts: BillAnalysis.ControlAnalysis.CostDetail(
                total: 97.5,
                items: ["On Peak Charges ($12.46)", "Off Peak Charges ($35.54)", "Distribution Charge ($49.50)"],
                explanation: "These charges depend on how much electricity you consume"
            ),
            controllablePercentage: 68.0
        )
    )
    .padding()
    .background(Color.billixLightGreen)
}

#Preview("Ways to Save") {
    WaysToSaveSection(
        actionItems: [
            BillAnalysis.ActionItem(
                action: "Switch to Off-Peak Hours",
                explanation: "Most of your usage happens during peak hours (2-7pm). Shifting laundry and dishwasher to off-peak could save money.",
                potentialSavings: 25.0,
                difficulty: "easy",
                category: "usage"
            ),
            BillAnalysis.ActionItem(
                action: "Negotiate Service Fee",
                explanation: "Your $15/month service fee is higher than average. Call and ask for a reduction.",
                potentialSavings: 8.0,
                difficulty: "medium",
                category: "plan"
            )
        ]
    )
    .padding()
    .background(Color.billixLightGreen)
}

#Preview("Jargon Decoder") {
    JargonDecoderSection(
        glossary: [
            BillAnalysis.GlossaryTerm(
                term: "kWh",
                definition: "Kilowatt-hour: A unit of energy equal to 1,000 watts used for one hour.",
                context: "If you run a 100W light bulb for 10 hours, that's 1 kWh."
            ),
            BillAnalysis.GlossaryTerm(
                term: "Peak Hours",
                definition: "Times when electricity demand is highest, typically 2-7pm on weekdays.",
                context: "Your peak rate is $0.25/kWh vs $0.12/kWh off-peak."
            ),
            BillAnalysis.GlossaryTerm(
                term: "Delivery Charge",
                definition: "The cost to transport electricity from the power plant to your home.",
                context: "This covers the infrastructure to bring power to your home."
            )
        ]
    )
    .padding()
    .background(Color.billixLightGreen)
}
