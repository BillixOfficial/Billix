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
                Text(bill.providerName ?? "Unknown Provider")
                    .font(.headline)
                    .lineLimit(1)

                Text(bill.formattedAmount)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.billixDarkTeal)

                if let dueDate = bill.formattedDueDate {
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
                statusBadge

                if let days = bill.daysUntilDue {
                    Text(daysText(days))
                        .font(.caption2)
                        .foregroundColor(dueDateColor)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .contextMenu {
            if showActions {
                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
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
