//
//  SwapCard.swift
//  Billix
//
//  Redesigned swap card with timeline indicator and refined styling
//

import SwiftUI

struct SwapCard: View {
    let swap: BillSwap
    let currentUserId: UUID
    var onTap: (() -> Void)? = nil

    @State private var isPressed = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Category accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(categoryColor)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 10) {
                    // Top row: Partner + Status
                    HStack {
                        // Partner info
                        HStack(spacing: 8) {
                            // Avatar placeholder
                            ZStack {
                                Circle()
                                    .fill(BillSwapTheme.accentLight)
                                    .frame(width: 36, height: 36)

                                Text(partnerInitial)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(BillSwapTheme.accent)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(partnerName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(BillSwapTheme.primaryText)

                                Text(swapTypeLabel)
                                    .font(.system(size: 11))
                                    .foregroundColor(BillSwapTheme.secondaryText)
                            }
                        }

                        Spacer()

                        // Status badge
                        SwapStatusBadge(status: swap.status.displayName)
                    }

                    // Divider
                    Rectangle()
                        .fill(BillSwapTheme.secondaryText.opacity(0.1))
                        .frame(height: 1)

                    // Middle row: Bills info
                    HStack(spacing: 16) {
                        // Your bill
                        if let billA = swap.billA {
                            billInfoColumn(
                                label: isInitiator ? "Your Bill" : "Their Bill",
                                category: billA.category.displayName,
                                amount: billA.formattedAmount
                            )
                        }

                        // Swap icon
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(BillSwapTheme.secondaryText)

                        // Their bill
                        if let billB = swap.billB {
                            billInfoColumn(
                                label: isInitiator ? "Their Bill" : "Your Bill",
                                category: billB.category.displayName,
                                amount: billB.formattedAmount
                            )
                        } else {
                            billInfoColumn(
                                label: "Waiting",
                                category: "No bill yet",
                                amount: "--"
                            )
                        }
                    }

                    // Bottom row: Timeline + Due date
                    HStack {
                        // Mini timeline
                        MiniSwapTimeline(currentStep: progressStep)

                        Spacer()

                        // Time remaining or due date
                        if let timeInfo = timeInfo {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(timeInfo)
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(timeColor)
                        }
                    }
                }
            }
            .padding(14)
            .background(BillSwapTheme.cardBackground)
            .cornerRadius(BillSwapTheme.cardCornerRadius)
            .shadow(
                color: BillSwapTheme.cardShadow,
                radius: BillSwapTheme.cardShadowRadius,
                x: 0,
                y: BillSwapTheme.cardShadowY
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func billInfoColumn(label: String, category: String, amount: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(BillSwapTheme.mutedText)
                .textCase(.uppercase)

            Text(category)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(BillSwapTheme.primaryText)
                .lineLimit(1)

            Text(amount)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(BillSwapTheme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Computed Properties

    private var isInitiator: Bool {
        swap.initiatorUserId == currentUserId
    }

    private var partnerName: String {
        // TrustProfile only has trust-related data, not display info
        // For now, show a placeholder - the actual display name would be fetched separately
        if isInitiator {
            if swap.counterpartyUserId != nil {
                return "Partner"
            }
            return "Waiting..."
        } else {
            return "Partner"
        }
    }

    private var partnerInitial: String {
        String(partnerName.prefix(1)).uppercased()
    }

    private var swapTypeLabel: String {
        swap.swapType.displayName
    }

    private var categoryColor: Color {
        if let billA = swap.billA {
            return BillSwapTheme.categoryColor(for: billA.category.rawValue)
        }
        return BillSwapTheme.accent
    }

    private var progressStep: SwapProgressStep {
        SwapProgressStep.from(status: swap.status.rawValue)
    }

    private var timeInfo: String? {
        switch swap.status {
        case .offered, .countered:
            if let deadline = swap.acceptDeadline {
                return formatTimeRemaining(deadline)
            }
        case .awaitingProof:
            if let deadline = swap.proofDueDeadline {
                return formatTimeRemaining(deadline)
            }
        case .completed:
            if let completedAt = swap.completedAt {
                return formatRelativeDate(completedAt)
            }
        default:
            break
        }
        return nil
    }

    private var timeColor: Color {
        if let deadline = swap.acceptDeadline ?? swap.proofDueDeadline {
            let hours = Calendar.current.dateComponents([.hour], from: Date(), to: deadline).hour ?? 0
            if hours < 6 {
                return BillSwapTheme.statusDispute
            } else if hours < 24 {
                return BillSwapTheme.statusPending
            }
        }
        return BillSwapTheme.secondaryText
    }

    private func formatTimeRemaining(_ deadline: Date) -> String {
        let now = Date()
        let interval = deadline.timeIntervalSince(now)

        if interval <= 0 {
            return "Expired"
        }

        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 24 {
            let days = hours / 24
            return "\(days)d left"
        } else if hours > 0 {
            return "\(hours)h left"
        } else {
            return "\(minutes)m left"
        }
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SwapCard(
            swap: BillSwap(
                id: UUID(),
                swapType: .twoSided,
                status: .locked,
                initiatorUserId: UUID(),
                counterpartyUserId: UUID(),
                billAId: UUID(),
                billBId: UUID(),
                counterOfferAmountCents: nil,
                counterOfferByUserId: nil,
                feeAmountCentsInitiator: 99,
                feeAmountCentsCounterparty: 99,
                spreadFeeCents: 0,
                feePaidInitiator: true,
                feePaidCounterparty: true,
                pointsWaiverInitiator: false,
                pointsWaiverCounterparty: false,
                acceptDeadline: Date().addingTimeInterval(3600 * 12),
                proofDueDeadline: nil,
                createdAt: Date(),
                updatedAt: Date(),
                acceptedAt: nil,
                lockedAt: nil,
                completedAt: nil,
                billA: SwapBill(
                    id: UUID(),
                    ownerUserId: UUID(),
                    title: "Electric Bill",
                    category: .electric,
                    providerName: "ConEd",
                    amountCents: 8500,
                    dueDate: Date().addingTimeInterval(86400 * 5),
                    status: .lockedInSwap,
                    paymentUrl: nil,
                    accountNumberLast4: nil,
                    billImageUrl: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                billB: SwapBill(
                    id: UUID(),
                    ownerUserId: UUID(),
                    title: "Water Bill",
                    category: .water,
                    providerName: "City Water",
                    amountCents: 7200,
                    dueDate: Date().addingTimeInterval(86400 * 7),
                    status: .lockedInSwap,
                    paymentUrl: nil,
                    accountNumberLast4: nil,
                    billImageUrl: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                initiatorProfile: nil,
                counterpartyProfile: nil
            ),
            currentUserId: UUID()
        )
    }
    .padding()
    .background(BillSwapTheme.background)
}
