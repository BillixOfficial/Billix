//
//  AnalysisComponents.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Shared UI components for displaying bill analysis results
//

import SwiftUI

// MARK: - Marketplace Comparison Card

/// Displays user's bill amount compared to area average
/// Shows position (below/average/above) with color coding
struct MarketplaceComparisonCard: View {
    let comparison: BillAnalysis.MarketplaceComparison
    let userAmount: Double

    private var positionColor: Color {
        switch comparison.position {
        case .below: return .statusUnderpaying
        case .average: return .statusNeutral
        case .above: return .statusOverpaying
        }
    }

    private var positionText: String {
        switch comparison.position {
        case .below: return "below average"
        case .average: return "close to average"
        case .above: return "above average"
        }
    }

    private var positionIcon: String {
        switch comparison.position {
        case .below: return "arrow.down.circle.fill"
        case .average: return "equal.circle.fill"
        case .above: return "arrow.up.circle.fill"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixChartBlue)

                Text("Area Comparison")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                // ZIP prefix badge
                Text("ZIP \(comparison.zipPrefix)xx")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.billixMediumGreen.opacity(0.1))
                    )
            }

            // Comparison bars
            HStack(spacing: 16) {
                // Your Bill
                VStack(spacing: 8) {
                    Text("Your Bill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Text(String(format: "$%.2f", userAmount))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(positionColor)

                    Image(systemName: positionIcon)
                        .font(.system(size: 20))
                        .foregroundColor(positionColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(positionColor.opacity(0.08))
                )

                // VS
                Text("vs")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen)

                // Area Average
                VStack(spacing: 8) {
                    Text("Area Avg")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Text(String(format: "$%.2f", comparison.areaAverage))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen.opacity(0.7))

                    Image(systemName: "person.3.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.billixMediumGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.billixMediumGreen.opacity(0.08))
                )
            }

            // Percentage difference badge
            HStack(spacing: 6) {
                Image(systemName: positionIcon)
                    .font(.system(size: 12))

                Text(String(format: "%.0f%% %@", abs(comparison.percentDiff), positionText))
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(positionColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(positionColor.opacity(0.12))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
}

// MARK: - Cost Breakdown Section

/// Displays a visual breakdown of costs by category
struct CostBreakdownSection: View {
    let breakdown: [BillAnalysis.CostBreakdown]

    private let categoryColors: [String: Color] = [
        "Power Supply": .billixChartBlue,
        "Delivery": .billixMoneyGreen,
        "Taxes": .orange,
        "Fees": .purple,
        "Other": .gray,
        "Service Charges": .teal,
        "Usage": .billixChartBlue,
        "Base Charge": .indigo
    ]

    private func colorFor(_ category: String) -> Color {
        // Try exact match first
        if let color = categoryColors[category] {
            return color
        }
        // Try partial match
        for (key, color) in categoryColors {
            if category.lowercased().contains(key.lowercased()) {
                return color
            }
        }
        return .gray
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.purple)

                Text("Cost Breakdown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()
            }

            // Breakdown bars
            VStack(spacing: 12) {
                ForEach(breakdown.sorted { $0.amount > $1.amount }, id: \.category) { item in
                    AnalysisComponentCostRow(
                        category: item.category,
                        amount: item.amount,
                        percentage: item.percentage,
                        color: colorFor(item.category)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
}

/// Single row in cost breakdown
private struct AnalysisComponentCostRow: View {
    let category: String
    let amount: Double
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Text(String(format: "$%.2f", amount))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)

                Text(String(format: "%.0f%%", percentage))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
                    .frame(width: 40, alignment: .trailing)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.billixMediumGreen.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Insights Section

/// Displays AI-generated insights with icons and colors
struct InsightsSection: View {
    let insights: [BillAnalysis.Insight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixSavingsYellow)

                Text("Insights")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()
            }

            // Insight cards
            ForEach(insights, id: \.title) { insight in
                AnalysisInsightRow(insight: insight)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
}

/// Single insight row for bill analysis
struct AnalysisInsightRow: View {
    let insight: BillAnalysis.Insight

    private var iconName: String {
        switch insight.type {
        case .savings: return "star.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch insight.type {
        case .savings: return .billixMoneyGreen
        case .warning: return .orange
        case .info: return .billixChartBlue
        case .success: return .billixMoneyGreen
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 18))
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Text(insight.description)
                    .font(.system(size: 13))
                    .foregroundColor(.billixMediumGreen)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(iconColor.opacity(0.08))
        )
    }
}

// MARK: - Line Items Section

/// Collapsible section showing bill line items
struct LineItemsSection: View {
    let lineItems: [BillAnalysis.LineItem]
    @State private var isExpanded: Bool = false

    private var displayedItems: [BillAnalysis.LineItem] {
        isExpanded ? lineItems : Array(lineItems.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with expand button
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixChartBlue)

                Text("Line Items")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                if lineItems.count > 3 {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "Show Less" : "Show All (\(lineItems.count))")
                                .font(.system(size: 12, weight: .medium))

                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.billixChartBlue)
                    }
                }
            }

            // Line items list
            VStack(spacing: 0) {
                ForEach(Array(displayedItems.enumerated()), id: \.element.id) { index, item in
                    LineItemRow(item: item)

                    if index < displayedItems.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
}

/// Single line item row
private struct LineItemRow: View {
    let item: BillAnalysis.LineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(2)

                Spacer()

                Text(String(format: "$%.2f", item.amount))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)
            }

            // Show explanation if available
            if let explanation = item.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.system(size: 12))
                    .foregroundColor(.billixMediumGreen)
                    .lineLimit(2)
            }

            // Show quantity/rate if available
            if let quantity = item.quantity, let rate = item.rate, let unit = item.unit {
                Text("\(String(format: "%.1f", quantity)) \(unit) × $\(String(format: "%.4f", rate))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.billixMediumGreen.opacity(0.8))
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Previews

#Preview("Marketplace Comparison") {
    MarketplaceComparisonCard(
        comparison: BillAnalysis.MarketplaceComparison(
            areaAverage: 125.00,
            percentDiff: 16.4,
            zipPrefix: "481",
            position: .above
        ),
        userAmount: 145.50
    )
    .padding()
    .background(Color.billixLightGreen)
}

#Preview("Cost Breakdown") {
    CostBreakdownSection(
        breakdown: [
            BillAnalysis.CostBreakdown(category: "Power Supply", amount: 94.50, percentage: 65),
            BillAnalysis.CostBreakdown(category: "Delivery", amount: 36.25, percentage: 25),
            BillAnalysis.CostBreakdown(category: "Taxes", amount: 14.75, percentage: 10)
        ]
    )
    .padding()
    .background(Color.billixLightGreen)
}

#Preview("Insights") {
    InsightsSection(
        insights: [
            BillAnalysis.Insight(type: .warning, title: "Higher Usage", description: "Your usage is 20% higher than last month"),
            BillAnalysis.Insight(type: .savings, title: "Off-Peak Savings", description: "Shifting usage to off-peak hours could save $8/month")
        ]
    )
    .padding()
    .background(Color.billixLightGreen)
}
