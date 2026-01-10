//
//  MatchCardView.swift
//  Billix
//
//  Match Card Component for Swap Match Proposals
//

import SwiftUI

struct MatchCardView: View {
    let match: SwapMatch
    let onAccept: () -> Void
    let onDismiss: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with match score
            HStack {
                // Match quality badge
                HStack(spacing: 6) {
                    Image(systemName: match.matchQuality.icon)
                        .font(.system(size: 14, weight: .semibold))
                    Text(match.matchQuality.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: match.matchQuality.color))
                .cornerRadius(12)

                Spacer()

                // Match score
                Text(match.formattedMatchScore)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: match.matchQuality.color))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Bills comparison
            HStack(spacing: 12) {
                // Your bill (left)
                BillMiniCard(
                    title: "Your Bill",
                    billerName: match.yourBill.title,
                    amount: match.yourBill.formattedAmount,
                    category: match.yourBill.category,
                    isYours: true
                )

                // Swap icon
                VStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.billixDarkTeal)
                    Text(match.formattedAmountDifference)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(width: 60)

                // Their bill (right)
                BillMiniCard(
                    title: "Their Bill",
                    billerName: match.theirBill.title,
                    amount: match.theirBill.formattedAmount,
                    category: match.theirBill.category,
                    isYours: false
                )
            }
            .padding(16)

            // Partner info
            HStack {
                // Trust tier badge
                HStack(spacing: 4) {
                    Image(systemName: match.partnerProfile.tier.icon)
                        .font(.system(size: 12))
                    Text(match.partnerProfile.tier.displayName)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(hex: match.partnerProfile.tier.color))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: match.partnerProfile.tier.color).opacity(0.15))
                .cornerRadius(8)

                if match.partnerProfile.completedSwapsCount > 0 {
                    Text("\(match.partnerProfile.completedSwapsCount) swaps")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                if match.partnerProfile.successRate >= 90 {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                        Text("\(Int(match.partnerProfile.successRate))%")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.billixMoneyGreen)
                }

                Spacer()
            }
            .padding(.horizontal, 16)

            // Match reasons (expandable)
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why this match?")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    ForEach(match.matchReasons, id: \.self) { reason in
                        HStack(spacing: 8) {
                            Image(systemName: reason.icon)
                                .font(.system(size: 12))
                                .foregroundColor(.billixDarkTeal)
                            Text(reason.displayText)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.05))
            }

            // Fees section
            if isExpanded {
                VStack(spacing: 4) {
                    HStack {
                        Text("Facilitation Fee")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(match.estimatedFees.formattedFacilitationFee)
                            .font(.system(size: 12, weight: .medium))
                    }
                    if match.estimatedFees.spreadFee > 0 {
                        HStack {
                            Text("Spread Fee (3%)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(match.estimatedFees.formattedSpreadFee)
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    Divider()
                    HStack {
                        Text("Your Total Fee")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(match.estimatedFees.formattedYourTotal)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.billixDarkTeal)
                    }
                }
                .padding(16)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation { isExpanded.toggle() }
                }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Less" : "Details")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onDismiss) {
                    Text("Skip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                Button(action: onAccept) {
                    Text("Accept Match")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.billixMoneyGreen)
                        .cornerRadius(8)
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Bill Mini Card

struct BillMiniCard: View {
    let title: String
    let billerName: String
    let amount: String
    let category: SwapBillCategory
    let isYours: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(category.color)
                Text(billerName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }

            Text(amount)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(isYours ? .billixDarkTeal : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(isYours ? Color.billixDarkTeal.opacity(0.08) : Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        MatchCardView(
            match: SwapMatch(
                yourBill: SwapBill(
                    id: UUID(),
                    ownerUserId: UUID(),
                    title: "Duke Energy",
                    category: .electric,
                    providerName: "Duke Energy",
                    amountCents: 8500,
                    dueDate: Date().addingTimeInterval(86400 * 5),
                    status: .active,
                    paymentUrl: nil,
                    accountNumberLast4: "4521",
                    billImageUrl: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                theirBill: SwapBill(
                    id: UUID(),
                    ownerUserId: UUID(),
                    title: "Comcast Internet",
                    category: .internet,
                    providerName: "Comcast",
                    amountCents: 8999,
                    dueDate: Date().addingTimeInterval(86400 * 3),
                    status: .active,
                    paymentUrl: nil,
                    accountNumberLast4: "7823",
                    billImageUrl: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                partnerProfile: TrustProfile.defaultProfile(userId: UUID()),
                matchScore: 85,
                matchReasons: [.similarAmount, .complementaryDueDate, .reliablePartner],
                estimatedFees: MatchFees(spreadFee: 15)
            ),
            onAccept: {},
            onDismiss: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
