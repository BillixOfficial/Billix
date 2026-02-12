//
//  AnalysisBreakdownTab.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI
import Charts

/// Breakdown tab - Visual cost breakdown using Swift Charts
struct AnalysisBreakdownTab: View {
    let analysis: BillAnalysis

    @State private var selectedCategory: String?
    @State private var appeared = false

    // Category colors
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
        "Other": .billixLightGreenText
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // NEW: What You Can Control
                if let controlAnalysis = analysis.controllableCosts {
                    ControlAnalysisSection(controlAnalysis: controlAnalysis)
                }

                // Donut chart
                donutChartSection

                // Insights section
                if let insights = analysis.insights, !insights.isEmpty {
                    insightsSection(insights)
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
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
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
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

    // MARK: - Insights Section

    private func insightsSection(_ insights: [BillAnalysis.Insight]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            ForEach(insights, id: \.title) { insight in
                InsightCard(insight: insight)
            }
        }
    }

    // MARK: - Helpers

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
        // Default color based on hash
        let colors: [Color] = [.billixChartBlue, .billixMoneyGreen, .billixSavingsYellow, .billixPurpleAccent, .billixChatBlue]
        return colors[abs(category.hashValue) % colors.count]
    }
}

// MARK: - Legend Row

struct LegendRow: View {
    let category: String
    let amount: Double
    let percentage: Double
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Color indicator
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)

                // Category name
                Text(category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                // Amount
                Text("$\(String(format: "%.2f", amount))")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)

                // Percentage badge
                Text("\(Int(percentage))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.15))
                    )
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: BillAnalysis.Insight

    private var iconInfo: (icon: String, color: Color) {
        switch insight.type {
        case .savings:
            return ("star.fill", .billixSavingsYellow)
        case .warning:
            return ("exclamationmark.triangle.fill", .billixSavingsOrange)
        case .info:
            return ("info.circle.fill", .billixChartBlue)
        case .success:
            return ("checkmark.circle.fill", .billixMoneyGreen)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconInfo.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: iconInfo.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconInfo.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Text(insight.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.billixMediumGreen)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(iconInfo.color.opacity(0.08))
        )
    }
}

// MARK: - Preview

struct AnalysisBreakdownTab_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisBreakdownTab(
        analysis: BillAnalysis(
        provider: "DTE Energy",
        amount: 142.50,
        billDate: "2024-11-15",
        dueDate: "2024-12-15",
        accountNumber: nil,
        category: "Electric",
        zipCode: nil,
        keyFacts: nil,
        lineItems: [
        BillAnalysis.LineItem(description: "Power Supply", amount: 78.00),
        BillAnalysis.LineItem(description: "Delivery", amount: 42.00),
        BillAnalysis.LineItem(description: "Taxes & Fees", amount: 22.50)
        ],
        costBreakdown: [
        BillAnalysis.CostBreakdown(category: "Power Supply", amount: 78.00, percentage: 55),
        BillAnalysis.CostBreakdown(category: "Delivery", amount: 42.00, percentage: 29),
        BillAnalysis.CostBreakdown(category: "Taxes & Fees", amount: 22.50, percentage: 16)
        ],
        insights: [
        BillAnalysis.Insight(type: .savings, title: "Potential Savings", description: "You could save $14/month by switching to a time-of-use plan."),
        BillAnalysis.Insight(type: .warning, title: "High Usage", description: "Your usage is 12% higher than last month.")
        ],
        marketplaceComparison: nil,
        plainEnglishSummary: nil,
        redFlags: nil,
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
