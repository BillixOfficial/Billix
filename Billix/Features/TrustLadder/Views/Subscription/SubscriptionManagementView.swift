//
//  SubscriptionManagementView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Settings view for managing subscription and viewing credits
//

import SwiftUI
import StoreKit

struct SubscriptionManagementView: View {
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @ObservedObject private var creditsService = UnlockCreditsService.shared

    @State private var showPaywall = false
    @State private var showCancelConfirmation = false
    @State private var showCreditHistory = false
    @State private var isRestoring = false

    // Theme colors
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current Plan Card
                currentPlanCard

                // Credits Balance Card
                creditsCard

                // Quick Actions
                quickActionsSection

                // Feature Unlocks
                if !subscriptionService.featureUnlocks.isEmpty {
                    featureUnlocksSection
                }

                // Plan Comparison
                planComparisonSection

                // Account Actions
                accountActionsSection

                // Legal
                legalSection
            }
            .padding()
        }
        .background(background.ignoresSafeArea())
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: .tierUpgrade)
        }
        .sheet(isPresented: $showCreditHistory) {
            CreditHistoryView()
        }
        .alert("Cancel Subscription", isPresented: $showCancelConfirmation) {
            Button("Keep Subscription", role: .cancel) {}
            Button("Cancel", role: .destructive) {
                openSubscriptionManagement()
            }
        } message: {
            Text("You'll need to cancel through the App Store. We'll open your subscription settings.")
        }
    }

    // MARK: - Current Plan Card

    private var currentPlanCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Plan")
                        .font(.system(size: 13))
                        .foregroundColor(secondaryText)

                    HStack(spacing: 8) {
                        Image(systemName: subscriptionService.currentTier.icon)
                            .foregroundColor(subscriptionService.currentTier.color)

                        Text(subscriptionService.currentTier.displayName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(primaryText)
                    }
                }

                Spacer()

                // Tier badge
                Text(subscriptionService.currentTier.formattedPrice)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(subscriptionService.currentTier.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(subscriptionService.currentTier.color.opacity(0.15))
                    .cornerRadius(8)
            }

            // Subscription status
            if let subscription = subscriptionService.subscription {
                Divider().background(secondaryText.opacity(0.3))

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            Text("Status: \(subscription.status.displayName)")
                                .font(.system(size: 13))
                                .foregroundColor(primaryText)
                        } icon: {
                            Circle()
                                .fill(subscription.status.color)
                                .frame(width: 8, height: 8)
                        }

                        if let daysLeft = subscription.daysUntilExpiration {
                            Text(daysLeft > 0 ? "Renews in \(daysLeft) days" : "Expires today")
                                .font(.system(size: 12))
                                .foregroundColor(secondaryText)
                        }
                    }

                    Spacer()

                    if subscription.status == .active {
                        Button("Manage") {
                            openSubscriptionManagement()
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accent)
                    }
                }
            }

            // Upgrade button (if not premium)
            if subscriptionService.currentTier != .premium {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                        Text(subscriptionService.currentTier == .free ? "Get Started" : "Upgrade Plan")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(accent)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: - Credits Card

    private var creditsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlock Credits")
                        .font(.system(size: 13))
                        .foregroundColor(secondaryText)

                    HStack(spacing: 6) {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.yellow)

                        Text("\(creditsService.balance)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(primaryText)

                        Text("credits")
                            .font(.system(size: 16))
                            .foregroundColor(secondaryText)
                    }
                }

                Spacer()

                Button {
                    showCreditHistory = true
                } label: {
                    Text("History")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accent)
                }
            }

            // Lifetime stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Earned")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                    Text("+\(creditsService.lifetimeEarned)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Spent")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                    Text("-\(creditsService.lifetimeSpent)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }

                Spacer()
            }

            // How to earn
            Divider().background(secondaryText.opacity(0.3))

            VStack(alignment: .leading, spacing: 8) {
                Text("Earn Credits")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(secondaryText)

                earnCreditRow(icon: "doc.text.image", text: "Upload bill receipt", credits: UnlockCreditsService.receiptUploadCredits)
                earnCreditRow(icon: "arrow.left.arrow.right", text: "Complete a swap", credits: UnlockCreditsService.swapCompletionCredits)
                earnCreditRow(icon: "person.badge.plus", text: "Refer a friend", credits: UnlockCreditsService.referralCredits)
                earnCreditRow(icon: "calendar", text: "Daily login", credits: UnlockCreditsService.dailyLoginCredits)
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func earnCreditRow(icon: String, text: String, credits: Int) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(secondaryText)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(primaryText)

            Spacer()

            Text("+\(credits)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.yellow)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(secondaryText)

            HStack(spacing: 12) {
                quickActionButton(icon: "doc.text.image", title: "Upload Receipt", color: .blue) {
                    // Navigate to receipt upload
                }

                quickActionButton(icon: "gift", title: "Refer Friends", color: .purple) {
                    // Navigate to referral
                }

                quickActionButton(icon: "chart.line.uptrend.xyaxis", title: "Live Feed", color: .green) {
                    // Navigate to marketplace feed
                }
            }
        }
    }

    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(cardBg)
            .cornerRadius(12)
        }
    }

    // MARK: - Feature Unlocks

    private var featureUnlocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unlocked Features")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(secondaryText)

            VStack(spacing: 8) {
                ForEach(Array(subscriptionService.featureUnlocks.values), id: \.id) { unlock in
                    if let feature = unlock.feature {
                        HStack {
                            Image(systemName: feature.icon)
                                .font(.system(size: 14))
                                .foregroundColor(accent)

                            Text(feature.displayName)
                                .font(.system(size: 14))
                                .foregroundColor(primaryText)

                            Spacer()

                            if let expires = unlock.expiresAt {
                                Text("Expires \(expires, style: .relative)")
                                    .font(.system(size: 11))
                                    .foregroundColor(secondaryText)
                            } else {
                                Text("Permanent")
                                    .font(.system(size: 11))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(cardBg)
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    // MARK: - Plan Comparison

    private var planComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compare Plans")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(secondaryText)

            VStack(spacing: 8) {
                ForEach(BillixSubscriptionTier.allCases) { tier in
                    planRow(tier)
                }
            }
        }
    }

    private func planRow(_ tier: BillixSubscriptionTier) -> some View {
        let isCurrent = tier == subscriptionService.currentTier

        return HStack {
            Image(systemName: tier.icon)
                .font(.system(size: 16))
                .foregroundColor(tier.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(tier.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)

                Text(tier.tagline)
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }

            Spacer()

            if isCurrent {
                Text("Current")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accent)
                    .cornerRadius(6)
            } else {
                Text(tier.formattedPrice)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryText)
            }
        }
        .padding()
        .background(isCurrent ? accent.opacity(0.1) : cardBg)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isCurrent ? accent : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Account Actions

    private var accountActionsSection: some View {
        VStack(spacing: 8) {
            // Restore purchases
            Button {
                Task {
                    isRestoring = true
                    await subscriptionService.restorePurchases()
                    isRestoring = false
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(isRestoring ? "Restoring..." : "Restore Purchases")
                    Spacer()
                    if isRestoring {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: primaryText))
                            .scaleEffect(0.8)
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(primaryText)
                .padding()
                .background(cardBg)
                .cornerRadius(10)
            }
            .disabled(isRestoring)

            // Cancel subscription (if active)
            if subscriptionService.subscription?.isActive == true {
                Button {
                    showCancelConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Cancel Subscription")
                        Spacer()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding()
                    .background(cardBg)
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("Billix is a coordination platform. We do not transfer money, hold funds, or guarantee payments. All bill payments are made directly between users and providers.")
                .font(.system(size: 11))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Terms of Service") {
                    // Open terms
                }
                .font(.system(size: 11))
                .foregroundColor(accent)

                Button("Privacy Policy") {
                    // Open privacy
                }
                .font(.system(size: 11))
                .foregroundColor(accent)
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Simple Credit History Sheet
// Note: The full CreditHistoryView is in Features/TrustLadder/Views/Engagement/CreditHistoryView.swift

struct SimpleCreditHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var creditsService = UnlockCreditsService.shared

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationView {
            ZStack {
                background.ignoresSafeArea()

                if creditsService.recentTransactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 48))
                            .foregroundColor(secondaryText)

                        Text("No transactions yet")
                            .font(.system(size: 16))
                            .foregroundColor(secondaryText)

                        Text("Earn credits by uploading receipts, completing swaps, and more!")
                            .font(.system(size: 13))
                            .foregroundColor(secondaryText.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(creditsService.recentTransactions) { transaction in
                            transactionRow(transaction)
                                .listRowBackground(cardBg)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Credit History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    private func transactionRow(_ transaction: UnlockCreditTransaction) -> some View {
        HStack {
            // Icon based on type
            Image(systemName: transactionIcon(for: transaction.type))
                .font(.system(size: 16))
                .foregroundColor(transaction.isPositive ? .green : .orange)
                .frame(width: 32, height: 32)
                .background(transaction.isPositive ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description ?? transaction.type?.displayName ?? "Transaction")
                    .font(.system(size: 14))
                    .foregroundColor(primaryText)

                Text(transaction.createdAt, style: .relative)
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(transaction.isPositive ? .green : .orange)
        }
        .padding(.vertical, 4)
    }

    private func transactionIcon(for type: UnlockCreditType?) -> String {
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

// MARK: - Preview

#Preview {
    NavigationView {
        SubscriptionManagementView()
    }
    .preferredColorScheme(.dark)
}
