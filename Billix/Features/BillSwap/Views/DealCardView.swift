//
//  DealCardView.swift
//  Billix
//
//  Component for displaying swap deal cards with terms and actions
//

import SwiftUI

// MARK: - Deal Card View

struct DealCardView: View {
    // MARK: - Properties

    let deal: SwapDeal
    let swap: BillSwapTransaction
    let onAccept: (() -> Void)?
    let onReject: (() -> Void)?
    let onCounter: (() -> Void)?

    @State private var showingRejectConfirmation = false

    // MARK: - Computed Properties

    private var isUserA: Bool {
        swap.isUserA(userId: SupabaseService.shared.currentUserId ?? UUID())
    }

    private var canRespond: Bool {
        guard let userId = SupabaseService.shared.currentUserId else { return false }
        return deal.canRespond(userId: userId)
    }

    private var isProposer: Bool {
        deal.proposerId == SupabaseService.shared.currentUserId
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with status
            headerView

            // Terms content
            termsContent

            // Actions (if can respond)
            if canRespond {
                actionButtons
            } else if isProposer && deal.status == .proposed {
                pendingIndicator
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusBorderColor, lineWidth: 2)
        )
        .alert("Reject Terms?", isPresented: $showingRejectConfirmation) {
            Button("Reject", role: .destructive) {
                onReject?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can propose different terms after rejecting.")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            // Version badge
            HStack(spacing: 4) {
                Image(systemName: "doc.text.fill")
                    .font(.caption)
                Text("Terms v\(deal.version)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.billixDarkTeal)
            .cornerRadius(8)

            Spacer()

            // Status badge
            DealStatusBadge(status: deal.status)

            // Expiration timer
            if deal.status == .proposed || deal.status == .countered {
                if let remaining = deal.formattedTimeRemaining {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(remaining)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(deal.isExpiringSoon ? .red : .secondary)
                }
            }
        }
        .padding()
        .background(Color.billixCreamBeige.opacity(0.5))
    }

    // MARK: - Terms Content

    private var termsContent: some View {
        VStack(spacing: 16) {
            // Amount exchange
            amountExchangeView

            Divider()
                .padding(.horizontal)

            // Details grid
            detailsGrid

            // Proposer info
            proposerInfo
        }
        .padding()
    }

    // MARK: - Amount Exchange View

    private var amountExchangeView: some View {
        HStack(spacing: 12) {
            // Your amount
            VStack(alignment: .leading, spacing: 4) {
                Text("You pay")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formatAmount(isUserA ? deal.amountA : deal.amountB))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.billixMoneyGreen)

                Text("by \(formatDeadline(isUserA ? deal.deadlineA : deal.deadlineB))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Exchange icon
            VStack {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.title)
                    .foregroundColor(.billixDarkTeal)

                Text(deal.whoPaysFirst.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Partner amount
            VStack(alignment: .trailing, spacing: 4) {
                Text("Partner pays")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formatAmount(isUserA ? deal.amountB : deal.amountA))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.billixDarkTeal)

                Text("by \(formatDeadline(isUserA ? deal.deadlineB : deal.deadlineA))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Details Grid

    private var detailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Proof required
            DetailCard(
                icon: deal.proofRequired.icon,
                title: "Proof Required",
                value: deal.proofRequired.displayName,
                color: .billixMoneyGreen
            )

            // Fallback action
            DetailCard(
                icon: deal.fallbackIfLate.icon,
                title: "If Late",
                value: deal.fallbackIfLate.shortName,
                color: .billixGoldenAmber
            )
        }
    }

    // MARK: - Proposer Info

    private var proposerInfo: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.secondary)

            Text(isProposer ? "You proposed these terms" : "Partner proposed these terms")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(deal.createdAt, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 12) {
                // Reject button
                Button {
                    showingRejectConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Reject")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }

                // Counter button
                if deal.canCounter {
                    Button {
                        onCounter?()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Counter")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.billixGoldenAmber)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.billixGoldenAmber.opacity(0.1))
                        .cornerRadius(10)
                    }
                }

                // Accept button
                Button {
                    onAccept?()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Accept")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.billixMoneyGreen)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Pending Indicator

    private var pendingIndicator: some View {
        VStack(spacing: 8) {
            Divider()

            HStack {
                Image(systemName: "hourglass")
                    .foregroundColor(.billixGoldenAmber)

                Text("Waiting for partner's response...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Helper Properties

    private var statusBorderColor: Color {
        switch deal.status {
        case .proposed, .countered:
            return Color.billixGoldenAmber.opacity(0.3)
        case .accepted:
            return Color.billixMoneyGreen.opacity(0.3)
        case .rejected:
            return Color.red.opacity(0.3)
        case .expired:
            return Color.gray.opacity(0.3)
        }
    }

    // MARK: - Formatters

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }

    private func formatDeadline(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Deal Status Badge

struct DealStatusBadge: View {
    let status: DealStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(foregroundColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(backgroundColor)
        .cornerRadius(8)
    }

    private var foregroundColor: Color {
        switch status {
        case .proposed:
            return .white
        case .countered:
            return .white
        case .accepted:
            return .white
        case .rejected:
            return .white
        case .expired:
            return .white
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .proposed:
            return .billixGoldenAmber
        case .countered:
            return .billixPurple
        case .accepted:
            return .billixMoneyGreen
        case .rejected:
            return .red
        case .expired:
            return .gray
        }
    }
}

// MARK: - Detail Card

private struct DetailCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.billixCreamBeige.opacity(0.3))
        .cornerRadius(10)
    }
}

// MARK: - Compact Deal Card (for lists)

struct CompactDealCard: View {
    let deal: SwapDeal
    let swap: BillSwapTransaction

    private var isUserA: Bool {
        swap.isUserA(userId: SupabaseService.shared.currentUserId ?? UUID())
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Terms v\(deal.version)")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    DealStatusBadge(status: deal.status)
                }

                Text("You: \(formatAmount(isUserA ? deal.amountA : deal.amountB)) \u{2194} Partner: \(formatAmount(isUserA ? deal.amountB : deal.amountA))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch deal.status {
        case .proposed, .countered:
            return .billixGoldenAmber
        case .accepted:
            return .billixMoneyGreen
        case .rejected:
            return .red
        case .expired:
            return .gray
        }
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Deal History List

struct DealHistoryView: View {
    let deals: [SwapDeal]
    let swap: BillSwapTransaction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.billixDarkTeal)

                Text("Terms History")
                    .font(.headline)
                    .foregroundColor(.billixDarkTeal)

                Spacer()

                Text("\(deals.count) version\(deals.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(deals.reversed()) { deal in
                CompactDealCard(deal: deal, swap: swap)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Deal Card - Pending") {
    let userA = UUID()
    let userB = UUID()
    let swap = BillSwapTransaction.mockActiveSwap(userAId: userA, userBId: userB)
    let deal = SwapDeal.mockDeal(swapId: swap.id, proposerId: userB, status: .proposed)

    return DealCardView(
        deal: deal,
        swap: swap,
        onAccept: {},
        onReject: {},
        onCounter: {}
    )
    .padding()
    .background(Color.billixCreamBeige)
}

#Preview("Deal Card - Accepted") {
    let userA = UUID()
    let userB = UUID()
    let swap = BillSwapTransaction.mockActiveSwap(userAId: userA, userBId: userB)
    let deal = SwapDeal.mockDeal(swapId: swap.id, proposerId: userA, status: .accepted)

    return DealCardView(
        deal: deal,
        swap: swap,
        onAccept: nil,
        onReject: nil,
        onCounter: nil
    )
    .padding()
    .background(Color.billixCreamBeige)
}
#endif
