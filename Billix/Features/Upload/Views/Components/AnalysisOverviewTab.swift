//
//  AnalysisOverviewTab.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Overview tab - Hero dashboard showing all key metrics at a glance
/// No scrolling needed - everything visible on one screen
struct AnalysisOverviewTab: View {
    let analysis: BillAnalysis

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Hero gauge section
            gaugeSection
                .padding(.top, 8)

            // Metrics grid
            metricsGrid

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Gauge Section

    @ViewBuilder
    private var gaugeSection: some View {
        if let comparison = analysis.marketplaceComparison {
            BillGaugeView(
                billAmount: analysis.amount,
                areaAverage: comparison.areaAverage,
                percentDiff: comparison.percentDiff,
                position: comparison.position
            )
        } else {
            SimpleBillGaugeView(
                billAmount: analysis.amount,
                provider: analysis.provider,
                category: analysis.category
            )
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
}

// MARK: - Preview

#Preview {
    AnalysisOverviewTab(
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
                position: .above
            )
        )
    )
    .background(Color.billixLightGreen)
}
