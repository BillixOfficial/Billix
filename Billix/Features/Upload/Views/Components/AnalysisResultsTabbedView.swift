//
//  AnalysisResultsTabbedView.swift
//  Billix
//
//  Created by Claude Code on 11/28/25.
//  Redesigned analysis view with hero section + swipeable tabs
//

import SwiftUI
import Charts

// MARK: - Main Tabbed View

struct AnalysisResultsTabbedView: View {
    let analysis: BillAnalysis
    let onComplete: () -> Void

    @State private var selectedTab: AnalysisTabType = .summary
    @State private var appeared = false
    @Namespace private var tabAnimation

    enum AnalysisTabType: String, CaseIterable {
        case summary = "Summary"
        case breakdown = "Breakdown"
        case details = "Details"

        var icon: String {
            switch self {
            case .summary: return "square.grid.2x2.fill"
            case .breakdown: return "chart.pie.fill"
            case .details: return "list.bullet.rectangle.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Hero Section (always visible)
            heroSection
                .padding(.horizontal, 20)
                .padding(.top, 12)

            // Tab Bar
            tabBar
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            // Swipeable Tab Content
            TabView(selection: $selectedTab) {
                SummaryTabContent(analysis: analysis)
                    .tag(AnalysisTabType.summary)

                BreakdownTabContent(analysis: analysis)
                    .tag(AnalysisTabType.breakdown)

                DetailsTabContent(analysis: analysis)
                    .tag(AnalysisTabType.details)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
            .frame(maxHeight: .infinity)

            // Done Button
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

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 12) {
            // Provider + Amount Row
            HStack(spacing: 14) {
                // Provider Icon
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

                // Amount
                Text("$\(String(format: "%.2f", analysis.amount))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)
            }

            // Comparison Bar (if available)
            if let comparison = analysis.marketplaceComparison {
                CompactComparisonBar(
                    position: comparison.position,
                    percentDiff: comparison.percentDiff,
                    areaAverage: comparison.areaAverage
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(AnalysisTabType.allCases, id: \.self) { tab in
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

    private func tabButton(for tab: AnalysisTabType) -> some View {
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
            }
            .foregroundColor(selectedTab == tab ? .white : .billixMediumGreen)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.billixChartBlue)
                            .matchedGeometryEffect(id: "activeTab", in: tabAnimation)
                            .shadow(color: .billixChartBlue.opacity(0.3), radius: 4, y: 2)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
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
            return "\(String(format: "%.0f", diff))% below average"
        case .average:
            return "At area average"
        case .above:
            return "\(String(format: "%.0f", diff))% above average"
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
                SummaryTabContent(analysis: analysis)
                    .tag(AnalysisResultsTabbedView.AnalysisTabType.summary)

                BreakdownTabContent(analysis: analysis)
                    .tag(AnalysisResultsTabbedView.AnalysisTabType.breakdown)

                DetailsTabContent(analysis: analysis)
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

            if let comparison = analysis.marketplaceComparison {
                CompactComparisonBar(
                    position: comparison.position,
                    percentDiff: comparison.percentDiff,
                    areaAverage: comparison.areaAverage
                )
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
                position: .above
            )
        ),
        onComplete: {}
    )
}
