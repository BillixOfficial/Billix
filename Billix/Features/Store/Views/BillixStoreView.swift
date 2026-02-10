//
//  BillixStoreView.swift
//  Billix
//
//  Store view for membership and token purchases
//

import SwiftUI
import StoreKit

struct BillixStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeKit = StoreKitService.shared
    @StateObject private var tokenService = TokenService.shared

    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var animateGlow = false
    @State private var showPurchaseSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "#F8FAF9"),
                        Color(hex: "#EEF4F1"),
                        Color(hex: "#E8F0EC")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Logo Header
                        logoHeader

                        // Token Balance Card
                        tokenBalanceCard

                        // Membership Section
                        membershipCard

                        // Buy Tokens Section
                        buyTokensCard

                        // Restore purchases
                        restoreSection

                        // Legal
                        legalSection

                        Spacer().frame(height: 40)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                Color(hex: "#8B9A94"),
                                Color(hex: "#E8EDEB")
                            )
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
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animateGlow = true
                }
            }
        }
    }

    // MARK: - Logo Header

    private var logoHeader: some View {
        VStack(spacing: 8) {
            Image("billix_logo_new")
                .resizable()
                .scaledToFit()
                .frame(height: 50)

            Text("Store")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "#2D3B35"))
        }
        .padding(.top, 8)
    }

    // MARK: - Token Balance Card

    private var tokenBalanceCard: some View {
        VStack(spacing: 20) {
            // Glowing token icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.billixGoldenAmber.opacity(animateGlow ? 0.3 : 0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 10)

                // Middle ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.billixGoldenAmber, Color(hex: "#F5C842")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 85, height: 85)

                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#F5C842"), Color.billixGoldenAmber],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.billixGoldenAmber.opacity(0.5), radius: 10, y: 4)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
            }

            // Balance display
            VStack(spacing: 6) {
                Text("YOUR BALANCE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .tracking(1.5)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(tokenService.tokenBalance)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Text("tokens")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "#8B9A94"))
                        .padding(.bottom, 8)
                }
            }

            // Member status
            if storeKit.isMember {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("MEMBER")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.billixMoneyGreen, Color.billixDarkTeal],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: Color.billixMoneyGreen.opacity(0.4), radius: 8, y: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [Color.billixGoldenAmber.opacity(0.3), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Membership Card

    private var membershipCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.billixMoneyGreen.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color.billixMoneyGreen)
                    }

                    Text("Membership")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3B35"))
                }

                Spacer()

                if storeKit.isMember {
                    Text("ACTIVE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.billixMoneyGreen)
                        .cornerRadius(12)
                }
            }

            if !storeKit.isMember {
                // Price display
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$6.99")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#2D3B35"))
                            Text("/month")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "#8B9A94"))
                        }
                        Text("Cancel anytime")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#A0ABA6"))
                    }

                    Spacer()

                    // Best value badge
                    Text("BEST VALUE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color.billixGoldenAmber, Color(hex: "#E8A830")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                }

                // Divider with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color(hex: "#E0E8E4"), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.vertical, 4)

                // Features grid
                VStack(spacing: 14) {
                    HStack(spacing: 20) {
                        memberFeature(icon: "infinity", text: "Unlimited\nConnections")
                        memberFeature(icon: "chart.bar.fill", text: "Bill\nAnalysis")
                    }
                    HStack(spacing: 20) {
                        memberFeature(icon: "arrow.left.arrow.right", text: "Market\nCompare")
                        memberFeature(icon: "bolt.slash.fill", text: "No Tokens\nNeeded")
                    }
                }

                // Subscribe button
                Button {
                    Task { await purchaseMembership() }
                } label: {
                    HStack(spacing: 10) {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                            Text("Get Membership")
                                .font(.system(size: 17, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.billixMoneyGreen, Color.billixDarkTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.billixMoneyGreen.opacity(0.4), radius: 12, y: 6)
                }
                .disabled(isPurchasing)
                .padding(.top, 8)
            } else {
                // Member message
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color.billixMoneyGreen)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're a member!")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                        Text("Enjoy unlimited access to everything")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#8B9A94"))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.billixMoneyGreen.opacity(0.1))
                .cornerRadius(14)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.billixMoneyGreen.opacity(0.15), lineWidth: 1)
        )
    }

    private func memberFeature(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.billixMoneyGreen.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.billixMoneyGreen)
            }

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#5D6D66"))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Buy Tokens Card

    private var buyTokensCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.billixGoldenAmber.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color.billixGoldenAmber)
                    }

                    Text("Buy Tokens")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3B35"))
                }

                Spacer()

                // Balance pill
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                    Text("\(tokenService.tokenBalance)")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(Color.billixGoldenAmber)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.billixGoldenAmber.opacity(0.15))
                .cornerRadius(14)
            }

            // Token uses
            if !storeKit.isMember {
                HStack(spacing: 0) {
                    Spacer()
                    tokenUse(icon: "link", label: "Connect")
                    Spacer()
                    tokenUse(icon: "chart.bar", label: "Analyze")
                    Spacer()
                    tokenUse(icon: "arrow.left.arrow.right", label: "Compare")
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "#FFFBF2"))
                        .stroke(Color.billixGoldenAmber.opacity(0.2), lineWidth: 1)
                )
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(Color.billixMoneyGreen)
                    Text("Members have unlimited access!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#5D6D66"))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.billixMoneyGreen.opacity(0.1))
                .cornerRadius(14)
            }

            // Token pack
            HStack(spacing: 18) {
                // Token visual
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FFF8E8"), Color(hex: "#FFF2D6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.billixGoldenAmber.opacity(0.3), lineWidth: 1)
                        )

                    VStack(spacing: 2) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color.billixGoldenAmber)

                        Text("+2")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color.billixGoldenAmber)
                    }
                }

                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Token Pack")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Text("2 tokens • One-time")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                // Buy button
                Button {
                    Task { await purchaseTokens() }
                } label: {
                    Text("$1.99")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.billixGoldenAmber, Color(hex: "#E8A830")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color.billixGoldenAmber.opacity(0.4), radius: 8, y: 4)
                }
                .disabled(isPurchasing)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: Color.billixGoldenAmber.opacity(0.15), radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.billixGoldenAmber.opacity(0.25), lineWidth: 1)
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: 8)
        )
    }

    private func tokenUse(icon: String, label: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.billixGoldenAmber.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.billixGoldenAmber)
            }

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#5D6D66"))
        }
    }

    // MARK: - Restore Section

    private var restoreSection: some View {
        Button {
            Task { await restorePurchases() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                Text("Restore Purchases")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(Color(hex: "#6B7B75"))
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "#D0DBD6"), lineWidth: 1.5)
            )
        }
        .disabled(isPurchasing)
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: 10) {
            Text("Membership auto-renews at $6.99/month unless cancelled at least 24 hours before the end of the current period.")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#A0ABA6"))
                .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Button("Terms") {
                    // Open terms
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#5B8A6B"))

                Text("•")
                    .foregroundColor(Color(hex: "#C0CBC6"))

                Button("Privacy") {
                    // Open privacy
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#5B8A6B"))
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Purchase Success Overlay

    private var purchaseSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.billixMoneyGreen.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Circle()
                        .fill(Color.billixMoneyGreen)
                        .frame(width: 70, height: 70)

                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Purchase Complete!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Button {
                    showPurchaseSuccess = false
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Color.billixMoneyGreen)
                        .cornerRadius(14)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white)
            )
            .padding(40)
        }
    }

    // MARK: - Actions

    private func purchaseMembership() async {
        isPurchasing = true

        // Simulate purchase for testing since products aren't in App Store Connect yet
        if storeKit.monthlyProduct == nil {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
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

        // Simulate purchase for testing since products aren't in App Store Connect yet
        if storeKit.tokenPackProduct == nil {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
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
