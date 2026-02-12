//
//  AnalysisSummaryTab.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI
import Charts

/// Summary tab - Hero dashboard showing all key metrics and new enhanced analysis
/// Includes Plain English Summary, Red Flags, gauge, metrics, insights, breakdown, and control analysis
struct AnalysisSummaryTab: View {
    let analysis: BillAnalysis

    @State private var selectedCategory: String?
    @State private var chartAppeared = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // Category colors for donut chart
    private let categoryColors: [String: Color] = [
        "Power Supply": .billixChartBlue,
        "Supply": .billixChartBlue,
        "Delivery": .billixMoneyGreen,
        "Delivery Charges": .billixMoneyGreen,
        "Taxes": .billixSavingsYellow,
        "Taxes & Fees": .billixSavingsYellow,
        "Fees": .billixSavingsOrange,
        "Service Charges": .billixPurpleAccent,
        "Usage": .billixChatBlue,
        "Base Charge": .billixFaqGreen,
        "Variable Costs": .billixChartBlue,
        "Fixed Costs": .billixVotePink,
        "Other": .billixLightGreenText
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // 1. Comparison Bar (first)
                if let comparison = analysis.marketplaceComparison {
                    ComparisonBarCard(
                        position: comparison.position,
                        percentDiff: comparison.percentDiff,
                        areaAverage: comparison.areaAverage,
                        yourAmount: analysis.amount,
                        state: comparison.state,
                        sampleSize: comparison.sampleSize
                    )
                }

                // 2. Quick Summary (second)
                if let summary = analysis.plainEnglishSummary {
                    PlainEnglishSummaryCard(summary: summary)
                }

                // 3. Cost Breakdown Pie Chart (third)
                donutChartSection

                // 4. Red Flags Alert
                if let redFlags = analysis.redFlags, !redFlags.isEmpty {
                    RedFlagsAlertCard(redFlags: redFlags)
                }

                // 5. What You Can Control
                if let controlAnalysis = analysis.controllableCosts {
                    ControlAnalysisSection(controlAnalysis: controlAnalysis)
                }

                // 6. Metrics grid
                metricsGrid

                // 7. AI Insights section (showing all insights)
                if let insights = analysis.insights, !insights.isEmpty {
                    insightsSection(insights)
                }

                // Extra padding for done button
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            // Savings card (if applicable)
            if let savings = analysis.potentialSavings, savings > 0 {
                SavingsMetricCard(savings: savings)
            } else {
                // Show provider card instead
                MetricCardView(
                    title: "Provider",
                    value: analysis.provider,
                    subtitle: analysis.category,
                    icon: categoryIcon,
                    iconColor: .billixChartBlue
                )
            }

            // Health score card
            HealthScoreCard(
                score: calculateHealthScore(),
                status: healthStatus
            )

            // Provider card (if savings shown) or Due Date
            if analysis.potentialSavings != nil {
                MetricCardView(
                    title: "Provider",
                    value: analysis.provider,
                    subtitle: analysis.category,
                    icon: categoryIcon,
                    iconColor: .billixChartBlue
                )
            } else {
                dueDateCard
            }

            // Due date card (if savings shown) or Category
            if analysis.potentialSavings != nil {
                dueDateCard
            } else {
                categoryCard
            }
        }
    }

    // MARK: - Insights Section

    private func insightsSection(_ insights: [BillAnalysis.Insight]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixSavingsYellow)

                Text("AI Insights")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }

            VStack(spacing: 12) {
                ForEach(insights, id: \.title) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }

    // MARK: - Individual Cards

    private var dueDateCard: some View {
        Group {
            if let dueDate = analysis.dueDate {
                MetricCardView(
                    title: "Due Date",
                    value: formatDueDate(dueDate),
                    subtitle: daysUntilDue(dueDate),
                    icon: "calendar",
                    iconColor: dueDateColor(dueDate)
                )
            } else {
                MetricCardView(
                    title: "Bill Date",
                    value: formatBillDate(analysis.billDate),
                    subtitle: nil,
                    icon: "calendar",
                    iconColor: .billixMediumGreen
                )
            }
        }
    }

    private var categoryCard: some View {
        MetricCardView(
            title: "Category",
            value: analysis.category,
            subtitle: "\(analysis.lineItems.count) line items",
            icon: categoryIcon,
            iconColor: .billixMoneyGreen
        )
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
        default: return "doc.text.fill"
        }
    }

    /// Calculate a bill health score based on available data
    private func calculateHealthScore() -> Int {
        var score = 70 // Base score

        // Adjust based on market position
        if let comparison = analysis.marketplaceComparison {
            switch comparison.position {
            case .below:
                score += 20 + Int(min(abs(comparison.percentDiff), 20))
            case .average:
                score += 10
            case .above:
                score -= Int(min(comparison.percentDiff, 30))
            }
        }

        // Bonus for having insights
        if let insights = analysis.insights, !insights.isEmpty {
            let savingsInsights = insights.filter { $0.type == .savings }.count
            score += savingsInsights * 5
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

    private func formatDueDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
        // Try other formats
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "yyyy-MM-dd"
        if let date = altFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    private func formatBillDate(_ dateString: String) -> String {
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
        let formatter = ISO8601DateFormatter()
        var dueDate: Date?

        if let date = formatter.date(from: dateString) {
            dueDate = date
        } else {
            let altFormatter = DateFormatter()
            altFormatter.dateFormat = "yyyy-MM-dd"
            dueDate = altFormatter.date(from: dateString)
        }

        guard let due = dueDate else { return "" }

        let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0

        if days < 0 {
            return "Overdue"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else {
            return "\(days) days left"
        }
    }

    private func dueDateColor(_ dateString: String) -> Color {
        let formatter = ISO8601DateFormatter()
        var dueDate: Date?

        if let date = formatter.date(from: dateString) {
            dueDate = date
        } else {
            let altFormatter = DateFormatter()
            altFormatter.dateFormat = "yyyy-MM-dd"
            dueDate = altFormatter.date(from: dateString)
        }

        guard let due = dueDate else { return .billixMediumGreen }

        let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0

        if days < 0 {
            return .billixVotePink
        } else if days <= 7 {
            return .billixSavingsOrange
        } else {
            return .billixMoneyGreen
        }
    }

    // MARK: - Donut Chart Section

    private var donutChartSection: some View {
        VStack(spacing: 16) {
            // Chart with center label
            ZStack {
                if let breakdown = analysis.costBreakdown, !breakdown.isEmpty {
                    Chart(breakdown, id: \.category) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(colorFor(item.category))
                        .opacity(selectedCategory == nil || selectedCategory == item.category ? 1 : 0.3)
                        .cornerRadius(4)
                    }
                    .chartBackground { _ in
                        centerLabel
                    }
                    .frame(height: 220)
                    .chartLegend(.hidden)
                } else {
                    // Fallback: create breakdown from line items
                    Chart(analysis.lineItems.prefix(6)) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(colorFor(item.category ?? item.description))
                        .opacity(selectedCategory == nil || selectedCategory == item.description ? 1 : 0.3)
                        .cornerRadius(4)
                    }
                    .chartBackground { _ in
                        centerLabel
                    }
                    .frame(height: 220)
                    .chartLegend(.hidden)
                }
            }

            // Legend
            legendSection
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
        .scaleEffect(chartAppeared ? 1 : 0.95)
        .opacity(chartAppeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                chartAppeared = true
            }
        }
    }

    private var centerLabel: some View {
        VStack(spacing: 4) {
            Text("Total")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.billixMediumGreen)

            Text("$\(String(format: "%.2f", analysis.amount))")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.billixDarkGreen)
        }
    }

    private var legendSection: some View {
        VStack(spacing: 10) {
            if let breakdown = analysis.costBreakdown, !breakdown.isEmpty {
                ForEach(breakdown.sorted(by: { $0.amount > $1.amount }), id: \.category) { item in
                    LegendRow(
                        category: item.category,
                        amount: item.amount,
                        percentage: item.percentage,
                        color: colorFor(item.category),
                        isSelected: selectedCategory == item.category,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedCategory == item.category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = item.category
                                }
                            }
                        }
                    )
                }
            } else {
                ForEach(analysis.lineItems.prefix(6).sorted(by: { $0.amount > $1.amount })) { item in
                    let percentage = (item.amount / analysis.amount) * 100
                    LegendRow(
                        category: item.description,
                        amount: item.amount,
                        percentage: percentage,
                        color: colorFor(item.category ?? item.description),
                        isSelected: selectedCategory == item.description,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedCategory == item.description {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = item.description
                                }
                            }
                        }
                    )
                }
            }
        }
    }

    private func colorFor(_ category: String) -> Color {
        // Check direct match first
        if let color = categoryColors[category] {
            return color
        }
        // Check partial match
        for (key, color) in categoryColors {
            if category.lowercased().contains(key.lowercased()) {
                return color
            }
        }
        // Expanded color palette for diverse categories
        let colors: [Color] = [
            .billixChartBlue,
            .billixMoneyGreen,
            .billixSavingsYellow,
            .billixSavingsOrange,
            .billixPurpleAccent,
            .billixChatBlue,
            .billixVotePink,
            .billixFaqGreen,
            Color(red: 0.4, green: 0.6, blue: 0.9),  // Light blue
            Color(red: 0.9, green: 0.5, blue: 0.3),  // Coral
            Color(red: 0.6, green: 0.4, blue: 0.8),  // Lavender
            Color(red: 0.3, green: 0.7, blue: 0.6)   // Teal
        ]
        return colors[abs(category.hashValue) % colors.count]
    }
}

// MARK: - Preview

struct AnalysisSummaryTab_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisSummaryTab(
        analysis: BillAnalysis(
        provider: "DTE Energy",
        amount: 142.50,
        billDate: "2024-11-15",
        dueDate: "2024-12-15",
        accountNumber: "****4521",
        category: "Electric",
        zipCode: "48127",
        keyFacts: nil,
        lineItems: [
        BillAnalysis.LineItem(description: "Power Supply", amount: 78.00),
        BillAnalysis.LineItem(description: "Delivery", amount: 42.00),
        BillAnalysis.LineItem(description: "Taxes", amount: 22.50)
        ],
        costBreakdown: nil,
        insights: [
        BillAnalysis.Insight(type: .savings, title: "Save Money", description: "Switch plans")
        ],
        marketplaceComparison: BillAnalysis.MarketplaceComparison(
        areaAverage: 128.00,
        percentDiff: 11.3,
        zipPrefix: "481",
        position: .above,
        state: "MI",
        sampleSize: 42
        ),
        plainEnglishSummary: "Your November electric bill is $142.50, due December 15th. You used 147 kWh of electricity, which is about average for a home your size.",
        redFlags: [
        BillAnalysis.RedFlag(type: "high", description: "Service fee appears twice on your bill", recommendation: "Contact your provider to remove the duplicate charge", potentialSavings: 15.0)
        ],
        controllableCosts: nil,
        savingsOpportunities: nil,
        jargonGlossary: nil,
        assistancePrograms: nil,
        rawExtractedText: nil
        )
        )
        .background(Color.billixLightGreen)
    }
}
