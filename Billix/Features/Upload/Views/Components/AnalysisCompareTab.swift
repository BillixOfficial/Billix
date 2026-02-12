//
//  AnalysisCompareTab.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI
import Charts

/// Compare tab - Market position visualization with bar chart
struct AnalysisCompareTab: View {
    let analysis: BillAnalysis

    @State private var animatedProgress: CGFloat = 0
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if let comparison = analysis.marketplaceComparison {
                    // Bar chart comparison
                    barChartSection(comparison)

                    // Position indicator
                    positionIndicatorSection(comparison)

                    // Context info
                    contextSection(comparison)
                } else {
                    // No comparison data available
                    noComparisonView
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Bar Chart Section

    private func barChartSection(_ comparison: BillAnalysis.MarketplaceComparison) -> some View {
        let data = [
            ComparisonItem(label: "Your Bill", amount: analysis.amount, color: positionColor(comparison.position)),
            ComparisonItem(label: "Area Avg", amount: comparison.areaAverage, color: .billixChartBlue)
        ]

        return VStack(alignment: .leading, spacing: 16) {
            Text("Bill Comparison")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            Chart(data) { item in
                BarMark(
                    x: .value("Amount", item.amount * animatedProgress),
                    y: .value("Category", item.label)
                )
                .foregroundStyle(item.color)
                .cornerRadius(6)
                .annotation(position: .trailing, alignment: .leading, spacing: 8) {
                    Text("$\(String(format: "%.0f", item.amount))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.billixMediumGreen)
                }
            }
            .frame(height: 120)
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
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animatedProgress = 1.0
            }
        }
    }

    // MARK: - Position Indicator Section

    private func positionIndicatorSection(_ comparison: BillAnalysis.MarketplaceComparison) -> some View {
        let minValue = comparison.areaAverage * 0.5
        let maxValue = comparison.areaAverage * 1.5
        let position = (analysis.amount - minValue) / (maxValue - minValue)
        let clampedPosition = max(0, min(1, position))

        return VStack(alignment: .leading, spacing: 16) {
            Text("Your Position")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            VStack(spacing: 12) {
                // Position bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background gradient bar
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.billixMoneyGreen, .billixSavingsYellow, .billixVotePink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 16)

                        // Position indicator
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .fill(positionColor(comparison.position))
                                    .frame(width: 12, height: 12)
                            )
                            .offset(x: (geometry.size.width - 24) * animatedProgress * clampedPosition)

                        // Average marker
                        Rectangle()
                            .fill(Color.billixDarkGreen)
                            .frame(width: 2, height: 24)
                            .offset(x: geometry.size.width * 0.5 - 1)
                    }
                }
                .frame(height: 24)

                // Labels
                HStack {
                    Text("$\(String(format: "%.0f", minValue))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixLightGreenText)

                    Spacer()

                    VStack(spacing: 2) {
                        Text("Avg")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                        Text("$\(String(format: "%.0f", comparison.areaAverage))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.billixDarkGreen)
                    }

                    Spacer()

                    Text("$\(String(format: "%.0f", maxValue))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixLightGreenText)
                }

                // Status message
                HStack(spacing: 8) {
                    Image(systemName: positionIcon(comparison.position))
                        .font(.system(size: 14, weight: .semibold))

                    Text(positionMessage(comparison))
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(positionColor(comparison.position))
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
    }

    // MARK: - Context Section

    private func contextSection(_ comparison: BillAnalysis.MarketplaceComparison) -> some View {
        HStack(spacing: 16) {
            // ZIP context
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.billixChartBlue)

                Text("ZIP: \(comparison.zipPrefix)xx")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }

            Spacer()

            // Difference badge
            HStack(spacing: 4) {
                Image(systemName: comparison.position == .below ? "arrow.down" : comparison.position == .above ? "arrow.up" : "equal")
                    .font(.system(size: 11, weight: .bold))

                Text("\(String(format: "%.1f", abs(comparison.percentDiff)))%")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(positionColor(comparison.position))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(positionColor(comparison.position).opacity(0.15))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - No Comparison View

    private var noComparisonView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.billixLightGreenText)

            Text("No Comparison Data")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            Text("We couldn't find enough data in your area to provide a comparison. Try adding your ZIP code for better results.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.billixMediumGreen)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
    }

    // MARK: - Helpers

    private func positionColor(_ position: BillAnalysis.MarketplaceComparison.Position) -> Color {
        switch position {
        case .below: return .billixMoneyGreen
        case .average: return .billixChartBlue
        case .above: return .billixVotePink
        }
    }

    private func positionIcon(_ position: BillAnalysis.MarketplaceComparison.Position) -> String {
        switch position {
        case .below: return "arrow.down.circle.fill"
        case .average: return "equal.circle.fill"
        case .above: return "arrow.up.circle.fill"
        }
    }

    private func positionMessage(_ comparison: BillAnalysis.MarketplaceComparison) -> String {
        switch comparison.position {
        case .below:
            return "You're paying less than \(Int(100 - comparison.percentDiff))% of your neighbors"
        case .average:
            return "You're paying about the same as your neighbors"
        case .above:
            return "You're paying more than \(Int(100 - comparison.percentDiff))% of your neighbors"
        }
    }
}

// MARK: - Supporting Types

struct ComparisonItem: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
    let color: Color
}

// MARK: - Preview

#Preview {
    AnalysisCompareTab(
        analysis: BillAnalysis(
            provider: "DTE Energy",
            amount: 142.50,
            billDate: "2024-11-15",
            dueDate: nil,
            accountNumber: nil,
            category: "Electric",
            zipCode: "48127",
            keyFacts: nil,
            lineItems: [],
            costBreakdown: nil,
            insights: nil,
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
        )
    )
    .background(Color.billixLightGreen)
}
