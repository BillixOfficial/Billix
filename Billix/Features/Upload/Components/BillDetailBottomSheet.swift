import SwiftUI

struct BillDetailBottomSheet: View {
    let analysis: BillAnalysis

    @State private var selectedTab: DetailTab = .overview
    @Namespace private var animation

    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case lineItems = "Line Items"
        case insights = "Insights"

        var icon: String {
            switch self {
            case .overview:
                return "chart.bar.fill"
            case .lineItems:
                return "list.bullet"
            case .insights:
                return "lightbulb.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            // Custom segmented control
            HStack(spacing: 0) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18))

                            Text(tab.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedTab == tab ? .billixMoneyGreen : .billixDarkTeal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.billixMoneyGreen.opacity(0.1))
                                        .matchedGeometryEffect(id: "tab", in: animation)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(14)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // Content area
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .lineItems:
                        lineItemsContent
                    case .insights:
                        insightsContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.billixCreamBeige)
    }

    // MARK: - Tab Contents

    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Quick stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                QuickStatCard(
                    icon: "calendar",
                    label: "Bill Date",
                    value: formatDateString(analysis.billDate),
                    color: .blue
                )

                QuickStatCard(
                    icon: "calendar.badge.clock",
                    label: "Due Date",
                    value: analysis.dueDate.map { formatDateString($0) } ?? "N/A",
                    color: .orange
                )

                QuickStatCard(
                    icon: "tag.fill",
                    label: "Category",
                    value: analysis.category,
                    color: .purple
                )

                if let accountNumber = analysis.accountNumber {
                    QuickStatCard(
                        icon: "number",
                        label: "Account",
                        value: String(accountNumber.suffix(4)),
                        color: .green
                    )
                }
            }

            // Cost breakdown chart
            if let costBreakdown = analysis.costBreakdown, !costBreakdown.isEmpty {
                CostBreakdownChartView(costBreakdown: costBreakdown)
            }

            // Marketplace comparison
            if let comparison = analysis.marketplaceComparison {
                MarketplaceGaugeView(comparison: comparison, userAmount: analysis.amount)
            }

            // Key facts
            if let keyFacts = analysis.keyFacts, !keyFacts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Information")
                        .font(.headline)
                        .foregroundColor(.billixNavyBlue)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(keyFacts, id: \.label) { fact in
                            VStack(alignment: .leading, spacing: 4) {
                                if let icon = fact.icon {
                                    Image(systemName: icon)
                                        .font(.caption)
                                        .foregroundColor(.billixDarkTeal)
                                }

                                Text(fact.label.uppercased())
                                    .font(.caption2)
                                    .foregroundColor(.billixDarkTeal)

                                Text(fact.value)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.billixNavyBlue)
                                    .lineLimit(2)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    private var lineItemsContent: some View {
        VStack(spacing: 16) {
            if !analysis.lineItems.isEmpty {
                LineItemDisclosureView(lineItems: analysis.lineItems)
            } else {
                ContentUnavailableView(
                    "No Line Items",
                    systemImage: "doc.text",
                    description: Text("No detailed line items available for this bill")
                )
                .frame(height: 300)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    private var insightsContent: some View {
        VStack(spacing: 16) {
            if let insights = analysis.insights, !insights.isEmpty {
                InsightsCarouselView(insights: insights)

                // Additional insights info
                VStack(alignment: .leading, spacing: 12) {
                    Text("About These Insights")
                        .font(.headline)
                        .foregroundColor(.billixNavyBlue)

                    Text("Our AI analyzes your bill against millions of data points to provide personalized recommendations and identify potential savings opportunities.")
                        .font(.subheadline)
                        .foregroundColor(.billixDarkTeal)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
            } else {
                ContentUnavailableView(
                    "No Insights Available",
                    systemImage: "lightbulb.slash",
                    description: Text("AI analysis didn't generate specific insights for this bill")
                )
                .frame(height: 300)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    // MARK: - Helper Functions

    private func formatDateString(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(label.uppercased())
                    .font(.caption2)
                    .foregroundColor(.billixDarkTeal)
                    .tracking(0.5)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.billixNavyBlue)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
