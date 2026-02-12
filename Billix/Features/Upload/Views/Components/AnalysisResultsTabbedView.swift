//
//  AnalysisResultsTabbedView.swift
//  Billix
//
//  Created by Claude Code on 11/28/25.
//  Redesigned analysis view with hero section + swipeable tabs
//

import SwiftUI
import Charts

// MARK: - Main View (Dark Glassmorphic Single-Scroll)

struct AnalysisResultsTabbedView: View {
    let analysis: BillAnalysis
    let onComplete: () -> Void
    var showDoneButton: Bool = true
    var billId: UUID? = nil  // For chat session persistence

    // Keep enum for embedded version compatibility
    enum AnalysisTabType: String, CaseIterable {
        case summary = "Summary"
        case details = "Details"

        var icon: String {
            switch self {
            case .summary: return "square.grid.2x2.fill"
            case .details: return "list.bullet.rectangle.fill"
            }
        }
    }

    @State private var appeared = false
    @State private var mascotFloating = false
    @State private var coinAtTop = true
    @State private var detailsExpanded = false
    @State private var expandedLineItems: Set<String> = []
    @State private var animatedPosition: CGFloat = 0.5
    @State private var redFlagsExpanded = false
    @State private var jargonExpanded = false
    @State private var showScrollIndicator = true
    @State private var showAskBillix = false

    var body: some View {
        ZStack {
            // Background gradient (matches upload screen)
            LinearGradient(
                colors: [
                    Color.billixDarkGreen.opacity(0.9),
                    Color.billixMoneyGreen.opacity(0.75),
                    Color.billixDarkGreen.opacity(0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed top section (doesn't scroll)
                VStack(spacing: 6) {
                    mascotSection
                    askBillixButton
                    statPillsRow
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                // Scrollable cards (clipped so content doesn't overlap pills)
                ZStack(alignment: .bottom) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Card 1: Comparison (if available)
                            if analysis.marketplaceComparison != nil {
                                comparisonCard
                            }

                            // Card 2: Quick Summary
                            if let summary = analysis.plainEnglishSummary {
                                summaryCard(summary)
                            }

                            // Card 3: Cost Breakdown
                            costBreakdownCard

                            // Card 4: Red Flags
                            if let redFlags = analysis.redFlags, !redFlags.isEmpty {
                                redFlagsCard(redFlags)
                            }

                            // Card 5: Control Analysis + Insights
                            if analysis.controllableCosts != nil || (analysis.insights != nil && !(analysis.insights!.isEmpty)) {
                                insightsCard
                            }

                            // Card 6: Details (collapsible)
                            detailsCard

                            // Bottom scroll anchor
                            GeometryReader { geo in
                                Color.clear
                                    .onChange(of: geo.frame(in: .global).minY) { _, newValue in
                                        let screenHeight = UIScreen.main.bounds.height
                                        let isBottomVisible = newValue < screenHeight - 40
                                        if isBottomVisible != !showScrollIndicator {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                showScrollIndicator = !isBottomVisible
                                            }
                                        }
                                    }
                            }
                            .frame(height: 1)

                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }

                    // Scroll indicator (shows when more content below)
                    if showScrollIndicator && !detailsExpanded {
                        VStack(spacing: 2) {
                            Image(systemName: "chevron.compact.down")
                                .font(.system(size: 22, weight: .semibold))
                            Text("Scroll for more")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.bottom, 8)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                    }
                }
                .clipped()

                // Done button (hidden when toolbar provides one)
                if showDoneButton {
                    doneButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAskBillix) {
            AskBillixChatView(analysis: analysis, billId: billId)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
            mascotFloating = true
            let timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 1.5)) {
                    coinAtTop.toggle()
                }
            }
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    // MARK: - Mascot Section

    private var mascotSection: some View {
        ZStack {
            // Outer glass ring
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 130, height: 130)
                .blur(radius: 0.5)

            // Inner glass ring
            Circle()
                .fill(Color.black.opacity(0.2))
                .frame(width: 100, height: 100)

            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 65
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 10)

            // Piggy
            Image("HoloPiggy")
                .resizable()
                .scaledToFit()
                .frame(width: 165, height: 165)
                .offset(y: mascotFloating ? -3 : 3)
            .animation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: mascotFloating
            )
        }
        .frame(height: 130)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.8)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appeared)
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            showAskBillix = true
        }
    }

    // MARK: - Ask Billix Button

    private var askBillixButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            showAskBillix = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Ask Billix")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.billixDarkGreen.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)
    }

    // MARK: - Stat Pills (2-row layout)

    private var statPillsRow: some View {
        VStack(spacing: 6) {
            // Top row: Your Bill + Provider (larger, primary info)
            HStack(spacing: 6) {
                statPillLarge(icon: "dollarsign.circle.fill", label: "$\(String(format: "%.2f", analysis.amount))", subtitle: "Your Bill")
                statPillLarge(icon: categoryIcon, label: analysis.provider, subtitle: analysis.category)
            }

            // Bottom row: Health + Due Date (smaller, secondary info)
            HStack(spacing: 6) {
                statPillSmall(icon: "heart.fill", label: "Bill Health", subtitle: "\(calculateHealthScore()) • \(healthStatus) vs avg", statusColor: healthScoreColor)
                if let dueDate = analysis.dueDate {
                    let dueSub = daysUntilDue(dueDate)
                    let dueColor: Color? = dueSub == "Overdue" ? .red : (dueSub == "Today" || dueSub == "Tomorrow" ? .orange : nil)
                    statPillSmall(icon: "calendar", label: formatDateShort(dueDate), subtitle: dueSub, statusColor: dueColor)
                } else {
                    statPillSmall(icon: "calendar", label: formatDateShort(analysis.billDate), subtitle: "Bill Date")
                }
            }
        }
        .padding(.top, 6)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
    }

    // Large pill for primary info (Your Bill, Provider)
    private func statPillLarge(icon: String, label: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }

    // Small pill for secondary info (Health, Due Date)
    private func statPillSmall(icon: String, label: String, subtitle: String, statusColor: Color? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 3) {
                    if let dotColor = statusColor {
                        Circle()
                            .fill(dotColor)
                            .frame(width: 5, height: 5)
                    }
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(statusColor ?? .white.opacity(0.55))
                }
            }

            Spacer(minLength: 0)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.15))
        )
    }

    private var healthScoreColor: Color {
        let score = calculateHealthScore()
        switch score {
        case 80...100: return .mint
        case 60..<80: return .cyan
        case 40..<60: return .yellow
        default: return .red
        }
    }

    // MARK: - Card 1: Comparison

    private var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let comparison = analysis.marketplaceComparison {
                // Header with your bill vs average
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your Bill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text("$\(String(format: "%.2f", analysis.amount))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Billix Average")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text("$\(String(format: "%.2f", comparison.areaAverage))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Comparison bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.billixMoneyGreen, .billixSavingsYellow, .statusOverpaying],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 10)

                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 2, height: 16)
                            .offset(x: geometry.size.width * 0.5 - 1)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 18, height: 18)
                            .shadow(color: .black.opacity(0.3), radius: 3)
                            .overlay(
                                Circle()
                                    .stroke(comparisonMarkerColor, lineWidth: 2.5)
                            )
                            .offset(x: geometry.size.width * animatedPosition - 9)
                    }
                }
                .frame(height: 18)
                .onAppear {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                        animatedPosition = comparisonUserPosition
                    }
                }

                HStack {
                    Text(comparisonStatusMessage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    if let state = comparison.state, let sampleSize = comparison.sampleSize, sampleSize >= 5 {
                        Text("\(sampleSize) bills in \(state)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.billixGoldenAmber.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Card 2: Quick Summary

    private func summaryCard(_ summary: String) -> some View {
        let points = summary.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.hasSuffix(".") ? $0 : $0 + "." }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("Quick Summary")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(points.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(points[index])
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }

    // MARK: - Card 3: Cost Breakdown

    private var costBreakdownCard: some View {
        let items: [(String, Double)] = {
            if let breakdown = analysis.costBreakdown, !breakdown.isEmpty {
                return breakdown.sorted(by: { $0.amount > $1.amount }).map { ($0.category, $0.amount) }
            }
            return analysis.lineItems.prefix(6).sorted(by: { $0.amount > $1.amount }).map { ($0.description, $0.amount) }
        }()

        let total = items.reduce(0) { $0 + $1.1 }

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("Cost Breakdown")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    let percentage = total > 0 ? (item.1 / total) * 100 : 0

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.0)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(1)

                            Spacer()

                            Text("$\(String(format: "%.2f", item.1))")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)

                            Text("\(Int(percentage))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 30, alignment: .trailing)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: geometry.size.width * CGFloat(percentage / 100))
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }

            // Total row
            HStack {
                Text("Total")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("$\(String(format: "%.2f", analysis.amount))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }

    // MARK: - Card 4: Red Flags

    private func redFlagsCard(_ redFlags: [BillAnalysis.RedFlag]) -> some View {
        let displayed = redFlagsExpanded ? redFlags : Array(redFlags.prefix(2))

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.billixSavingsOrange)
                Text("\(redFlags.count) Issue\(redFlags.count > 1 ? "s" : "") Found")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }

            ForEach(displayed) { flag in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(flag.type.uppercased())
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(flagColor(flag.type)))

                        Text(flag.description)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text("→ \(flag.recommendation)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.leading, 8)

                    if let savings = flag.potentialSavings, savings > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 11))
                            Text("Save ~$\(Int(savings))/mo")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.billixMoneyGreen)
                        .padding(.leading, 8)
                    }
                }
            }

            if redFlags.count > 2 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        redFlagsExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(redFlagsExpanded ? "Show Less" : "Show All (\(redFlags.count))")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: redFlagsExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.billixSavingsOrange)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.billixSavingsOrange.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Card 5: Insights + Control Analysis

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixSavingsYellow)
                Text("Insights")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            // Control Analysis
            if let control = analysis.controllableCosts {
                HStack(alignment: .top, spacing: 12) {
                    // YOU CONTROL card
                    VStack(alignment: .leading, spacing: 4) {
                        Text("YOU CONTROL")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(0.5)
                        Text("$\(String(format: "%.0f", control.variableCosts.total))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("\(Int(control.controllablePercentage))%")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))

                        // Items list
                        if !control.variableCosts.items.isEmpty {
                            Divider()
                                .background(Color.white.opacity(0.3))
                                .padding(.vertical, 4)
                            ForEach(control.variableCosts.items.prefix(3), id: \.self) { item in
                                HStack(alignment: .top, spacing: 5) {
                                    Text("•")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white.opacity(0.9))
                                    Text(item)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.billixMoneyGreen.opacity(0.25))
                    )

                    // FIXED card
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FIXED")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(0.5)
                        Text("$\(String(format: "%.0f", control.fixedCosts.total))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("\(100 - Int(control.controllablePercentage))%")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))

                        // Items list
                        if !control.fixedCosts.items.isEmpty {
                            Divider()
                                .background(Color.white.opacity(0.3))
                                .padding(.vertical, 4)
                            ForEach(control.fixedCosts.items.prefix(3), id: \.self) { item in
                                HStack(alignment: .top, spacing: 5) {
                                    Text("•")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white.opacity(0.9))
                                    Text(item)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.billixVotePink.opacity(0.2))
                    )
                }
            }

            // AI Insights
            if let insights = analysis.insights, !insights.isEmpty {
                ForEach(insights, id: \.title) { insight in
                    HStack(spacing: 12) {
                        Image(systemName: insightIcon(insight.type))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(insightColor(insight.type))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(insight.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text(insight.description)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.75))
                                .lineLimit(3)
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(insightColor(insight.type).opacity(0.12))
                    )
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }

    // MARK: - Card 6: Details (Collapsible)

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible, tappable)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    detailsExpanded.toggle()
                    if detailsExpanded {
                        // Auto-expand all line items that have details
                        for item in analysis.lineItems where item.quantity != nil || item.explanation != nil {
                            expandedLineItems.insert(item.id)
                        }
                    } else {
                        expandedLineItems.removeAll()
                    }
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Text("Details")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: detailsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(18)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))

            if detailsExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Key Facts
                    VStack(spacing: 8) {
                        detailRow(label: "Provider", value: analysis.provider)
                        detailRow(label: "Category", value: analysis.category)
                        detailRow(label: "Bill Date", value: formatDateLong(analysis.billDate))
                        if let dueDate = analysis.dueDate {
                            detailRow(label: "Due Date", value: formatDateLong(dueDate))
                        }
                        if let account = analysis.accountNumber {
                            detailRow(label: "Account", value: account)
                        }
                        if let zip = analysis.zipCode {
                            detailRow(label: "ZIP Code", value: zip)
                        }
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 1)

                    // Line Items
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                let allExpanded = expandedLineItems.count == analysis.lineItems.filter({ $0.quantity != nil || $0.explanation != nil }).count
                                if allExpanded {
                                    expandedLineItems.removeAll()
                                } else {
                                    for item in analysis.lineItems where item.quantity != nil || item.explanation != nil {
                                        expandedLineItems.insert(item.id)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("LINE ITEMS (\(analysis.lineItems.count))")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.55))
                                    .tracking(0.5)
                                Spacer()
                                Image(systemName: expandedLineItems.isEmpty ? "chevron.down" : "chevron.up")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        ForEach(analysis.lineItems) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if expandedLineItems.contains(item.id) {
                                            expandedLineItems.remove(item.id)
                                        } else {
                                            expandedLineItems.insert(item.id)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        if item.quantity != nil || item.explanation != nil {
                                            Image(systemName: expandedLineItems.contains(item.id) ? "chevron.down" : "chevron.right")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white.opacity(0.4))
                                                .frame(width: 14)
                                        } else {
                                            Circle()
                                                .fill(Color.white.opacity(0.3))
                                                .frame(width: 5, height: 5)
                                                .frame(width: 14)
                                        }

                                        Text(item.description)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineLimit(1)

                                        Spacer()

                                        Text("$\(String(format: "%.2f", item.amount))")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())

                                if expandedLineItems.contains(item.id) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let qty = item.quantity, let rate = item.rate {
                                            Text("\(String(format: "%.0f", qty)) \(item.unit ?? "units") × $\(String(format: "%.4f", rate))/\(item.unit ?? "unit")")
                                                .font(.system(size: 13))
                                                .foregroundColor(.white.opacity(0.55))
                                        }
                                        if let explanation = item.explanation {
                                            Text(explanation)
                                                .font(.system(size: 13))
                                                .foregroundColor(.white.opacity(0.55))
                                        }
                                    }
                                    .padding(.leading, 14)
                                    .transition(.opacity)
                                }
                            }

                            if item.id != analysis.lineItems.last?.id {
                                Rectangle()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 1)
                            }
                        }

                        // Total
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 1)

                        HStack {
                            Text("Total")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("$\(String(format: "%.2f", analysis.amount))")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }

                    // Jargon Decoder
                    if let glossary = analysis.jargonGlossary, !glossary.isEmpty {
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)

                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    jargonExpanded.toggle()
                                }
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            } label: {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("Jargon Decoder (\(glossary.count) terms)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                    Spacer()
                                    Image(systemName: jargonExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())

                            if jargonExpanded {
                                ForEach(glossary.sorted(by: { $0.term < $1.term })) { term in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(term.term)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white.opacity(0.95))
                                        Text(term.definition)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(term.context)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.5))
                                            .italic()
                                    }
                                    .padding(.vertical, 4)
                                }
                                .transition(.opacity)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
                .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button {
            onComplete()
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            HStack(spacing: 8) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.billixMoneyGreen, .billixMoneyGreen.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: .billixMoneyGreen.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Helpers

    private var categoryIcon: String {
        switch analysis.category.lowercased() {
        case "electric", "electricity": return "bolt.fill"
        case "gas": return "flame.fill"
        case "water": return "drop.fill"
        case "internet": return "wifi"
        case "phone", "mobile": return "phone.fill"
        case "cable", "tv": return "tv.fill"
        default: return "building.2.fill"
        }
    }

    private func formatDateShort(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "yyyy-MM-dd"
        if let date = altFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    private func formatDateLong(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy"
            return displayFormatter.string(from: date)
        }
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "yyyy-MM-dd"
        if let date = altFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy"
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    private func daysUntilDue(_ dateString: String) -> String {
        var dueDate: Date?
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: dateString) { dueDate = d }
        else {
            let alt = DateFormatter()
            alt.dateFormat = "yyyy-MM-dd"
            dueDate = alt.date(from: dateString)
        }
        guard let due = dueDate else { return "" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
        if days < 0 { return "Overdue" }
        else if days == 0 { return "Today" }
        else if days == 1 { return "Tomorrow" }
        else { return "\(days) days" }
    }

    private func calculateHealthScore() -> Int {
        var score = 70
        if let comparison = analysis.marketplaceComparison {
            switch comparison.position {
            case .below: score += 20 + Int(min(abs(comparison.percentDiff), 20))
            case .average: score += 10
            case .above: score -= Int(min(comparison.percentDiff, 30))
            }
        }
        if let insights = analysis.insights, !insights.isEmpty {
            score += insights.filter { $0.type == .savings }.count * 5
        }
        return max(20, min(100, score))
    }

    private var healthStatus: String {
        let score = calculateHealthScore()
        switch score {
        case 80...100: return "Great"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Poor"
        }
    }

    private var comparisonUserPosition: CGFloat {
        guard let comparison = analysis.marketplaceComparison else { return 0.5 }
        switch comparison.position {
        case .below: return max(0.15, 0.5 - (abs(comparison.percentDiff) / 100))
        case .average: return 0.5
        case .above: return min(0.85, 0.5 + (abs(comparison.percentDiff) / 100))
        }
    }

    private var comparisonMarkerColor: Color {
        guard let comparison = analysis.marketplaceComparison else { return .billixChartBlue }
        switch comparison.position {
        case .below: return .billixMoneyGreen
        case .average: return .billixChartBlue
        case .above: return .statusOverpaying
        }
    }

    private var comparisonStatusMessage: String {
        guard let comparison = analysis.marketplaceComparison else { return "" }
        let diff = abs(comparison.percentDiff)
        switch comparison.position {
        case .below: return "\(String(format: "%.0f", diff))% below Billix average"
        case .average: return "At Billix average"
        case .above: return "\(String(format: "%.0f", diff))% above Billix average"
        }
    }

    private func flagColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "high": return .billixVotePink
        case "medium": return .billixSavingsOrange
        case "low": return .billixSavingsYellow
        default: return .billixMediumGreen
        }
    }

    private func insightIcon(_ type: BillAnalysis.Insight.InsightType) -> String {
        switch type {
        case .savings: return "dollarsign.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }

    private func insightColor(_ type: BillAnalysis.Insight.InsightType) -> Color {
        switch type {
        case .savings: return .billixMoneyGreen
        case .warning: return .billixSavingsOrange
        case .info: return .billixChartBlue
        case .success: return .billixMoneyGreen
        }
    }
}

// MARK: - Compact Comparison Bar

struct CompactComparisonBar: View {
    let position: BillAnalysis.MarketplaceComparison.Position
    let percentDiff: Double
    let areaAverage: Double

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
        VStack(spacing: 8) {
            // Gradient bar with marker
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Gradient background
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [.billixMoneyGreen, .billixSavingsYellow, .statusOverpaying],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 10)

                    // Average marker (center)
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 2, height: 14)
                        .offset(x: geometry.size.width * 0.5 - 1)

                    // User position marker
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                        .overlay(
                            Circle()
                                .stroke(markerColor, lineWidth: 2.5)
                        )
                        .offset(x: geometry.size.width * animatedPosition - 8)
                }
            }
            .frame(height: 16)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
                    animatedPosition = userPosition
                }
            }

            // Status text
            HStack {
                Text(statusMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(markerColor)

                Spacer()

                Text("Avg: $\(String(format: "%.0f", areaAverage))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.billixLightGreenText)
            }
        }
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
            return "\(String(format: "%.0f", diff))% below Billix average"
        case .average:
            return "At Billix average"
        case .above:
            return "\(String(format: "%.0f", diff))% above Billix average"
        }
    }
}

// MARK: - Summary Tab Content

struct SummaryTabContent: View {
    let analysis: BillAnalysis

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 1).id("summaryTop")

                    // Single unified card for all summary content
                    VStack(spacing: 24) {
                        // Key Facts Grid
                        keyFactsGrid

                        // Divider
                        if analysis.insights != nil || analysis.zipCode != nil {
                            Divider()
                                .background(Color.billixBorderGreen)
                                .padding(.vertical, 6)
                        }

                        // Top Insights
                        if let insights = analysis.insights, !insights.isEmpty {
                            insightsSection(Array(insights.prefix(2)))
                        }

                        // Quick stats row
                        if analysis.zipCode != nil || analysis.lineItems.contains(where: { $0.rate != nil }) {
                            quickStatsRow
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    .padding(.bottom, 80)
                }
            }
            .onAppear {
                proxy.scrollTo("summaryTop", anchor: .top)
            }
        }
    }

    private var keyFactsGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            // Category
            SummaryGridItem(
                icon: categoryIcon,
                iconColor: .billixChartBlue,
                label: "CATEGORY",
                value: analysis.category
            )

            // Account
            SummaryGridItem(
                icon: "number",
                iconColor: .billixMediumGreen,
                label: "ACCOUNT",
                value: analysis.accountNumber ?? "N/A"
            )

            // Usage (if available)
            if let usageItem = analysis.lineItems.first(where: { $0.quantity != nil && $0.unit != nil }),
               let quantity = usageItem.quantity, let unit = usageItem.unit {
                SummaryGridItem(
                    icon: "bolt.fill",
                    iconColor: .billixSavingsYellow,
                    label: "USAGE",
                    value: "\(String(format: "%.0f", quantity)) \(unit)"
                )
            } else {
                SummaryGridItem(
                    icon: "calendar",
                    iconColor: .billixSavingsYellow,
                    label: "BILL DATE",
                    value: formatDateShort(analysis.billDate)
                )
            }

            // Line Items Count
            SummaryGridItem(
                icon: "list.bullet",
                iconColor: .billixMoneyGreen,
                label: "LINE ITEMS",
                value: "\(analysis.lineItems.count)"
            )
        }
    }

    private func insightsSection(_ insights: [BillAnalysis.Insight]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixChartBlue)

                Text("AI Insights")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixDarkGreen)
            }

            ForEach(insights, id: \.title) { insight in
                CompactInsightCard(insight: insight)
            }
        }
    }

    private var quickStatsRow: some View {
        HStack(spacing: 10) {
            // ZIP Code
            if let zipCode = analysis.zipCode {
                QuickStatPill(icon: "mappin", label: "ZIP", value: zipCode)
            }

            // Rate (if available)
            if let usageItem = analysis.lineItems.first(where: { $0.rate != nil }),
               let rate = usageItem.rate, let unit = usageItem.unit {
                QuickStatPill(icon: "dollarsign.circle", label: "Rate", value: "$\(String(format: "%.3f", rate))/\(unit)")
            }

            Spacer()
        }
    }

    private var categoryIcon: String {
        switch analysis.category.lowercased() {
        case "electric", "electricity": return "bolt.fill"
        case "gas": return "flame.fill"
        case "water": return "drop.fill"
        case "internet": return "wifi"
        case "phone", "mobile": return "phone.fill"
        case "cable", "tv": return "tv.fill"
        default: return "building.2.fill"
        }
    }

    private func formatDateShort(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "yyyy-MM-dd"
        if let date = altFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Summary Grid Item (inline, no card background)

struct SummaryGridItem: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
                    .tracking(0.4)

                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Summary Grid Card

struct SummaryGridCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
                    .tracking(0.3)

                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Compact Insight Card

struct CompactInsightCard: View {
    let insight: BillAnalysis.Insight

    private var iconInfo: (icon: String, color: Color) {
        switch insight.type {
        case .savings: return ("dollarsign.circle.fill", .billixMoneyGreen)
        case .warning: return ("exclamationmark.triangle.fill", .statusOverpaying)
        case .info: return ("info.circle.fill", .billixChartBlue)
        case .success: return ("checkmark.circle.fill", .billixMoneyGreen)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconInfo.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(iconInfo.color)

            VStack(alignment: .leading, spacing: 3) {
                Text(insight.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Text(insight.description)
                    .font(.system(size: 13))
                    .foregroundColor(.billixMediumGreen)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(iconInfo.color.opacity(0.08))
        )
    }
}

// MARK: - Quick Stat Pill

struct QuickStatPill: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.billixChartBlue)

            Text("\(label): \(value)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.billixChartBlue.opacity(0.08))
        )
    }
}

// MARK: - Breakdown Tab Content

struct BreakdownTabContent: View {
    let analysis: BillAnalysis

    @State private var selectedCategory: String?

    private let categoryColors: [String: Color] = [
        // Energy/Supply - Warm Orange
        "Power Supply": Color(hex: "#F97316"),  // Orange
        "Supply": Color(hex: "#F97316"),
        "Energy": Color(hex: "#EA580C"),  // Darker Orange
        "Energy Charge": Color(hex: "#F97316"),

        // Delivery/Distribution - Teal
        "Delivery": Color(hex: "#14B8A6"),  // Teal
        "Delivery Charges": Color(hex: "#14B8A6"),
        "Distribution": Color(hex: "#0D9488"),  // Darker Teal

        // Time-of-Use - Distinct colors
        "On-Peak": Color(hex: "#DC2626"),  // Red
        "On Peak": Color(hex: "#DC2626"),
        "Off-Peak": Color(hex: "#2563EB"),  // Blue
        "Off Peak": Color(hex: "#2563EB"),
        "Mid-Peak": Color(hex: "#D97706"),  // Amber
        "Mid Peak": Color(hex: "#D97706"),
        "Super Off-Peak": Color(hex: "#7C3AED"),  // Purple

        // Service/Base - Purple shades
        "Service": Color(hex: "#8B5CF6"),  // Violet
        "Service Charge": Color(hex: "#8B5CF6"),
        "Customer Charge": Color(hex: "#A78BFA"),  // Light Violet
        "Base": Color(hex: "#6D28D9"),  // Dark Purple
        "Base Charge": Color(hex: "#6D28D9"),

        // Taxes & Fees - Yellow/Gold
        "Taxes": Color(hex: "#EAB308"),  // Yellow
        "Taxes & Fees": Color(hex: "#EAB308"),
        "Fees": Color(hex: "#CA8A04"),  // Dark Yellow
        "Regulatory": Color(hex: "#FBBF24"),  // Amber
        "Regulatory Fees": Color(hex: "#FBBF24"),
        "Franchise": Color(hex: "#F59E0B"),  // Light Amber

        // Environmental - Green
        "Environmental": Color(hex: "#22C55E"),  // Green
        "Renewable": Color(hex: "#16A34A"),  // Dark Green

        // Usage - Pink
        "Usage": Color(hex: "#EC4899"),  // Pink
        "Usage Charge": Color(hex: "#EC4899"),

        // Other
        "Other": Color(hex: "#64748B")  // Slate
    ]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 1).id("breakdownTop")

                    // Single unified card for all breakdown content
                    VStack(spacing: 20) {
                        // Donut Chart
                        donutChartSection

                        Divider()
                            .background(Color.billixBorderGreen)
                            .padding(.vertical, 4)

                        // Progress Bars
                        progressBarsSection
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    .padding(.bottom, 80)
                }
            }
            .onAppear {
                proxy.scrollTo("breakdownTop", anchor: .top)
            }
        }
    }

    private var donutChartSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Chart(analysis.lineItems.prefix(6)) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(colorFor(item.description))
                    .opacity(selectedCategory == nil || selectedCategory == item.description ? 1 : 0.3)
                    .cornerRadius(4)
                }
                .chartBackground { _ in
                    VStack(spacing: 2) {
                        Text("Total")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.billixMediumGreen)

                        Text("$\(String(format: "%.2f", analysis.amount))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.billixDarkGreen)
                    }
                }
                .chartLegend(.hidden)
            }
            .frame(height: 160)

            // Legend
            VStack(spacing: 6) {
                ForEach(analysis.lineItems.prefix(6).sorted(by: { $0.amount > $1.amount })) { item in
                    let percentage = (item.amount / analysis.amount) * 100
                    ChartLegendRow(
                        category: item.description,
                        amount: item.amount,
                        percentage: percentage,
                        color: colorFor(item.description),
                        isSelected: selectedCategory == item.description,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = selectedCategory == item.description ? nil : item.description
                            }
                        }
                    )
                }
            }
        }
    }

    private var progressBarsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Distribution")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            let totalAmount = analysis.lineItems.reduce(0) { $0 + $1.amount }

            ForEach(analysis.lineItems.prefix(5)) { item in
                TabbedCostBreakdownRow(
                    label: item.description,
                    amount: item.amount,
                    percentage: totalAmount > 0 ? (item.amount / totalAmount) * 100 : 0,
                    color: colorFor(item.description)
                )
            }
        }
    }

    private func colorFor(_ category: String) -> Color {
        let lowercased = category.lowercased()

        // Check for time-of-use patterns first (most specific)
        if lowercased.contains("on peak") || lowercased.contains("on-peak") {
            return Color(hex: "#DC2626")  // Red
        }
        if lowercased.contains("off peak") || lowercased.contains("off-peak") {
            return Color(hex: "#2563EB")  // Blue
        }
        if lowercased.contains("mid peak") || lowercased.contains("mid-peak") {
            return Color(hex: "#D97706")  // Amber
        }

        // Check for other specific patterns
        if lowercased.contains("service") || lowercased.contains("customer charge") {
            return Color(hex: "#8B5CF6")  // Violet
        }
        if lowercased.contains("power supply") || lowercased.contains("energy") || lowercased.contains("supply") {
            return Color(hex: "#F97316")  // Orange
        }
        if lowercased.contains("delivery") || lowercased.contains("distribution") {
            return Color(hex: "#14B8A6")  // Teal
        }
        if lowercased.contains("tax") || lowercased.contains("fee") {
            return Color(hex: "#EAB308")  // Yellow
        }
        if lowercased.contains("regulatory") || lowercased.contains("franchise") {
            return Color(hex: "#FBBF24")  // Light Amber
        }
        if lowercased.contains("environmental") || lowercased.contains("renewable") {
            return Color(hex: "#22C55E")  // Green
        }
        if lowercased.contains("base") {
            return Color(hex: "#6D28D9")  // Dark Purple
        }
        if lowercased.contains("usage") {
            return Color(hex: "#EC4899")  // Pink
        }

        // Fallback color palette
        let colors: [Color] = [
            Color(hex: "#F97316"),  // Orange
            Color(hex: "#14B8A6"),  // Teal
            Color(hex: "#8B5CF6"),  // Violet
            Color(hex: "#EAB308"),  // Yellow
            Color(hex: "#EC4899"),  // Pink
            Color(hex: "#22C55E"),  // Green
            Color(hex: "#DC2626"),  // Red
            Color(hex: "#2563EB"),  // Blue
            Color(hex: "#D97706"),  // Amber
            Color(hex: "#7C3AED")   // Purple
        ]
        return colors[abs(category.hashValue) % colors.count]
    }
}

// MARK: - Chart Legend Row

struct ChartLegendRow: View {
    let category: String
    let amount: Double
    let percentage: Double
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)

                Text(category)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(1)

                Spacer()

                Text("$\(String(format: "%.0f", amount))")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)

                Text("\(Int(percentage))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.12))
                    )
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tabbed Cost Breakdown Row

struct TabbedCostBreakdownRow: View {
    let label: String
    let amount: Double
    let percentage: Double
    let color: Color

    @State private var animatedProgress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(1)

                Spacer()

                Text("$\(String(format: "%.0f", amount))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.12))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * animatedProgress)
                }
            }
            .frame(height: 6)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                    animatedProgress = CGFloat(percentage / 100)
                }
            }
        }
    }
}

// MARK: - Details Tab Content

struct DetailsTabContent: View {
    let analysis: BillAnalysis

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 1).id("detailsTop")

                    // Single unified card for all details content
                    VStack(spacing: 20) {
                        // All Line Items (Grouped)
                        lineItemsSection

                        // All Insights
                        if let insights = analysis.insights, !insights.isEmpty {
                            Divider()
                                .background(Color.billixBorderGreen)
                                .padding(.vertical, 4)

                            allInsightsSection(insights)
                        }

                        // Account Info
                        Divider()
                            .background(Color.billixBorderGreen)
                            .padding(.vertical, 4)

                        accountInfoSection
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    .padding(.bottom, 80)
                }
            }
            .onAppear {
                proxy.scrollTo("detailsTop", anchor: .top)
            }
        }
    }

    private var lineItemsSection: some View {
        let groupedItems = Dictionary(grouping: analysis.lineItems) { $0.category ?? "Other" }
        let sortedCategories = groupedItems.keys.sorted { cat1, cat2 in
            let total1 = groupedItems[cat1]?.reduce(0) { $0 + $1.amount } ?? 0
            let total2 = groupedItems[cat2]?.reduce(0) { $0 + $1.amount } ?? 0
            return total1 > total2
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixChartBlue)

                Text("Line Items")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }

            ForEach(sortedCategories, id: \.self) { category in
                if let items = groupedItems[category] {
                    DetailGroupedSection(category: category, items: items)
                }
            }

            Rectangle()
                .fill(Color.billixBorderGreen)
                .frame(height: 1)

            HStack {
                Text("Total")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Text("$\(String(format: "%.2f", analysis.amount))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.billixMoneyGreen)
            }
        }
    }

    private func allInsightsSection(_ insights: [BillAnalysis.Insight]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixChartBlue)

                Text("All Insights")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }

            ForEach(insights, id: \.title) { insight in
                CompactInsightCard(insight: insight)
            }
        }
    }

    private var accountInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixChartBlue)

                Text("Account Details")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }

            DetailInfoRow(label: "Provider", value: analysis.provider)
            DetailInfoRow(label: "Category", value: analysis.category)
            DetailInfoRow(label: "Bill Date", value: analysis.billDate)

            if let dueDate = analysis.dueDate {
                DetailInfoRow(label: "Due Date", value: dueDate)
            }
            if let accountNumber = analysis.accountNumber {
                DetailInfoRow(label: "Account", value: accountNumber)
            }
            if let zipCode = analysis.zipCode {
                DetailInfoRow(label: "ZIP Code", value: zipCode)
            }
        }
    }
}

// MARK: - Detail Grouped Section

struct DetailGroupedSection: View {
    let category: String
    let items: [BillAnalysis.LineItem]

    private var categoryTotal: Double {
        items.reduce(0) { $0 + $1.amount }
    }

    private var categoryColor: Color {
        switch category.lowercased() {
        case "supply", "power supply", "energy", "energy charge": return Color(hex: "#F97316")  // Orange
        case "delivery", "delivery charges", "distribution": return Color(hex: "#14B8A6")  // Teal
        case "taxes", "fees", "taxes & fees": return Color(hex: "#EAB308")  // Yellow
        case "service", "service charge", "customer charge": return Color(hex: "#8B5CF6")  // Violet
        case "base", "base charge": return Color(hex: "#6D28D9")  // Dark Purple
        case "on-peak", "on peak": return Color(hex: "#DC2626")  // Red
        case "off-peak", "off peak": return Color(hex: "#2563EB")  // Blue
        case "mid-peak", "mid peak": return Color(hex: "#D97706")  // Amber
        case "environmental", "renewable": return Color(hex: "#22C55E")  // Green
        case "regulatory", "regulatory fees", "franchise": return Color(hex: "#FBBF24")  // Amber
        default: return Color(hex: "#64748B")  // Slate
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(categoryColor)
                    .tracking(0.3)

                Spacer()

                Text("$\(String(format: "%.2f", categoryTotal))")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)
            }

            Rectangle()
                .fill(categoryColor.opacity(0.25))
                .frame(height: 1)

            ForEach(items) { item in
                HStack {
                    Text(item.description)
                        .font(.system(size: 13))
                        .foregroundColor(.billixDarkGreen)

                    Spacer()

                    Text("$\(String(format: "%.2f", item.amount))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                }
                .padding(.leading, 8)

                if let quantity = item.quantity, let rate = item.rate, let unit = item.unit {
                    Text("\(String(format: "%.0f", quantity)) \(unit) × $\(String(format: "%.4f", rate))")
                        .font(.system(size: 11))
                        .foregroundColor(.billixLightGreenText)
                        .padding(.leading, 8)
                }
            }
        }
        .padding(.bottom, 6)
    }
}

// MARK: - Detail Info Row

struct DetailInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.billixMediumGreen)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.billixDarkGreen)
        }
    }
}

// MARK: - Embedded Version (for UploadDetailView)

struct AnalysisResultsTabbedEmbeddedView: View {
    let analysis: BillAnalysis

    @State private var selectedTab: AnalysisResultsTabbedView.AnalysisTabType = .summary
    @State private var appeared = false
    @Namespace private var tabAnimation

    var body: some View {
        VStack(spacing: 0) {
            // Hero Section
            heroSection

            // Tab Bar
            tabBar
                .padding(.top, 16)
                .padding(.bottom, 12)

            // Swipeable Tab Content
            TabView(selection: $selectedTab) {
                AnalysisSummaryTab(analysis: analysis)
                    .tag(AnalysisResultsTabbedView.AnalysisTabType.summary)

                AnalysisDetailsTab(analysis: analysis)
                    .tag(AnalysisResultsTabbedView.AnalysisTabType.details)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
            .frame(minHeight: 500, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.billixChartBlue.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: categoryIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.billixChartBlue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(analysis.provider)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)

                    if let dueDate = analysis.dueDate {
                        Text("Due \(formatDateShort(dueDate))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                    }
                }

                Spacer()

                Text("$\(String(format: "%.2f", analysis.amount))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(AnalysisResultsTabbedView.AnalysisTabType.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private func tabButton(for tab: AnalysisResultsTabbedView.AnalysisTabType) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tab
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .semibold))

                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(selectedTab == tab ? .white : .billixMediumGreen)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.billixChartBlue)
                            .matchedGeometryEffect(id: "embeddedActiveTab", in: tabAnimation)
                            .shadow(color: .billixChartBlue.opacity(0.3), radius: 4, y: 2)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var categoryIcon: String {
        switch analysis.category.lowercased() {
        case "electric", "electricity": return "bolt.fill"
        case "gas": return "flame.fill"
        case "water": return "drop.fill"
        case "internet": return "wifi"
        case "phone", "mobile": return "phone.fill"
        case "cable", "tv": return "tv.fill"
        default: return "building.2.fill"
        }
    }

    private func formatDateShort(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "yyyy-MM-dd"
        if let date = altFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Preview

#Preview {
    AnalysisResultsTabbedView(
        analysis: BillAnalysis(
            provider: "DTE Energy",
            amount: 142.50,
            billDate: "2024-11-15",
            dueDate: "2024-12-15",
            accountNumber: "****4521",
            category: "Electric",
            zipCode: "48127",
            keyFacts: [
                BillAnalysis.KeyFact(label: "Service Type", value: "Residential", icon: "house.fill"),
                BillAnalysis.KeyFact(label: "Billing Period", value: "Oct 15 - Nov 14", icon: "calendar")
            ],
            lineItems: [
                BillAnalysis.LineItem(description: "Power Supply", amount: 78.00, category: "Supply", quantity: 850, rate: 0.0918, unit: "kWh"),
                BillAnalysis.LineItem(description: "Delivery Charges", amount: 42.00, category: "Delivery"),
                BillAnalysis.LineItem(description: "State Tax", amount: 12.50, category: "Taxes"),
                BillAnalysis.LineItem(description: "Regulatory Fees", amount: 10.00, category: "Taxes")
            ],
            costBreakdown: nil,
            insights: [
                BillAnalysis.Insight(type: .savings, title: "Potential Savings", description: "You could save $14/month by switching to a time-of-use plan."),
                BillAnalysis.Insight(type: .info, title: "Usage Trend", description: "Your usage is 12% higher than last month.")
            ],
            marketplaceComparison: BillAnalysis.MarketplaceComparison(
                areaAverage: 128.00,
                percentDiff: 11.3,
                zipPrefix: "481",
                position: .above,
                state: "MI",
                sampleSize: 42
            ),
            plainEnglishSummary: nil,
            redFlags: nil,
            controllableCosts: nil,
            savingsOpportunities: nil,
            jargonGlossary: nil,
            assistancePrograms: nil,
            rawExtractedText: nil
        ),
        onComplete: {}
    )
}
