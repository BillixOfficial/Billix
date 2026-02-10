//
//  BillixStoreView.swift
//  Billix
//
//  Store view for membership and token purchases
//

import SwiftUI
import StoreKit

// MARK: - Theme (matching HomeView)

private enum Theme {
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let accent = Color(hex: "#5B8A6B")
    static let accentLight = Color(hex: "#5B8A6B").opacity(0.08)
    static let success = Color(hex: "#4CAF7A")
    static let warning = Color(hex: "#E8A54B")
    static let purple = Color(hex: "#9B7EB8")

    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 16
    static let shadowColor = Color.black.opacity(0.03)
    static let shadowRadius: CGFloat = 8
}

struct BillixStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeKit = StoreKitService.shared
    @StateObject private var tokenService = TokenService.shared

    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPurchaseSuccess = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Token Balance Section
                    tokenBalanceSection

                    // Membership Card
                    membershipSection

                    // Buy Tokens Card
                    buyTokensSection

                    // Restore & Legal
                    footerSection

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.top, 12)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.secondaryText, Color(hex: "#E8EDEB"))
                    }
                }
            }
            .alert("Purchase", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if showPurchaseSuccess {
                    purchaseSuccessOverlay
                }
            }
            .onAppear {
                Task {
                    await tokenService.loadTokenBalance()
                }
            }
        }
    }

    // MARK: - Token Balance Section

    private var tokenBalanceSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.warning.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.warning)
            }

            // Balance
            VStack(spacing: 4) {
                Text("YOUR BALANCE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.secondaryText)
                    .tracking(1)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(tokenService.tokenBalance)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)

                    Text("tokens")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
                }
            }

            // Member badge
            if storeKit.isMember {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                    Text("MEMBER")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.accent)
                .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, Theme.cardPadding)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
    }

    // MARK: - Membership Section

    private var membershipSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.accent)
                    }

                    Text("Membership")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.primaryText)
                }

                Spacer()

                if storeKit.isMember {
                    Text("ACTIVE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.success)
                        .cornerRadius(10)
                }
            }

            if !storeKit.isMember {
                // Price
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$6.99")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)
                    Text("/month")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.secondaryText)

                    Spacer()

                    Text("Cancel anytime")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.secondaryText)
                }

                // Features
                VStack(spacing: 10) {
                    featureRow(icon: "infinity", text: "Unlimited connections")
                    featureRow(icon: "chart.bar.fill", text: "Full bill analysis")
                    featureRow(icon: "arrow.left.arrow.right", text: "Market comparisons")
                    featureRow(icon: "bolt.slash.fill", text: "No tokens needed")
                }
                .padding(.vertical, 4)

                // Subscribe button
                Button {
                    Task { await purchaseMembership() }
                } label: {
                    HStack(spacing: 8) {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                            Text("Get Membership")
                                .font(.system(size: 15, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.accent)
                    .cornerRadius(12)
                }
                .disabled(isPurchasing)
            } else {
                // Active member message
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.success)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're a member!")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.primaryText)
                        Text("Enjoy unlimited access")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.secondaryText)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.success.opacity(0.08))
                .cornerRadius(12)
            }
        }
        .padding(Theme.cardPadding)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.accent)
                .frame(width: 28, height: 28)
                .background(Theme.accentLight)
                .cornerRadius(8)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.primaryText)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.accent)
        }
    }

    // MARK: - Buy Tokens Section

    private var buyTokensSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Theme.warning.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.warning)
                    }

                    Text("Buy Tokens")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.primaryText)
                }

                Spacer()

                // Current balance pill
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text("\(tokenService.tokenBalance)")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(Theme.warning)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.warning.opacity(0.12))
                .cornerRadius(12)
            }

            // Info text
            if !storeKit.isMember {
                Text("Use tokens to connect with others, analyze bills, and compare rates.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.secondaryText)
                    .lineSpacing(2)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.success)
                    Text("Members have unlimited access!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.primaryText)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.success.opacity(0.08))
                .cornerRadius(10)
            }

            // Token pack row
            HStack(spacing: 14) {
                // Token icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.warning.opacity(0.12))
                        .frame(width: 56, height: 56)

                    VStack(spacing: 2) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.warning)
                        Text("+2")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.warning)
                    }
                }

                // Description
                VStack(alignment: .leading, spacing: 2) {
                    Text("Token Pack")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.primaryText)

                    Text("2 tokens • One-time purchase")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                // Buy button
                Button {
                    Task { await purchaseTokens() }
                } label: {
                    Text("$1.99")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Theme.warning)
                        .cornerRadius(10)
                }
                .disabled(isPurchasing)
            }
            .padding(14)
            .background(Theme.warning.opacity(0.06))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.warning.opacity(0.15), lineWidth: 1)
            )
        }
        .padding(Theme.cardPadding)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 16) {
            // Restore purchases button
            Button {
                Task { await restorePurchases() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                    Text("Restore Purchases")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Theme.secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#D0DBD6"), lineWidth: 1)
                )
            }
            .disabled(isPurchasing)

            // Legal text
            VStack(spacing: 8) {
                Text("Membership auto-renews at $6.99/month unless cancelled at least 24 hours before the end of the current period.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    Button("Terms") { }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.accent)

                    Text("•")
                        .foregroundColor(Theme.secondaryText)

                    Button("Privacy") { }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }

    // MARK: - Purchase Success Overlay

    private var purchaseSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Theme.success.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Circle()
                        .fill(Theme.success)
                        .frame(width: 56, height: 56)

                    Image(systemName: "checkmark")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Purchase Complete!")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.primaryText)

                Button {
                    showPurchaseSuccess = false
                } label: {
                    Text("Continue")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Theme.accent)
                        .cornerRadius(12)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
            )
            .padding(40)
        }
    }

    // MARK: - Actions

    private func purchaseMembership() async {
        isPurchasing = true

        if storeKit.monthlyProduct == nil {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                isPurchasing = false
                errorMessage = "In-app purchases will be available soon! Products are being set up in App Store Connect."
                showError = true
            }
            return
        }

        do {
            _ = try await storeKit.purchase(storeKit.monthlyProduct!)
            showPurchaseSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }

    private func purchaseTokens() async {
        isPurchasing = true

        if storeKit.tokenPackProduct == nil {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                isPurchasing = false
                errorMessage = "In-app purchases will be available soon! Products are being set up in App Store Connect."
                showError = true
            }
            return
        }

        do {
            _ = try await storeKit.purchaseTokenPack()
            await tokenService.loadTokenBalance()
            showPurchaseSuccess = true
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
