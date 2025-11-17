import SwiftUI

struct LineItemDisclosureView: View {
    let lineItems: [BillAnalysis.LineItem]

    @State private var expandedCategories: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.billixDarkTeal)
                Text("Line Items")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.billixNavyBlue)

                Spacer()

                Text("\(lineItems.count) items")
                    .font(.caption)
                    .foregroundColor(.billixDarkTeal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.billixDarkTeal.opacity(0.1))
                    .cornerRadius(8)
            }

            if lineItems.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    // Group items by category
                    let groupedItems = Dictionary(grouping: lineItems) { $0.category ?? "Other" }

                    ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                        if let items = groupedItems[category] {
                            CategoryDisclosureGroup(
                                category: category,
                                items: items,
                                isExpanded: expandedCategories.contains(category)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if expandedCategories.contains(category) {
                                        expandedCategories.remove(category)
                                    } else {
                                        expandedCategories.insert(category)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Expand/Collapse all button
            if !lineItems.isEmpty {
                Button(action: toggleAllCategories) {
                    HStack {
                        Image(systemName: allExpanded ? "chevron.up.circle" : "chevron.down.circle")
                        Text(allExpanded ? "Collapse All" : "Expand All")
                    }
                    .font(.caption)
                    .foregroundColor(.billixDarkTeal)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.billixNavyBlue.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No line items available")
                .font(.subheadline)
                .foregroundColor(.billixDarkTeal)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
    }

    private var allExpanded: Bool {
        let groupedItems = Dictionary(grouping: lineItems) { $0.category ?? "Other" }
        return expandedCategories.count == groupedItems.keys.count
    }

    private func toggleAllCategories() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            let groupedItems = Dictionary(grouping: lineItems) { $0.category ?? "Other" }
            if allExpanded {
                expandedCategories.removeAll()
            } else {
                expandedCategories = Set(groupedItems.keys)
            }
        }
    }
}

// MARK: - Category Disclosure Group

struct CategoryDisclosureGroup: View {
    let category: String
    let items: [BillAnalysis.LineItem]
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    // Category icon
                    Image(systemName: categoryIcon)
                        .font(.title3)
                        .foregroundColor(categoryColor)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.uppercased())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.billixNavyBlue)

                        Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.billixDarkTeal)
                    }

                    Spacer()

                    // Subtotal
                    Text(formatCurrency(items.reduce(0) { $0 + $1.amount }))
                        .font(.headline)
                        .foregroundColor(.billixNavyBlue)

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
                .background(categoryColor.opacity(0.08))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Line items (expandable)
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        LineItemRow(item: item)

                        if item.id != items.last?.id {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Helper Properties

    private var categoryIcon: String {
        let lowercased = category.lowercased()

        switch lowercased {
        case let c where c.contains("supply") || c.contains("power") || c.contains("energy"):
            return "bolt.fill"
        case let c where c.contains("delivery") || c.contains("distribution"):
            return "shippingbox.fill"
        case let c where c.contains("tax"):
            return "percent"
        case let c where c.contains("fee"):
            return "dollarsign.circle"
        case let c where c.contains("credit") || c.contains("discount"):
            return "gift.fill"
        default:
            return "square.grid.2x2"
        }
    }

    private var categoryColor: Color {
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

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }
}

// MARK: - Line Item Row

struct LineItemRow: View {
    let item: BillAnalysis.LineItem

    @State private var showExplanation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.description)
                        .font(.body)
                        .foregroundColor(.billixNavyBlue)

                    if let quantity = item.quantity, let rate = item.rate, let unit = item.unit {
                        Text("\(String(format: "%.3f", quantity)) \(unit) × \(formatCurrency(rate))")
                            .font(.caption)
                            .foregroundColor(.billixDarkTeal)
                    }
                }

                Spacer()

                Text(formatCurrency(item.amount))
                    .font(.headline)
                    .foregroundColor(.billixNavyBlue)
            }

            // Explanation (collapsible)
            if let explanation = item.explanation, !explanation.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showExplanation.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text(showExplanation ? "Hide details" : "Show details")
                            .font(.caption)
                    }
                    .foregroundColor(.billixDarkTeal)
                }

                if showExplanation {
                    Text(explanation)
                        .font(.caption)
                        .italic()
                        .foregroundColor(.billixDarkTeal)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.billixDarkTeal.opacity(0.05))
                        .cornerRadius(8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(16)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }
}
