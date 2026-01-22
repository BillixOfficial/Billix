//
//  BillixStoreView.swift
//  Billix
//
//  Unified store view for subscriptions, credits, and purchases
//

import SwiftUI
import StoreKit

struct BillixStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeKit = StoreKitService.shared
    @StateObject private var credits = UnlockCreditsService.shared

    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedPlan: PlanType = .yearly

    enum PlanType {
        case monthly, yearly
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with status
                    headerSection

                    // Billix Prime Subscription
                    subscriptionSection

                    // Credits & Tokens
                    creditsSection

                    // One-time purchases
                    purchasesSection

                    // Restore purchases
                    restoreSection

                    // Legal
                    legalSection

                    Spacer().frame(height: 40)
                }
                .padding(20)
            }
            .background(Color(hex: "#F7F9F8").ignoresSafeArea())
            .navigationTitle("Billix Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "#8B9A94"))
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

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Store icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.billixGoldenAmber, Color.billixGold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "cart.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            // Status badge
            if storeKit.isPrime {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                    Text("Billix Prime Active")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color.billixGoldenAmber, Color.billixGold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
            }

            // Credits balance
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.billixGoldenAmber)

                Text("\(credits.balance) Credits")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.billixGoldenAmber)

                Text("Billix Prime")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Spacer()

                if storeKit.isPrime {
                    Text("Active")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#5B8A6B"))
                        .cornerRadius(10)
                }
            }

            // Plan options
            if !storeKit.isPrime {
                VStack(spacing: 12) {
                    // Yearly plan
                    planCard(
                        title: "Yearly",
                        price: storeKit.yearlyProduct?.displayPrice ?? "$39.99",
                        period: "/year",
                        savings: "Save 33%",
                        isSelected: selectedPlan == .yearly
                    ) {
                        selectedPlan = .yearly
                    }

                    // Monthly plan
                    planCard(
                        title: "Monthly",
                        price: storeKit.monthlyProduct?.displayPrice ?? "$4.99",
                        period: "/month",
                        savings: nil,
                        isSelected: selectedPlan == .monthly
                    ) {
                        selectedPlan = .monthly
                    }
                }

                // Features list
                VStack(alignment: .leading, spacing: 10) {
                    featureRow(icon: "checkmark.circle.fill", text: "Unlimited bill comparisons")
                    featureRow(icon: "checkmark.circle.fill", text: "Priority swap matching")
                    featureRow(icon: "checkmark.circle.fill", text: "Advanced analytics")
                    featureRow(icon: "checkmark.circle.fill", text: "No ads")
                    featureRow(icon: "checkmark.circle.fill", text: "Premium support")
                }
                .padding(.top, 8)

                // Subscribe button
                Button {
                    Task { await purchaseSubscription() }
                } label: {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Subscribe Now")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.billixGoldenAmber, Color.billixGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .disabled(isPurchasing)
            } else {
                // Already subscribed message
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#5B8A6B"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're a Prime member!")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                        Text("Enjoy all premium features")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#8B9A94"))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#5B8A6B").opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    private func planCard(title: String, price: String, period: String, savings: String?, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        if let savings = savings {
                            Text(savings)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "#5B8A6B"))
                                .cornerRadius(6)
                        }
                    }

                    HStack(spacing: 2) {
                        Text(price)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                        Text(period)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#8B9A94"))
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.billixGoldenAmber : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.billixGoldenAmber)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Color.billixGoldenAmber.opacity(0.08) : Color(hex: "#F7F9F8"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.billixGoldenAmber : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#5B8A6B"))

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#5D6D66"))
        }
    }

    // MARK: - Credits Section

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.billixGoldenAmber)

                Text("Credits & Tokens")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))
            }

            // Token pack
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.billixGoldenAmber.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color.billixGoldenAmber)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("3 Connect Tokens")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Text("Use for swap connections")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                Button {
                    Task { await purchaseTokenPack() }
                } label: {
                    Text(storeKit.tokenPackPrice)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.billixGoldenAmber)
                        .cornerRadius(10)
                }
                .disabled(isPurchasing)
            }
            .padding(14)
            .background(Color(hex: "#F7F9F8"))
            .cornerRadius(14)

            // Earn credits info
            VStack(alignment: .leading, spacing: 10) {
                Text("Earn Free Credits")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                earnRow(icon: "doc.text.viewfinder", text: "Upload receipts", credits: "+10")
                earnRow(icon: "arrow.left.arrow.right", text: "Complete swaps", credits: "+25")
                earnRow(icon: "person.badge.plus", text: "Refer friends", credits: "+100")
            }
            .padding(14)
            .background(Color(hex: "#5B8A6B").opacity(0.08))
            .cornerRadius(14)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    private func earnRow(icon: String, text: String, credits: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#5B8A6B"))
                .frame(width: 20)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#5D6D66"))

            Spacer()

            Text(credits)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#5B8A6B"))
        }
    }

    // MARK: - Purchases Section

    private var purchasesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "bag.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#8B9A94"))

                Text("One-Time Purchases")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))
            }

            // Handshake fee
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#5B8A6B").opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color(hex: "#5B8A6B"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Swap Handshake Fee")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Text("Finalize swap agreements")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                Button {
                    Task { await purchaseHandshakeFee() }
                } label: {
                    Text(storeKit.handshakeFeePrice)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#5B8A6B"))
                        .cornerRadius(10)
                }
                .disabled(isPurchasing)
            }
            .padding(14)
            .background(Color(hex: "#F7F9F8"))
            .cornerRadius(14)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Restore Section

    private var restoreSection: some View {
        Button {
            Task { await restorePurchases() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                Text("Restore Purchases")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(Color(hex: "#5D6D66"))
        }
        .disabled(isPurchasing)
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Manage your subscription in Settings.")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#8B9A94"))
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Terms of Service") {
                    // Open terms
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#5B8A6B"))

                Button("Privacy Policy") {
                    // Open privacy
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#5B8A6B"))
            }
        }
    }

    // MARK: - Actions

    private func purchaseSubscription() async {
        let product = selectedPlan == .yearly ? storeKit.yearlyProduct : storeKit.monthlyProduct
        guard let product = product else {
            errorMessage = "Product not available"
            showError = true
            return
        }

        isPurchasing = true
        do {
            _ = try await storeKit.purchase(product)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }

    private func purchaseTokenPack() async {
        isPurchasing = true
        do {
            _ = try await storeKit.purchaseTokenPack()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }

    private func purchaseHandshakeFee() async {
        isPurchasing = true
        do {
            _ = try await storeKit.purchaseHandshakeFee()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }

    private func restorePurchases() async {
        isPurchasing = true
        await storeKit.restorePurchases()
        isPurchasing = false
    }
}

// MARK: - Preview

#Preview {
    BillixStoreView()
}
