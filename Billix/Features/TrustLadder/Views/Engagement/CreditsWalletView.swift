//
//  CreditsWalletView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  View for managing unlock credits - viewing balance, history, and spending options
//

import SwiftUI

struct CreditsWalletView: View {
    @ObservedObject private var creditsService = UnlockCreditsService.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared

    @State private var showReceiptUpload = false
    @State private var showHistory = false

    // Theme colors
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Balance card
                balanceCard

                // Quick actions
                quickActionsSection

                // Earn credits section
                earnCreditsSection

                // Spend credits section
                spendCreditsSection

                // Recent transactions
                recentTransactionsSection
            }
            .padding()
        }
        .background(background.ignoresSafeArea())
        .navigationTitle("Credits")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showReceiptUpload) {
            BillReceiptUploadView()
        }
        .sheet(isPresented: $showHistory) {
            CreditHistoryView()
        }
        .refreshable {
            await creditsService.loadCredits()
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 16) {
            // Main balance
            VStack(spacing: 4) {
                Text("Available Credits")
                    .font(.system(size: 13))
                    .foregroundColor(secondaryText)

                HStack(alignment: .bottom, spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.yellow)

                    Text("\(creditsService.balance)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }

            // Lifetime stats
            HStack(spacing: 24) {
                statColumn(
                    value: "+\(creditsService.lifetimeEarned)",
                    label: "Earned",
                    color: .green
                )

                Divider()
                    .frame(height: 30)
                    .background(secondaryText.opacity(0.3))

                statColumn(
                    value: "-\(creditsService.lifetimeSpent)",
                    label: "Spent",
                    color: .orange
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.yellow.opacity(0.3), .orange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private func statColumn(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(secondaryText)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            quickActionButton(
                icon: "doc.text.image",
                title: "Upload Receipt",
                color: .purple
            ) {
                showReceiptUpload = true
            }

            quickActionButton(
                icon: "clock.arrow.circlepath",
                title: "History",
                color: .blue
            ) {
                showHistory = true
            }

            quickActionButton(
                icon: "person.badge.plus",
                title: "Refer Friend",
                color: .green
            ) {
                // Show referral
            }
        }
    }

    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 75)
            .background(cardBg)
            .cornerRadius(12)
        }
    }

    // MARK: - Earn Credits Section

    private var earnCreditsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earn Credits")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            VStack(spacing: 8) {
                earnOptionRow(
                    icon: "doc.text.image",
                    title: "Upload Bill Receipt",
                    subtitle: "Upload proof of a paid bill",
                    credits: UnlockCreditsService.receiptUploadCredits,
                    color: .purple
                ) {
                    showReceiptUpload = true
                }

                earnOptionRow(
                    icon: "arrow.left.arrow.right",
                    title: "Complete a Swap",
                    subtitle: "Successfully finish a bill swap",
                    credits: UnlockCreditsService.swapCompletionCredits,
                    color: .blue
                ) {
                    // Navigate to swaps
                }

                earnOptionRow(
                    icon: "person.badge.plus",
                    title: "Refer a Friend",
                    subtitle: "Invite someone new to Billix",
                    credits: UnlockCreditsService.referralCredits,
                    color: .green
                ) {
                    // Show referral
                }

                earnOptionRow(
                    icon: "calendar.badge.clock",
                    title: "Daily Login",
                    subtitle: "Open the app each day",
                    credits: UnlockCreditsService.dailyLoginCredits,
                    color: .orange
                ) {
                    // Info only
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func earnOptionRow(
        icon: String,
        title: String,
        subtitle: String,
        credits: Int,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(primaryText)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("+\(credits)")
                        .font(.system(size: 14, weight: .bold))
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 12))
                }
                .foregroundColor(.yellow)
            }
            .padding()
            .background(background)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Spend Credits Section

    private var spendCreditsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spend Credits")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            VStack(spacing: 8) {
                ForEach(PremiumFeature.allCases.filter { $0.creditCost != nil }) { feature in
                    spendOptionRow(feature: feature)
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func spendOptionRow(feature: PremiumFeature) -> some View {
        let isUnlocked = subscriptionService.hasAccess(to: feature)
        let canAfford = creditsService.canAfford(feature.creditCost ?? 0)

        return HStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(.system(size: 16))
                .foregroundColor(isUnlocked ? .green : feature.requiredTier.color)
                .frame(width: 32, height: 32)
                .background((isUnlocked ? Color.green : feature.requiredTier.color).opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(feature.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(primaryText)

                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }

                Text(feature.description)
                    .font(.system(size: 10))
                    .foregroundColor(secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            if isUnlocked {
                Text("Unlocked")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green)
            } else if let cost = feature.creditCost {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 3) {
                        Text("\(cost)")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(canAfford ? .yellow : secondaryText)

                    if !canAfford {
                        Text("Need \(cost - creditsService.balance) more")
                            .font(.system(size: 9))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
        }
        .padding()
        .background(background)
        .cornerRadius(10)
        .opacity(isUnlocked ? 0.7 : 1)
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)

                Spacer()

                Button {
                    showHistory = true
                } label: {
                    Text("See All")
                        .font(.system(size: 12))
                        .foregroundColor(accent)
                }
            }

            if creditsService.recentTransactions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 24))
                            .foregroundColor(secondaryText)
                        Text("No transactions yet")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(creditsService.recentTransactions.prefix(5)) { transaction in
                        transactionRow(transaction)
                    }
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func transactionRow(_ transaction: UnlockCreditTransaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: transactionIcon(transaction.type))
                .font(.system(size: 14))
                .foregroundColor(transaction.isPositive ? .green : .orange)
                .frame(width: 28, height: 28)
                .background((transaction.isPositive ? Color.green : Color.orange).opacity(0.15))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description ?? transaction.type?.displayName ?? "Transaction")
                    .font(.system(size: 12))
                    .foregroundColor(primaryText)

                Text(transaction.createdAt, style: .relative)
                    .font(.system(size: 10))
                    .foregroundColor(secondaryText)
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(transaction.isPositive ? .green : .orange)
        }
    }

    private func transactionIcon(_ type: UnlockCreditType?) -> String {
        switch type {
        case .receiptUpload: return "doc.text.image"
        case .referral: return "person.badge.plus"
        case .dailyLogin: return "calendar"
        case .swapCompletion: return "arrow.left.arrow.right"
        case .featureUnlock: return "lock.open"
        case .promotion: return "gift"
        case .refund: return "arrow.uturn.backward"
        case .none: return "star.circle"
        }
    }
}

// MARK: - Compact Credits Widget

/// A compact credits display for embedding in other views
struct CompactCreditsWidget: View {
    @StateObject private var creditsService = UnlockCreditsService.shared

    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationLink {
            CreditsWalletView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Credits")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)

                    Text("\(creditsService.balance)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(primaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)
            }
            .padding()
            .background(cardBg)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Credits Badge

/// A small badge showing credit balance
struct CreditsBadge: View {
    @StateObject private var creditsService = UnlockCreditsService.shared

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.yellow)

            Text("\(creditsService.balance)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct CreditsWalletView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
        CreditsWalletView()
        }
        .preferredColorScheme(.dark)
    }
}
