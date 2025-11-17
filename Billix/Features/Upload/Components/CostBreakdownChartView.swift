import SwiftUI
import Charts

struct CostBreakdownChartView: View {
    let costBreakdown: [BillAnalysis.CostBreakdown]

    @State private var selectedCategory: String?
    @State private var isAnimated = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.billixDarkTeal)
                Text("Cost Breakdown")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.billixNavyBlue)

                Spacer()

                if let selected = selectedCategory,
                   let item = costBreakdown.first(where: { $0.category == selected }) {
                    Text(String(format: "%.1f%%", item.percentage))
                        .font(.headline)
                        .foregroundColor(.billixMoneyGreen)
                }
            }

            if costBreakdown.isEmpty {
                emptyState
            } else {
                HStack(spacing: 24) {
                    // Donut chart
                    Chart(costBreakdown, id: \.category) { item in
                        SectorMark(
                            angle: .value("Amount", isAnimated ? item.amount : 0),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(categoryColor(for: item.category))
                        .opacity(selectedCategory == nil || selectedCategory == item.category ? 1.0 : 0.4)
                    }
                    .frame(width: 140, height: 140)
                    .chartAngleSelection(value: $selectedCategory)

                    // Legend
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(costBreakdown, id: \.category) { item in
                            LegendRow(
                                category: item.category,
                                amount: item.amount,
                                percentage: item.percentage,
                                color: categoryColor(for: item.category),
                                isSelected: selectedCategory == item.category
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = selectedCategory == item.category ? nil : item.category
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.billixNavyBlue.opacity(0.08), radius: 10, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimated = true
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No breakdown available")
                .font(.subheadline)
                .foregroundColor(.billixDarkTeal)
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Functions

    private func categoryColor(for category: String) -> Color {
        let lowercased = category.lowercased()

        switch lowercased {
        case let c where c.contains("supply") || c.contains("power") || c.contains("energy"):
            return .blue
        case let c where c.contains("delivery") || c.contains("distribution"):
            return .purple
        case let c where c.contains("tax"):
            return .orange
        case let c where c.contains("fee"):
            return .red
        case let c where c.contains("credit") || c.contains("discount"):
            return .green
        default:
            return .gray
        }
    }
}

// MARK: - Legend Row

struct LegendRow: View {
    let category: String
    let amount: Double
    let percentage: Double
    let color: Color
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Color indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)

            // Category name
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.billixNavyBlue)
                    .lineLimit(1)

                Text(formatCurrency(amount))
                    .font(.caption2)
                    .foregroundColor(.billixDarkTeal)
            }

            Spacer(minLength: 4)

            // Percentage
            Text(String(format: "%.1f%%", percentage))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? color.opacity(0.1) : Color.clear)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }
}
