//
//  DealBillPanelView.swift
//  Billix
//
//  Deal Sheet Bill Panel for Swap Detail View
//

import SwiftUI

struct DealBillPanelView: View {
    let panel: DealSheetBillPanel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(panel.headerText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Spacer()

                // Tier badge
                HStack(spacing: 4) {
                    Image(systemName: panel.billInfo.ownerTier.icon)
                        .font(.system(size: 10))
                    Text(panel.billInfo.tierDisplayName)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(Color(hex: panel.billInfo.tierBadgeColor))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: panel.billInfo.tierBadgeColor).opacity(0.12))
                .cornerRadius(6)
            }

            // Biller name with category icon
            HStack(spacing: 8) {
                Image(systemName: panel.billInfo.categoryIcon)
                    .font(.system(size: 16))
                    .foregroundColor(.billixDarkTeal)
                    .frame(width: 28, height: 28)
                    .background(Color.billixDarkTeal.opacity(0.1))
                    .cornerRadius(6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(panel.billInfo.billerName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(panel.billInfo.categoryDisplayName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            // Amount
            Text(panel.billInfo.formattedAmount)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(panel.isOwner ? .billixDarkTeal : .primary)

            // Account number (masked)
            HStack(spacing: 4) {
                Image(systemName: "creditcard")
                    .font(.system(size: 10))
                Text(panel.billInfo.maskedAccountNumber)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.secondary)

            // Due date
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 10))

                Text(panel.billInfo.dueDateUrgencyText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(panel.billInfo.isUrgent ? .orange : .secondary)
            }

            Divider()

            // Status
            HStack(spacing: 6) {
                Image(systemName: panel.statusIcon)
                    .font(.system(size: 12))
                Text(panel.statusText)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(Color(hex: panel.statusColor))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panel.isOwner ? Color.billixDarkTeal.opacity(0.05) : Color.gray.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(panel.isOwner ? Color.billixDarkTeal.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Deal Sheet Layout

struct DealSheetView: View {
    let yourPanel: DealSheetBillPanel
    let theirPanel: DealSheetBillPanel
    let swap: BillSwap

    var body: some View {
        VStack(spacing: 16) {
            // Side-by-side panels
            HStack(spacing: 12) {
                DealBillPanelView(panel: yourPanel)
                    .frame(maxWidth: .infinity)

                // Center lock icon
                VStack {
                    ZStack {
                        Circle()
                            .fill(swapStatusColor.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: swapStatusIcon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(swapStatusColor)
                    }

                    Text(swap.status.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(swapStatusColor)
                }
                .frame(width: 50)

                DealBillPanelView(panel: theirPanel)
                    .frame(maxWidth: .infinity)
            }

            // Fee summary
            FeesSummaryView(swap: swap)
        }
    }

    private var swapStatusIcon: String {
        switch swap.status {
        case .offered, .countered: return "arrow.left.arrow.right"
        case .acceptedPendingFee: return "creditcard"
        case .locked: return "lock.fill"
        case .awaitingProof: return "doc.badge.clock"
        case .completed: return "checkmark.seal.fill"
        case .failed, .disputed: return "exclamationmark.triangle.fill"
        default: return "xmark.circle"
        }
    }

    private var swapStatusColor: Color {
        Color(hex: swap.status.color)
    }
}

// MARK: - Fees Summary

struct FeesSummaryView: View {
    let swap: BillSwap

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Fee Summary")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }

            HStack {
                Text("Facilitation Fee")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                Text("$1.99")
                    .font(.system(size: 12, weight: .medium))
            }

            if swap.spreadFeeCents > 0 {
                HStack {
                    Text("Spread Fee (3%)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "$%.2f", Double(swap.spreadFeeCents) / 100.0))
                        .font(.system(size: 12, weight: .medium))
                }
            }

            Divider()

            HStack {
                Text("Your Total")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(String(format: "$%.2f", Double(swap.feeAmountCentsInitiator) / 100.0))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.billixDarkTeal)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Compact Deal Preview

struct CompactDealPreview: View {
    let yourBillInfo: RedactedBillInfo
    let theirBillInfo: RedactedBillInfo

    var body: some View {
        HStack(spacing: 8) {
            // Your bill
            VStack(alignment: .leading, spacing: 4) {
                Text("You Pay")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(theirBillInfo.formattedAmount)
                    .font(.system(size: 16, weight: .bold))
                Text(theirBillInfo.billerName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            // Their bill
            VStack(alignment: .trailing, spacing: 4) {
                Text("They Pay")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(yourBillInfo.formattedAmount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixDarkTeal)
                Text(yourBillInfo.billerName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            DealBillPanelView(
                panel: DealSheetBillPanel(
                    isOwner: true,
                    billInfo: RedactedBillInfo.mockBill,
                    status: .readyToBePaid
                )
            )

            DealBillPanelView(
                panel: DealSheetBillPanel(
                    isOwner: false,
                    billInfo: RedactedBillInfo.mockBill2,
                    status: .pendingPayment(dueDate: Date().addingTimeInterval(86400 * 3))
                )
            )

            CompactDealPreview(
                yourBillInfo: RedactedBillInfo.mockBill,
                theirBillInfo: RedactedBillInfo.mockBill2
            )
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}
