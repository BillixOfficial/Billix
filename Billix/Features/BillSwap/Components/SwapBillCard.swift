//
//  SwapBillCard.swift
//  Billix
//
//  Card component for displaying bills in the swap marketplace
//

import SwiftUI

struct SwapBillCard: View {
    let bill: SwapBill
    var showActions: Bool = false
    var semiBlind: Bool = false  // Semi-blind mode: only show bill type + amount + location
    var isVerified: Bool = false // Whether the bill owner is verified
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: bill.category?.icon ?? "doc.fill")
                    .font(.title2)
                    .foregroundColor(categoryColor)
            }

            // Bill details
            VStack(alignment: .leading, spacing: 4) {
                if semiBlind {
                    // Semi-blind: show category name instead of provider
                    HStack(spacing: 6) {
                        Text(bill.category?.displayName ?? "Bill")
                            .font(.headline)
                            .lineLimit(1)

                        if isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.billixMoneyGreen)
                        }
                    }
                } else {
                    Text(bill.providerName ?? "Unknown Provider")
                        .font(.headline)
                        .lineLimit(1)
                }

                // Amount - show approximate in semi-blind mode
                Text(semiBlind ? approximateAmount : bill.formattedAmount)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.billixDarkTeal)

                if semiBlind {
                    // Show location instead of due date in semi-blind mode
                    if let location = bill.cityFromZip {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.caption2)
                            Text(location)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                } else if let dueDate = bill.formattedDueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text("Due: \(dueDate)")
                            .font(.caption)
                    }
                    .foregroundColor(dueDateColor)
                }
            }

            Spacer()

            // Status badge
            VStack(alignment: .trailing, spacing: 8) {
                if semiBlind {
                    // In semi-blind mode, show "Available" instead of status
                    Text("Available")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.billixMoneyGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.billixMoneyGreen.opacity(0.1))
                        .cornerRadius(4)
                } else {
                    statusBadge

                    if let days = bill.daysUntilDue {
                        Text(daysText(days))
                            .font(.caption2)
                            .foregroundColor(dueDateColor)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .contextMenu {
            if showActions && !semiBlind {
                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Semi-Blind Helpers

    /// Approximate amount (rounded to nearest $5)
    private var approximateAmount: String {
        let value = NSDecimalNumber(decimal: bill.amount).doubleValue
        let rounded = (value / 5.0).rounded() * 5.0
        return "~$\(Int(rounded))"
    }

    // MARK: - Computed Properties

    private var categoryColor: Color {
        bill.category?.color ?? .gray
    }

    private var dueDateColor: Color {
        guard let days = bill.daysUntilDue else { return .secondary }

        if days < 0 {
            return .red
        } else if days <= 3 {
            return .orange
        } else {
            return .secondary
        }
    }

    private var statusBadge: some View {
        Text(bill.status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(4)
    }

    private var statusColor: Color {
        switch bill.status {
        case .unmatched: return .orange
        case .matched: return .blue
        case .paid: return .green
        }
    }

    private func daysText(_ days: Int) -> String {
        if days < 0 {
            return "\(abs(days)) days overdue"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else {
            return "\(days) days left"
        }
    }
}

// MARK: - Compact Bill Card

struct SwapCompactBillCard: View {
    let bill: SwapBill

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: bill.category?.icon ?? "doc.fill")
                .font(.title3)
                .foregroundColor(.billixDarkTeal)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(bill.providerName ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(bill.formattedAmount)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(bill.status.rawValue.capitalized)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview("Swap Bill Card") {
    VStack(spacing: 16) {
        SwapBillCard(bill: SwapBill.mockBills[0])
        SwapBillCard(bill: SwapBill.mockBills[1])
        SwapBillCard(bill: SwapBill.mockBills[2])
    }
    .padding()
    .background(Color(.systemGray6))
}

#Preview("Swap Compact Bill Card") {
    VStack(spacing: 8) {
        SwapCompactBillCard(bill: SwapBill.mockBills[0])
        SwapCompactBillCard(bill: SwapBill.mockBills[1])
    }
    .padding()
}
