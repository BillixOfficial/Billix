//
//  PaywallView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Paywall view shown when users try to access premium features
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @ObservedObject private var creditsService = UnlockCreditsService.shared

    let context: PaywallContext
    @State private var selectedProduct: Product?
    @State private var showAnnual = false
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Theme colors
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationView {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Feature being unlocked (if applicable)
                        if case .featureGate(let feature) = context {
                            featureHighlight(feature)
                        }

                        // Tier toggle
                        billingToggle

                        // Subscription options
                        subscriptionCards

                        // Or use credits (if applicable)
                        if case .featureGate(let feature) = context,
                           let creditCost = feature.creditCost {
                            creditsOption(feature: feature, cost: creditCost)
                        }

                        // Features comparison
                        featuresComparison

                        // Restore purchases
                        restoreButton

                        // Legal text
                        legalText
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(secondaryText)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(context.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(primaryText)

            if let subtitle = context.subtitle {
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Feature Highlight

    private func featureHighlight(_ feature: PremiumFeature) -> some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 32))
                .foregroundColor(accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(primaryText)

                Text(feature.description)
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)
            }

            Spacer()
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Billing Toggle

    private var billingToggle: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation { showAnnual = false }
            } label: {
                Text("Monthly")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(showAnnual ? secondaryText : primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(showAnnual ? Color.clear : accent.opacity(0.2))
                    .cornerRadius(8)
            }

            Button {
                withAnimation { showAnnual = true }
            } label: {
                HStack(spacing: 4) {
                    Text("Annual")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Save 20%")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accent)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                }
                .foregroundColor(showAnnual ? primaryText : secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(showAnnual ? accent.opacity(0.2) : Color.clear)
                .cornerRadius(8)
            }
        }
        .padding(4)
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Subscription Cards

    private var subscriptionCards: some View {
        VStack(spacing: 12) {
            let products = showAnnual ? subscriptionService.annualProducts : subscriptionService.monthlyProducts

            ForEach(products, id: \.id) { product in
                subscriptionCard(product)
            }
        }
    }

    private func subscriptionCard(_ product: Product) -> some View {
        let productId = SubscriptionProductID(rawValue: product.id)
        let tier = productId?.tier ?? .basic
        let isSelected = selectedProduct?.id == product.id
        let isCurrentTier = subscriptionService.currentTier == tier

        return Button {
            selectedProduct = product
        } label: {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: tier.icon)
                                .foregroundColor(tier.color)
                            Text(tier.displayName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(primaryText)

                            if isCurrentTier {
                                Text("Current")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(accent)
                                    .foregroundColor(.black)
                                    .cornerRadius(4)
                            }
                        }

                        Text(tier.tagline)
                            .font(.system(size: 13))
                            .foregroundColor(secondaryText)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(primaryText)

                        Text(showAnnual ? "/year" : "/month")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)
                    }
                }

                // Features for this tier
                let newFeatures = tier.features.filter { !BillixSubscriptionTier.free.features.contains($0) }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(newFeatures.prefix(4), id: \.self) { feature in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(accent)
                            Text(feature.displayName)
                                .font(.system(size: 11))
                                .foregroundColor(secondaryText)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                }
            }
            .padding()
            .background(isSelected ? accent.opacity(0.1) : cardBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isCurrentTier)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task {
                await purchaseSubscription()
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text(selectedProduct != nil ? "Subscribe" : "Select a Plan")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(selectedProduct != nil ? accent : accent.opacity(0.5))
            .cornerRadius(12)
        }
        .disabled(selectedProduct == nil || isPurchasing)
    }

    // MARK: - Credits Option

    private func creditsOption(feature: PremiumFeature, cost: Int) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Or unlock with credits")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(secondaryText)

                Spacer()

                Text("\(creditsService.balance) available")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)
            }

            Button {
                Task {
                    await unlockWithCredits(feature: feature, cost: cost)
                }
            } label: {
                HStack {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.yellow)
                    Text("Use \(cost) Credits")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(creditsService.canAfford(cost) ? primaryText : secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(cardBg)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(!creditsService.canAfford(cost))
        }
        .padding()
        .background(cardBg.opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Features Comparison

    private var featuresComparison: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Compare Plans")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(primaryText)

            ForEach(PremiumFeature.allCases, id: \.self) { feature in
                HStack {
                    Image(systemName: feature.icon)
                        .font(.system(size: 14))
                        .foregroundColor(secondaryText)
                        .frame(width: 24)

                    Text(feature.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(primaryText)

                    Spacer()

                    // Show which tier includes this
                    Text(feature.requiredTier.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(feature.requiredTier.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(feature.requiredTier.color.opacity(0.15))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task {
                await subscriptionService.restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(.system(size: 14))
                .foregroundColor(accent)
        }
    }

    // MARK: - Legal Text

    private var legalText: some View {
        VStack(spacing: 8) {
            Text("Billix is a coordination platform. We do not transfer money, hold funds, or guarantee payments. All bill payments are made directly between users and providers.")
                .font(.system(size: 11))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)

            Text("Subscriptions auto-renew unless cancelled. Cancel anytime in Settings.")
                .font(.system(size: 10))
                .foregroundColor(secondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Actions

    private func purchaseSubscription() async {
        guard let product = selectedProduct,
              let productId = SubscriptionProductID(rawValue: product.id) else {
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await subscriptionService.purchase(productId)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func unlockWithCredits(feature: PremiumFeature, cost: Int) async {
        do {
            try await subscriptionService.unlockFeature(feature, using: creditsService)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView(context: .featureGate(.fractionalSwaps))
        .preferredColorScheme(.dark)
    }
}
