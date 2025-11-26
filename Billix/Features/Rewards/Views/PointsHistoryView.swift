//
//  PointsHistoryView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Transaction history for rewards points
//

import SwiftUI

struct PointsHistoryView: View {
    let transactions: [PointTransaction]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.billixLightGreen
                    .ignoresSafeArea()

                if transactions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(transactions) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Points History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.billixMoneyGreen)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.billixMediumGreen)

            Text("No transactions yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            Text("Play games and earn points to see your history here")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.billixMediumGreen)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: PointTransaction

    private var isEarning: Bool {
        transaction.amount >= 0
    }

    private var typeIcon: String {
        switch transaction.type {
        case .gameWin: return "gamecontroller.fill"
        case .dailyBonus: return "gift.fill"
        case .redemption: return "bag.fill"
        case .referral: return "person.2.fill"
        case .achievement: return "trophy.fill"
        }
    }

    private var typeColor: Color {
        switch transaction.type {
        case .gameWin: return .billixGamePurple
        case .dailyBonus: return .billixArcadeGold
        case .redemption: return .billixChartBlue
        case .referral: return .billixMoneyGreen
        case .achievement: return .billixPrizeOrange
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: typeIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(typeColor)
            }

            // Description
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(transaction.type.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Text("•")
                        .foregroundColor(.billixMediumGreen)

                    Text(transaction.formattedDate)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                }
            }

            Spacer()

            // Amount
            Text(transaction.amountString)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(isEarning ? .billixMoneyGreen : .billixMediumGreen)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Preview

#Preview {
    PointsHistoryView(transactions: RewardsPoints.preview.transactions)
}

#Preview("Empty") {
    PointsHistoryView(transactions: [])
}
