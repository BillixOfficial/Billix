import SwiftUI

struct AnalysisResultsView: View {
    let analysis: BillAnalysis
    let onSave: () -> Void
    let onDismiss: () -> Void

    @State private var showingSaveConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Header Section
                VStack(spacing: 12) {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.billixMoneyGreen.opacity(0.2), Color.billixDarkTeal.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.billixMoneyGreen, Color.billixDarkTeal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    // Provider name
                    Text(analysis.provider)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)

                    // Total amount
                    Text(formatCurrency(analysis.amount))
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.billixNavyBlue, Color.billixDarkTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.top, 20)

                // MARK: - Bill Summary Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bill Summary")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.billixNavyBlue)

                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("BILL DATE")
                                    .font(.caption)
                                    .foregroundColor(.billixDarkTeal)
                                Text(formatDateString(analysis.billDate))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.billixNavyBlue)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("DUE DATE")
                                    .font(.caption)
                                    .foregroundColor(.billixDarkTeal)
                                Text(analysis.dueDate.map { formatDateString($0) } ?? "N/A")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.billixNavyBlue)
                            }
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CATEGORY")
                                    .font(.caption)
                                    .foregroundColor(.billixDarkTeal)
                                Text(analysis.category)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.billixNavyBlue)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("TOTAL AMOUNT")
                                    .font(.caption)
                                    .foregroundColor(.billixDarkTeal)
                                Text(formatCurrency(analysis.amount))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.billixNavyBlue)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }

                // MARK: - Marketplace Comparison Section
                if let comparison = analysis.marketplaceComparison {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(comparisonColor(for: comparison.position))
                            Text("Marketplace Comparison")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.billixNavyBlue)
                        }

                        VStack(spacing: 16) {
                            // Visual scale
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Lower")
                                        .font(.caption2)
                                        .foregroundColor(.billixDarkTeal)
                                    Spacer()
                                    Text("Area Average")
                                        .font(.caption2)
                                        .foregroundColor(.billixDarkTeal)
                                    Spacer()
                                    Text("Higher")
                                        .font(.caption2)
                                        .foregroundColor(.billixDarkTeal)
                                }

                                // Gradient bar with position marker
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background gradient
                                        LinearGradient(
                                            colors: [Color.billixMoneyGreen, Color.yellow, Color.red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .frame(height: 32)
                                        .cornerRadius(16)

                                        // Average marker (center)
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.7))
                                            .frame(width: 2, height: 32)
                                            .offset(x: geometry.size.width / 2)

                                        // User's position marker
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.billixNavyBlue, lineWidth: 2)
                                            )
                                            .offset(x: markerPosition(for: comparison.percentDiff, in: geometry.size.width) - 8)
                                    }
                                }
                                .frame(height: 32)
                            }

                            // Comparison values
                            HStack {
                                VStack(spacing: 4) {
                                    Text("Your Bill")
                                        .font(.caption)
                                        .foregroundColor(.billixDarkTeal)
                                    Text(formatCurrency(analysis.amount))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.billixNavyBlue)
                                }

                                Text("vs")
                                    .font(.headline)
                                    .foregroundColor(.billixDarkTeal)
                                    .padding(.horizontal)

                                VStack(spacing: 4) {
                                    Text("Area Average (ZIP \(comparison.zipPrefix)**)")
                                        .font(.caption)
                                        .foregroundColor(.billixDarkTeal)
                                    Text(formatCurrency(comparison.areaAverage))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.billixNavyBlue)
                                }
                            }

                            // Status message
                            HStack(spacing: 8) {
                                Image(systemName: comparisonIcon(for: comparison.position))
                                    .foregroundColor(comparisonColor(for: comparison.position))
                                Text(comparisonMessage(for: comparison))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.billixNavyBlue)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(comparisonBackgroundColor(for: comparison.position))
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                }

                // MARK: - Key Information Section
                if let keyFacts = analysis.keyFacts, !keyFacts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Key Information")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.billixNavyBlue)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(keyFacts, id: \.label) { fact in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fact.label.uppercased())
                                        .font(.caption)
                                        .foregroundColor(.billixDarkTeal)
                                    Text(fact.value)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.billixNavyBlue)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                // MARK: - Cost Breakdown Section
                if let costBreakdown = analysis.costBreakdown, !costBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cost Breakdown")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.billixNavyBlue)

                        VStack(spacing: 12) {
                            ForEach(costBreakdown, id: \.category) { item in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(item.category)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.billixNavyBlue)
                                        Spacer()
                                        Text(formatCurrency(item.amount))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.billixNavyBlue)
                                        Text("(\(String(format: "%.1f", item.percentage))%)")
                                            .font(.caption)
                                            .foregroundColor(.billixDarkTeal)
                                    }

                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(height: 8)
                                                .cornerRadius(4)

                                            Rectangle()
                                                .fill(categoryColor(for: item.category))
                                                .frame(width: geometry.size.width * CGFloat(item.percentage / 100), height: 8)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                }

                // MARK: - Complete Breakdown Section (Grouped by Category)
                if !analysis.lineItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Complete Breakdown")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.billixNavyBlue)

                        let groupedItems = Dictionary(grouping: analysis.lineItems) { $0.category ?? "Other" }

                        ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                            if let items = groupedItems[category] {
                                VStack(alignment: .leading, spacing: 8) {
                                    // Category header with subtotal
                                    HStack {
                                        Text(category.uppercased())
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.billixDarkTeal)
                                        Spacer()
                                        Text(formatCurrency(items.reduce(0) { $0 + $1.amount }))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.billixNavyBlue)
                                    }
                                    .padding(.bottom, 4)

                                    // Line items in this category
                                    ForEach(items) { item in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(item.description)
                                                    .font(.body)
                                                    .foregroundColor(.billixNavyBlue)
                                                Spacer()
                                                Text(formatCurrency(item.amount))
                                                    .font(.headline)
                                                    .foregroundColor(.billixNavyBlue)
                                            }

                                            if let quantity = item.quantity, let rate = item.rate, let unit = item.unit {
                                                Text("\(String(format: "%.3f", quantity)) \(unit) × \(formatCurrency(rate))")
                                                    .font(.caption)
                                                    .foregroundColor(.billixDarkTeal)
                                            }

                                            if let explanation = item.explanation {
                                                Text(explanation)
                                                    .font(.caption)
                                                    .italic()
                                                    .foregroundColor(.billixDarkTeal)
                                                    .padding(.top, 2)
                                            }
                                        }
                                        .padding(.vertical, 8)

                                        if item.id != items.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                }

                // MARK: - Enhanced AI Insights Section
                if let insights = analysis.insights, !insights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.billixGoldenAmber)
                            Text("AI Insights")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.billixNavyBlue)
                        }

                        ForEach(insights, id: \.title) { insight in
                            HStack(alignment: .top, spacing: 12) {
                                insightIcon(for: insight.type)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(insight.title)
                                        .font(.headline)
                                        .foregroundColor(.billixNavyBlue)
                                    Text(insight.description)
                                        .font(.body)
                                        .foregroundColor(.billixNavyBlue)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(insightBackgroundColor(for: insight.type))
                            .cornerRadius(12)
                        }
                    }
                }

                // MARK: - Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onSave()
                        showingSaveConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Bill")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.billixMoneyGreen, Color.billixDarkTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }

                    Button(action: onDismiss) {
                        Text("Upload Another Bill")
                            .foregroundColor(.billixNavyBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(16)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.billixCreamBeige.ignoresSafeArea())
        .alert("Bill Saved!", isPresented: $showingSaveConfirmation) {
            Button("OK", action: onDismiss)
        } message: {
            Text("Your bill has been saved successfully.")
        }
    }

    // MARK: - Helper Methods

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }

    private func formatDateString(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    private func markerPosition(for percentDiff: Double, in width: CGFloat) -> CGFloat {
        // Map percentDiff to position on the scale
        // -100% (way below) -> 0%, 0% (average) -> 50%, +100% (way above) -> 100%
        let normalizedPosition = max(0, min(100, 50 + (percentDiff / 2)))
        return width * CGFloat(normalizedPosition / 100)
    }

    private func comparisonColor(for position: BillAnalysis.MarketplaceComparison.Position) -> Color {
        switch position {
        case .below:
            return .billixMoneyGreen
        case .average:
            return .yellow
        case .above:
            return .red
        }
    }

    private func comparisonIcon(for position: BillAnalysis.MarketplaceComparison.Position) -> String {
        switch position {
        case .below:
            return "checkmark.circle.fill"
        case .average:
            return "checkmark.circle.fill"
        case .above:
            return "exclamationmark.triangle.fill"
        }
    }

    private func comparisonBackgroundColor(for position: BillAnalysis.MarketplaceComparison.Position) -> Color {
        switch position {
        case .below:
            return Color.billixMoneyGreen.opacity(0.1)
        case .average:
            return Color.yellow.opacity(0.1)
        case .above:
            return Color.red.opacity(0.1)
        }
    }

    private func comparisonMessage(for comparison: BillAnalysis.MarketplaceComparison) -> String {
        let percentText = String(format: "%.1f", abs(comparison.percentDiff))

        switch comparison.position {
        case .below:
            return "Excellent! You're paying \(percentText)% less than the area average."
        case .average:
            return "You're paying around the area average. This is typical for your area."
        case .above:
            return "You're paying \(percentText)% more than the area average. Consider shopping for better rates."
        }
    }

    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case let c where c.contains("power") || c.contains("supply"):
            return .blue
        case let c where c.contains("delivery"):
            return .purple
        case let c where c.contains("tax"):
            return .orange
        default:
            return .gray
        }
    }

    @ViewBuilder
    private func insightIcon(for type: BillAnalysis.Insight.InsightType) -> some View {
        switch type {
        case .savings:
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.billixMoneyGreen)
        case .warning:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
        case .info:
            Image(systemName: "info.circle.fill")
                .foregroundColor(.billixDarkTeal)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }

    private func insightBackgroundColor(for type: BillAnalysis.Insight.InsightType) -> Color {
        switch type {
        case .savings:
            return Color.billixMoneyGreen.opacity(0.1)
        case .warning:
            return Color.orange.opacity(0.1)
        case .info:
            return Color.billixDarkTeal.opacity(0.1)
        case .success:
            return Color.green.opacity(0.1)
        }
    }
}
