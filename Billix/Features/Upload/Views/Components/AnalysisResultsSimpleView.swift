//
//  AnalysisResultsSimpleView.swift
//  Billix
//
//  Created by Claude Code on 11/28/25.
//  Redesigned to match web version card-based layout
//

import SwiftUI

/// Full Analysis results view matching the web version's card-based layout
/// All sections visible, scrollable - no progressive disclosure
struct AnalysisResultsSimpleView: View {
    let analysis: BillAnalysis
    let onComplete: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 1. Header Section
                    headerCard

                    // 2. Bill Summary Card
                    billSummaryCard

                    // 3. Marketplace Comparison Card
                    if let comparison = analysis.marketplaceComparison {
                        marketplaceComparisonCard(comparison)
                    }

                    // 4. Key Information Card
                    if analysis.keyFacts != nil || analysis.lineItems.contains(where: { $0.quantity != nil }) {
                        keyInformationCard
                    }

                    // 5. Cost Breakdown Card (Progress Bars)
                    if !analysis.lineItems.isEmpty {
                        costBreakdownCard
                    }

                    // 6. Complete Breakdown Card (Grouped Line Items)
                    if !analysis.lineItems.isEmpty {
                        completeBreakdownCard
                    }

                    // 7. AI Insights Card
                    if let insights = analysis.insights, !insights.isEmpty {
                        aiInsightsCard(insights)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            // Done button
            doneButton
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(Color.billixLightGreen)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - 1. Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            // Provider icon
            ZStack {
                Circle()
                    .fill(Color.billixChartBlue.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: categoryIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.billixChartBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(analysis.provider)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                if let accountNumber = analysis.accountNumber {
                    Text("Account: \(accountNumber)")
                        .font(.system(size: 13))
                        .foregroundColor(.billixMediumGreen)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", analysis.amount))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)

                if let dueDate = analysis.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text("Due: \(formatDateShort(dueDate))")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.billixChartBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.billixChartBlue.opacity(0.1))
                    )
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - 2. Bill Summary Card

    private var billSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: "Bill Summary", icon: "doc.text.fill")

            // Grid of info
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                summaryGridItem(label: "BILL DATE", value: formatDateShort(analysis.billDate))
                summaryGridItem(label: "DUE DATE", value: analysis.dueDate.map { formatDateShort($0) } ?? "N/A")
                summaryGridItem(label: "CATEGORY", value: analysis.category)
                summaryGridItem(label: "ZIP CODE", value: analysis.zipCode ?? "N/A")
            }

            Divider()
                .background(Color.billixBorderGreen)

            // Total amount
            HStack {
                Text("TOTAL AMOUNT")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
                    .tracking(0.5)

                Spacer()

                Text("$\(String(format: "%.2f", analysis.amount))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)
            }
        }
        .padding(20)
        .background(cardBackground)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05), value: appeared)
    }

    private func summaryGridItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.billixMediumGreen)
                .tracking(0.5)

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.billixDarkGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 3. Marketplace Comparison Card

    private func marketplaceComparisonCard(_ comparison: BillAnalysis.MarketplaceComparison) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: "Marketplace Comparison", icon: "storefront.fill")

            // Gradient comparison bar
            MarketplaceComparisonBar(
                position: comparison.position,
                percentDiff: comparison.percentDiff
            )

            // Your Bill vs Area Average
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Your Bill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Text("$\(String(format: "%.2f", analysis.amount))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)
                }
                .frame(maxWidth: .infinity)

                Text("vs")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixLightGreenText)
                    .padding(.horizontal, 12)

                VStack(spacing: 4) {
                    Text("Billix Average")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Text("$\(String(format: "%.2f", comparison.areaAverage))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)

                    if let state = comparison.state, let sampleSize = comparison.sampleSize, sampleSize >= 5 {
                        Text("Based on \(sampleSize) bills in \(state)")
                            .font(.system(size: 11))
                            .foregroundColor(.billixLightGreenText)
                    } else {
                        Text("(ZIP \(comparison.zipPrefix)**)")
                            .font(.system(size: 11))
                            .foregroundColor(.billixLightGreenText)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)

            // Status message
            comparisonStatusBanner(comparison)
        }
        .padding(20)
        .background(cardBackground)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appeared)
    }

    private func comparisonStatusBanner(_ comparison: BillAnalysis.MarketplaceComparison) -> some View {
        let diff = abs(comparison.percentDiff)
        let message: String
        let icon: String
        let color: Color

        switch comparison.position {
        case .below:
            message = "You're paying \(String(format: "%.0f", diff))% less than the Billix average."
            icon = "checkmark.circle.fill"
            color = .billixMoneyGreen
        case .average:
            message = "You're paying about the same as the Billix average."
            icon = "equal.circle.fill"
            color = .billixChartBlue
        case .above:
            message = "You're paying \(String(format: "%.0f", diff))% more than the Billix average."
            icon = "exclamationmark.triangle.fill"
            color = .statusOverpaying
        }

        return HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.billixDarkGreen)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - 4. Key Information Card

    private var keyInformationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: "Key Information", icon: "info.circle.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                // From key facts
                if let keyFacts = analysis.keyFacts {
                    ForEach(keyFacts, id: \.label) { fact in
                        summaryGridItem(label: fact.label.uppercased(), value: fact.value)
                    }
                }

                // Usage info from line items
                if let usageItem = analysis.lineItems.first(where: { $0.quantity != nil && $0.unit != nil }) {
                    if let quantity = usageItem.quantity, let unit = usageItem.unit {
                        summaryGridItem(label: "USAGE", value: "\(String(format: "%.0f", quantity)) \(unit)")
                    }
                    if let rate = usageItem.rate, let unit = usageItem.unit {
                        summaryGridItem(label: "RATE", value: "$\(String(format: "%.3f", rate))/\(unit)")
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: appeared)
    }

    // MARK: - 5. Cost Breakdown Card

    private var costBreakdownCard: some View {
        let totalAmount = analysis.lineItems.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: "Cost Breakdown", icon: "chart.bar.fill")

            ForEach(analysis.lineItems) { item in
                CostBreakdownRow(
                    label: item.description,
                    amount: item.amount,
                    percentage: totalAmount > 0 ? (item.amount / totalAmount) * 100 : 0,
                    color: categoryColor(for: item.category)
                )
            }
        }
        .padding(20)
        .background(cardBackground)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appeared)
    }

    // MARK: - 6. Complete Breakdown Card

    private var completeBreakdownCard: some View {
        let groupedItems = Dictionary(grouping: analysis.lineItems) { $0.category ?? "Other" }
        let sortedCategories = groupedItems.keys.sorted { cat1, cat2 in
            let total1 = groupedItems[cat1]?.reduce(0) { $0 + $1.amount } ?? 0
            let total2 = groupedItems[cat2]?.reduce(0) { $0 + $1.amount } ?? 0
            return total1 > total2
        }

        return VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: "Complete Breakdown", icon: "list.bullet.rectangle.fill")

            ForEach(sortedCategories, id: \.self) { category in
                if let items = groupedItems[category] {
                    GroupedLineItemsSection(
                        category: category,
                        items: items,
                        color: categoryColor(for: category)
                    )
                }
            }

            Divider()
                .background(Color.billixBorderGreen)

            // Grand Total
            HStack {
                Text("Total")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Text("$\(String(format: "%.2f", analysis.amount))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.billixMoneyGreen)
            }
        }
        .padding(20)
        .background(cardBackground)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: appeared)
    }

    // MARK: - 7. AI Insights Card

    private func aiInsightsCard(_ insights: [BillAnalysis.Insight]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: "AI Insights", icon: "sparkles")

            ForEach(insights, id: \.title) { insight in
                AnalysisInsightCard(insight: insight)
            }
        }
        .padding(20)
        .background(cardBackground)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: appeared)
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

    // MARK: - Shared Components

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func cardHeader(title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixChartBlue)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
        }
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

    private func categoryColor(for category: String?) -> Color {
        guard let category = category?.lowercased() else { return .billixChartBlue }
        switch category {
        case "supply", "power supply", "energy": return .billixMoneyGreen
        case "delivery", "distribution": return .billixChartBlue
        case "taxes", "fees", "taxes & fees": return .billixSavingsYellow
        default: return .billixMediumGreen
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

// MARK: - Marketplace Comparison Bar

struct MarketplaceComparisonBar: View {
    let position: BillAnalysis.MarketplaceComparison.Position
    let percentDiff: Double

    @State private var animatedPosition: CGFloat = 0.5

    private var userPosition: CGFloat {
        // Position on a 0-1 scale where 0.5 is average
        // Below average: < 0.5, Above average: > 0.5
        switch position {
        case .below:
            return max(0.1, 0.5 - (abs(percentDiff) / 100))
        case .average:
            return 0.5
        case .above:
            return min(0.9, 0.5 + (abs(percentDiff) / 100))
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Labels
            HStack {
                Text("Lower")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.billixMoneyGreen)

                Spacer()

                Text("Higher")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.statusOverpaying)
            }

            // Gradient bar with marker
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

                    // Average marker (center line)
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 2, height: 16)
                        .offset(x: geometry.size.width * 0.5 - 1)

                    // User position marker
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(markerBorderColor, lineWidth: 3)
                        )
                        .offset(x: geometry.size.width * animatedPosition - 10)
                }
            }
            .frame(height: 20)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                    animatedPosition = userPosition
                }
            }

            // Position label
            Text("Your position")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.billixLightGreenText)
        }
    }

    private var markerBorderColor: Color {
        switch position {
        case .below: return .billixMoneyGreen
        case .average: return .billixSavingsYellow
        case .above: return .statusOverpaying
        }
    }
}

// MARK: - Cost Breakdown Row

struct CostBreakdownRow: View {
    let label: String
    let amount: Double
    let percentage: Double
    let color: Color

    @State private var animatedProgress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(1)

                Spacer()

                Text("$\(String(format: "%.0f", amount)) (\(String(format: "%.0f", percentage))%)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress)
                }
            }
            .frame(height: 8)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    animatedProgress = CGFloat(percentage / 100)
                }
            }
        }
    }
}

// MARK: - Grouped Line Items Section

struct GroupedLineItemsSection: View {
    let category: String
    let items: [BillAnalysis.LineItem]
    let color: Color

    private var categoryTotal: Double {
        items.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Category header with total
            HStack {
                Text(category.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
                    .tracking(0.5)

                Spacer()

                Text("$\(String(format: "%.2f", categoryTotal))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)
            }

            Rectangle()
                .fill(color.opacity(0.3))
                .frame(height: 1)

            // Line items
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.description)
                            .font(.system(size: 14))
                            .foregroundColor(.billixDarkGreen)

                        Spacer()

                        Text("$\(String(format: "%.2f", item.amount))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.billixDarkGreen)
                    }

                    // Show quantity x rate if available
                    if let quantity = item.quantity, let rate = item.rate, let unit = item.unit {
                        Text("\(String(format: "%.0f", quantity)) \(unit) x $\(String(format: "%.4f", rate))")
                            .font(.system(size: 12))
                            .foregroundColor(.billixLightGreenText)
                    }
                }
                .padding(.leading, 12)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Analysis Insight Card

struct AnalysisInsightCard: View {
    let insight: BillAnalysis.Insight

    private var backgroundColor: Color {
        switch insight.type {
        case .savings: return .billixMoneyGreen
        case .warning: return .statusOverpaying
        case .info: return .billixChartBlue
        case .success: return .billixMoneyGreen
        }
    }

    private var iconName: String {
        switch insight.type {
        case .savings: return "dollarsign.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(backgroundColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Text(insight.description)
                    .font(.system(size: 13))
                    .foregroundColor(.billixMediumGreen)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor.opacity(0.1))
        )
    }
}

// MARK: - Embedded Version (for UploadDetailView)

/// Embedded version without Done button for use inside other views
struct AnalysisResultsSimpleEmbeddedView: View {
    let analysis: BillAnalysis

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            // 1. Header Section
            headerCard

            // 2. Bill Summary Card
            billSummaryCard

            // 3. Marketplace Comparison Card
            if let comparison = analysis.marketplaceComparison {
                marketplaceComparisonCard(comparison)
            }

            // 4. Key Information Card
            if analysis.keyFacts != nil || analysis.lineItems.contains(where: { $0.quantity != nil }) {
                keyInformationCard
            }

            // 5. Cost Breakdown Card
            if !analysis.lineItems.isEmpty {
                costBreakdownCard
            }

            // 6. Complete Breakdown Card
            if !analysis.lineItems.isEmpty {
                completeBreakdownCard
            }

            // 7. AI Insights Card
            if let insights = analysis.insights, !insights.isEmpty {
                aiInsightsCard(insights)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - 1. Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.billixChartBlue.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: categoryIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.billixChartBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(analysis.provider)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                if let accountNumber = analysis.accountNumber {
                    Text("Account: \(accountNumber)")
                        .font(.system(size: 13))
                        .foregroundColor(.billixMediumGreen)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", analysis.amount))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)

                if let dueDate = analysis.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text("Due: \(formatDateShort(dueDate))")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.billixChartBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.billixChartBlue.opacity(0.1))
                    )
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - 2. Bill Summary Card

    private var billSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: "Bill Summary", icon: "doc.text.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                summaryGridItem(label: "BILL DATE", value: formatDateShort(analysis.billDate))
                summaryGridItem(label: "DUE DATE", value: analysis.dueDate.map { formatDateShort($0) } ?? "N/A")
                summaryGridItem(label: "CATEGORY", value: analysis.category)
                summaryGridItem(label: "ZIP CODE", value: analysis.zipCode ?? "N/A")
            }

            Divider()
                .background(Color.billixBorderGreen)

            HStack {
                Text("TOTAL AMOUNT")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
                    .tracking(0.5)

                Spacer()

                Text("$\(String(format: "%.2f", analysis.amount))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private func summaryGridItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.billixMediumGreen)
                .tracking(0.5)

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.billixDarkGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 3. Marketplace Comparison Card

    private func marketplaceComparisonCard(_ comparison: BillAnalysis.MarketplaceComparison) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: "Marketplace Comparison", icon: "storefront.fill")

            MarketplaceComparisonBar(
                position: comparison.position,
                percentDiff: comparison.percentDiff
            )

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Your Bill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Text("$\(String(format: "%.2f", analysis.amount))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)
                }
                .frame(maxWidth: .infinity)

                Text("vs")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixLightGreenText)
                    .padding(.horizontal, 12)

                VStack(spacing: 4) {
                    Text("Billix Average")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Text("$\(String(format: "%.2f", comparison.areaAverage))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)

                    if let state = comparison.state, let sampleSize = comparison.sampleSize, sampleSize >= 5 {
                        Text("Based on \(sampleSize) bills in \(state)")
                            .font(.system(size: 11))
                            .foregroundColor(.billixLightGreenText)
                    } else {
                        Text("(ZIP \(comparison.zipPrefix)**)")
                            .font(.system(size: 11))
                            .foregroundColor(.billixLightGreenText)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)

            comparisonStatusBanner(comparison)
        }
        .padding(20)
        .background(cardBackground)
    }

    private func comparisonStatusBanner(_ comparison: BillAnalysis.MarketplaceComparison) -> some View {
        let diff = abs(comparison.percentDiff)
        let message: String
        let icon: String
        let color: Color

        switch comparison.position {
        case .below:
            message = "You're paying \(String(format: "%.0f", diff))% less than the Billix average."
            icon = "checkmark.circle.fill"
            color = .billixMoneyGreen
        case .average:
            message = "You're paying about the same as the Billix average."
            icon = "equal.circle.fill"
            color = .billixChartBlue
        case .above:
            message = "You're paying \(String(format: "%.0f", diff))% more than the Billix average."
            icon = "exclamationmark.triangle.fill"
            color = .statusOverpaying
        }

        return HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.billixDarkGreen)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - 4. Key Information Card

    private var keyInformationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: "Key Information", icon: "info.circle.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                if let keyFacts = analysis.keyFacts {
                    ForEach(keyFacts, id: \.label) { fact in
                        summaryGridItem(label: fact.label.uppercased(), value: fact.value)
                    }
                }

                if let usageItem = analysis.lineItems.first(where: { $0.quantity != nil && $0.unit != nil }) {
                    if let quantity = usageItem.quantity, let unit = usageItem.unit {
                        summaryGridItem(label: "USAGE", value: "\(String(format: "%.0f", quantity)) \(unit)")
                    }
                    if let rate = usageItem.rate, let unit = usageItem.unit {
                        summaryGridItem(label: "RATE", value: "$\(String(format: "%.3f", rate))/\(unit)")
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - 5. Cost Breakdown Card

    private var costBreakdownCard: some View {
        let totalAmount = analysis.lineItems.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: "Cost Breakdown", icon: "chart.bar.fill")

            ForEach(analysis.lineItems) { item in
                CostBreakdownRow(
                    label: item.description,
                    amount: item.amount,
                    percentage: totalAmount > 0 ? (item.amount / totalAmount) * 100 : 0,
                    color: categoryColor(for: item.category)
                )
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - 6. Complete Breakdown Card

    private var completeBreakdownCard: some View {
        let groupedItems = Dictionary(grouping: analysis.lineItems) { $0.category ?? "Other" }
        let sortedCategories = groupedItems.keys.sorted { cat1, cat2 in
            let total1 = groupedItems[cat1]?.reduce(0) { $0 + $1.amount } ?? 0
            let total2 = groupedItems[cat2]?.reduce(0) { $0 + $1.amount } ?? 0
            return total1 > total2
        }

        return VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: "Complete Breakdown", icon: "list.bullet.rectangle.fill")

            ForEach(sortedCategories, id: \.self) { category in
                if let items = groupedItems[category] {
                    GroupedLineItemsSection(
                        category: category,
                        items: items,
                        color: categoryColor(for: category)
                    )
                }
            }

            Divider()
                .background(Color.billixBorderGreen)

            HStack {
                Text("Total")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Text("$\(String(format: "%.2f", analysis.amount))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.billixMoneyGreen)
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - 7. AI Insights Card

    private func aiInsightsCard(_ insights: [BillAnalysis.Insight]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(title: "AI Insights", icon: "sparkles")

            ForEach(insights, id: \.title) { insight in
                AnalysisInsightCard(insight: insight)
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - Shared Components

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func cardHeader(title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixChartBlue)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
        }
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

    private func categoryColor(for category: String?) -> Color {
        guard let category = category?.lowercased() else { return .billixChartBlue }
        switch category {
        case "supply", "power supply", "energy": return .billixMoneyGreen
        case "delivery", "distribution": return .billixChartBlue
        case "taxes", "fees", "taxes & fees": return .billixSavingsYellow
        default: return .billixMediumGreen
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
    AnalysisResultsSimpleView(
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
            jargonGlossary: nil
        ),
        onComplete: {}
    )
}
