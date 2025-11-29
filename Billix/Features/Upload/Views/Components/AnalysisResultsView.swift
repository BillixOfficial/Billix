//
//  AnalysisResultsView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Main container for Full Analysis results with tabbed navigation
/// Displays analysis data in 4 organized tabs: Overview, Breakdown, Compare, Details
struct AnalysisResultsView: View {
    let analysis: BillAnalysis
    let onComplete: () -> Void

    @State private var selectedTab: AnalysisTab = .overview
    @State private var appeared = false
    @Namespace private var tabAnimation

    enum AnalysisTab: String, CaseIterable {
        case overview = "Overview"
        case breakdown = "Breakdown"
        case compare = "Compare"
        case details = "Details"

        var icon: String {
            switch self {
            case .overview: return "gauge.medium"
            case .breakdown: return "chart.pie.fill"
            case .compare: return "chart.bar.fill"
            case .details: return "list.bullet.rectangle"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom segmented control
            segmentedControl
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // Tab content
            TabView(selection: $selectedTab) {
                AnalysisOverviewTab(analysis: analysis)
                    .tag(AnalysisTab.overview)

                AnalysisBreakdownTab(analysis: analysis)
                    .tag(AnalysisTab.breakdown)

                AnalysisCompareTab(analysis: analysis)
                    .tag(AnalysisTab.compare)

                AnalysisDetailsTab(analysis: analysis)
                    .tag(AnalysisTab.details)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)

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

    // MARK: - Segmented Control

    private var segmentedControl: some View {
        HStack(spacing: 4) {
            ForEach(AnalysisTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.billixBorderGreen.opacity(0.5))
        )
    }

    private func tabButton(for tab: AnalysisTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 11, weight: .semibold))

                if selectedTab == tab {
                    Text(tab.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .foregroundColor(selectedTab == tab ? .white : .billixMediumGreen)
            .padding(.horizontal, selectedTab == tab ? 12 : 10)
            .padding(.vertical, 8)
            .background(
                Group {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.billixChartBlue)
                            .matchedGeometryEffect(id: "selectedTab", in: tabAnimation)
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
}

// MARK: - Embedded Version (for UploadDetailView)

/// Embedded version of AnalysisResultsView without the Done button
/// Used when the analysis is shown inside another view that has its own navigation
struct AnalysisResultsEmbeddedView: View {
    let analysis: BillAnalysis

    @State private var selectedTab: AnalysisResultsView.AnalysisTab = .overview
    @State private var appeared = false
    @Namespace private var tabAnimation

    var body: some View {
        VStack(spacing: 0) {
            // Custom segmented control
            segmentedControl
                .padding(.bottom, 8)

            // Tab content - fixed height to avoid scroll issues
            TabView(selection: $selectedTab) {
                AnalysisOverviewTab(analysis: analysis)
                    .tag(AnalysisResultsView.AnalysisTab.overview)

                AnalysisBreakdownTab(analysis: analysis)
                    .tag(AnalysisResultsView.AnalysisTab.breakdown)

                AnalysisCompareTab(analysis: analysis)
                    .tag(AnalysisResultsView.AnalysisTab.compare)

                AnalysisDetailsTab(analysis: analysis)
                    .tag(AnalysisResultsView.AnalysisTab.details)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
            .frame(minHeight: 500)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var segmentedControl: some View {
        HStack(spacing: 4) {
            ForEach(AnalysisResultsView.AnalysisTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.billixBorderGreen.opacity(0.5))
        )
    }

    private func tabButton(for tab: AnalysisResultsView.AnalysisTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 11, weight: .semibold))

                if selectedTab == tab {
                    Text(tab.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .foregroundColor(selectedTab == tab ? .white : .billixMediumGreen)
            .padding(.horizontal, selectedTab == tab ? 12 : 10)
            .padding(.vertical, 8)
            .background(
                Group {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.billixChartBlue)
                            .matchedGeometryEffect(id: "embeddedSelectedTab", in: tabAnimation)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    AnalysisResultsView(
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
                BillAnalysis.LineItem(description: "Power Supply", amount: 78.00, category: "Supply", quantity: 850, rate: 0.092, unit: "kWh"),
                BillAnalysis.LineItem(description: "Delivery Charges", amount: 42.00, category: "Delivery"),
                BillAnalysis.LineItem(description: "Taxes & Fees", amount: 22.50, category: "Taxes")
            ],
            costBreakdown: [
                BillAnalysis.CostBreakdown(category: "Power Supply", amount: 78.00, percentage: 55),
                BillAnalysis.CostBreakdown(category: "Delivery", amount: 42.00, percentage: 29),
                BillAnalysis.CostBreakdown(category: "Taxes & Fees", amount: 22.50, percentage: 16)
            ],
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
