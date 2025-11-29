//
//  AnalysisDetailsTab.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Details tab - Key facts and expandable line items
struct AnalysisDetailsTab: View {
    let analysis: BillAnalysis

    @State private var expandedItems: Set<String> = []
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Key facts section
                if let keyFacts = analysis.keyFacts, !keyFacts.isEmpty {
                    keyFactsSection(keyFacts)
                } else {
                    // Build key facts from available data
                    builtInKeyFactsSection
                }

                // Line items section
                if !analysis.lineItems.isEmpty {
                    lineItemsSection
                }

                // Total
                totalSection

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Key Facts Section

    private func keyFactsSection(_ keyFacts: [BillAnalysis.KeyFact]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Facts")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            VStack(spacing: 0) {
                ForEach(keyFacts, id: \.label) { fact in
                    KeyFactRow(
                        icon: fact.icon ?? "info.circle",
                        label: fact.label,
                        value: fact.value
                    )

                    if fact.label != keyFacts.last?.label {
                        Divider()
                            .background(Color.billixBorderGreen)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
        }
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var builtInKeyFactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bill Details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            VStack(spacing: 0) {
                KeyFactRow(
                    icon: categoryIcon,
                    label: "Provider",
                    value: analysis.provider
                )

                Divider().background(Color.billixBorderGreen)

                KeyFactRow(
                    icon: "tag.fill",
                    label: "Category",
                    value: analysis.category
                )

                Divider().background(Color.billixBorderGreen)

                KeyFactRow(
                    icon: "calendar",
                    label: "Bill Date",
                    value: formatDate(analysis.billDate)
                )

                if let dueDate = analysis.dueDate {
                    Divider().background(Color.billixBorderGreen)

                    KeyFactRow(
                        icon: "calendar.badge.clock",
                        label: "Due Date",
                        value: formatDate(dueDate)
                    )
                }

                if let accountNumber = analysis.accountNumber {
                    Divider().background(Color.billixBorderGreen)

                    KeyFactRow(
                        icon: "number",
                        label: "Account",
                        value: accountNumber
                    )
                }

                if let zipCode = analysis.zipCode {
                    Divider().background(Color.billixBorderGreen)

                    KeyFactRow(
                        icon: "mappin.circle.fill",
                        label: "ZIP Code",
                        value: zipCode
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
        }
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - Line Items Section

    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Line Items")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Text("\(analysis.lineItems.count) items")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }

            VStack(spacing: 0) {
                ForEach(analysis.lineItems) { item in
                    ExpandableLineItemRow(
                        item: item,
                        isExpanded: expandedItems.contains(item.id),
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if expandedItems.contains(item.id) {
                                    expandedItems.remove(item.id)
                                } else {
                                    expandedItems.insert(item.id)
                                }
                            }
                        }
                    )

                    if item.id != analysis.lineItems.last?.id {
                        Divider()
                            .background(Color.billixBorderGreen)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
        }
    }

    // MARK: - Total Section

    private var totalSection: some View {
        HStack {
            Text("Total")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            Spacer()

            Text("$\(String(format: "%.2f", analysis.amount))")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.billixMoneyGreen)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.billixMoneyGreen.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.billixMoneyGreen.opacity(0.3), lineWidth: 1)
                )
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
        default: return "building.2.fill"
        }
    }

    private func formatDate(_ dateString: String) -> String {
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
}

// MARK: - Key Fact Row

struct KeyFactRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.billixChartBlue)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.billixMediumGreen)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
                .multilineTextAlignment(.trailing)
        }
        .padding(16)
    }
}

// MARK: - Expandable Line Item Row

struct ExpandableLineItemRow: View {
    let item: BillAnalysis.LineItem
    let isExpanded: Bool
    let onTap: () -> Void

    private var hasDetails: Bool {
        item.quantity != nil || item.rate != nil || item.explanation != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Expand/collapse indicator
                    if hasDetails {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.billixMediumGreen)
                            .frame(width: 16)
                    } else {
                        Circle()
                            .fill(Color.billixChartBlue)
                            .frame(width: 6, height: 6)
                            .frame(width: 16)
                    }

                    // Description
                    Text(item.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.billixDarkGreen)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    // Amount
                    Text("$\(String(format: "%.2f", item.amount))")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded details
            if isExpanded && hasDetails {
                VStack(alignment: .leading, spacing: 8) {
                    // Quantity x Rate
                    if let quantity = item.quantity, let rate = item.rate {
                        HStack(spacing: 4) {
                            Text("\(String(format: "%.0f", quantity))")
                                .font(.system(size: 12, weight: .semibold))
                            Text(item.unit ?? "units")
                                .font(.system(size: 12, weight: .regular))
                            Text("×")
                                .font(.system(size: 12, weight: .regular))
                            Text("$\(String(format: "%.4f", rate))")
                                .font(.system(size: 12, weight: .semibold))
                            Text("/\(item.unit ?? "unit")")
                                .font(.system(size: 12, weight: .regular))
                        }
                        .foregroundColor(.billixMediumGreen)
                    }

                    // Explanation
                    if let explanation = item.explanation {
                        Text(explanation)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.billixLightGreenText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Category badge
                    if let category = item.category {
                        Text(category)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.billixChartBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.billixChartBlue.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 44)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(isExpanded ? Color.billixLightGreen.opacity(0.5) : Color.clear)
    }
}

// MARK: - Preview

#Preview {
    AnalysisDetailsTab(
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
                BillAnalysis.LineItem(description: "Power Supply", amount: 78.00, category: "Supply", quantity: 850, rate: 0.0918, unit: "kWh", explanation: "Energy generation cost"),
                BillAnalysis.LineItem(description: "Delivery Charges", amount: 42.00, category: "Delivery"),
                BillAnalysis.LineItem(description: "State Tax", amount: 12.50, category: "Taxes"),
                BillAnalysis.LineItem(description: "Regulatory Fees", amount: 10.00, category: "Fees")
            ],
            costBreakdown: nil,
            insights: nil,
            marketplaceComparison: nil
        )
    )
    .background(Color.billixLightGreen)
}
