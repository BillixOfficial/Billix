//
//  UpgradeMembershipView.swift
//  Billix
//
//  Displayed when user reaches their monthly connection limit
//  Encourages upgrade to higher tier for more connections
//

import SwiftUI

struct UpgradeMembershipView: View {
    let currentTier: ReputationTier
    let monthlyLimit: Int
    let onDismiss: () -> Void
    let onUpgrade: () -> Void

    @StateObject private var storeKit = StoreKitService.shared
    @State private var animateGradient = false
    @State private var animateContent = false
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPurchaseSuccess = false

    private let accentColor = Color(hex: "#5B8A6B")
    private let goldColor = Color(hex: "#E8B54D")
    private let purpleColor = Color(hex: "#9B7B9F")

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#F7F9F8"),
                    accentColor.opacity(0.08),
                    purpleColor.opacity(0.05)
                ],
                startPoint: animateGradient ? .topLeading : .topTrailing,
                endPoint: animateGradient ? .bottomTrailing : .bottomLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateGradient)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header with illustration
                    headerSection
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)

                    // Current status card
                    currentStatusCard
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)

                    // Upgrade benefits
                    upgradeBenefitsSection
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)

                    // Upgrade tiers
                    upgradeTiersSection
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)

                    // Action buttons
                    actionButtons
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color(hex: "#8B9A94"))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 12)
                }
                Spacer()
            }
        }
        .onAppear {
            animateGradient = true
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animateContent = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Illustration
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [goldColor.opacity(0.3), goldColor.opacity(0)],
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [goldColor.opacity(0.2), goldColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)

                // Icon
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [goldColor, Color(hex: "#D4A43A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 10) {
                Text("Level Up Your Impact")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("You've reached your monthly connection limit.\nUpgrade to help more neighbors!")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Current Status Card

    private var currentStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Status")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#8B9A94"))

                    HStack(spacing: 8) {
                        Image(systemName: currentTier.icon)
                            .font(.system(size: 18))
                            .foregroundColor(currentTier.color)

                        Text(currentTier.displayName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                    }
                }

                Spacer()

                // Progress indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text("This Month")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#8B9A94"))

                    HStack(spacing: 4) {
                        Text("\(monthlyLimit)/\(monthlyLimit)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "#E07A6B"))

                        Text("used")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#8B9A94"))
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#E5E5E5"))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#E07A6B"))
                        .frame(width: geometry.size.width, height: 8)
                }
            }
            .frame(height: 8)

            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8B9A94"))

                Text("Resets next month")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
    }

    // MARK: - Upgrade Benefits Section

    private var upgradeBenefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why Upgrade?")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#2D3B35"))

            VStack(spacing: 12) {
                BenefitRow(
                    icon: "infinity",
                    title: "Unlimited Connections",
                    description: "Help as many neighbors as you want",
                    color: accentColor
                )

                BenefitRow(
                    icon: "dollarsign.circle.fill",
                    title: "Higher Bill Limits",
                    description: "Support bills up to $500",
                    color: goldColor
                )

                BenefitRow(
                    icon: "star.fill",
                    title: "Priority Matching",
                    description: "Get matched faster with supporters",
                    color: purpleColor
                )

                BenefitRow(
                    icon: "shield.checkmark.fill",
                    title: "Verified Badge",
                    description: "Build trust in the community",
                    color: Color(hex: "#5BA4D4")
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
    }

    // MARK: - Upgrade Tiers Section

    private var upgradeTiersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upgrade Path")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#2D3B35"))

            VStack(spacing: 12) {
                // Contributor tier
                TierUpgradeCard(
                    tier: .contributor,
                    isNext: currentTier == .neighbor,
                    requirements: "Verify your identity with Gov ID",
                    benefits: ["Up to $150 bills", "Unlimited connections"]
                )

                // Pillar tier
                TierUpgradeCard(
                    tier: .pillar,
                    isNext: currentTier == .contributor,
                    requirements: "Complete 15 successful connections",
                    benefits: ["Up to $500 bills", "Community leader status"]
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Membership price card
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$6.99")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#2D3B35"))
                    Text("/month")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#8B9A94"))

                    Spacer()

                    Text("Cancel anytime")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                // Purchase button
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
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [accentColor, Color(hex: "#4A7A5B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .disabled(isPurchasing)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)

            Button {
                onDismiss()
            } label: {
                Text("Maybe Later")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }
            .padding(.top, 4)
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
    }

    // MARK: - Purchase Success Overlay

    private var purchaseSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Circle()
                        .fill(accentColor)
                        .frame(width: 56, height: 56)

                    Image(systemName: "checkmark")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Welcome to Contributor!")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("You now have unlimited connections")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8B9A94"))

                Button {
                    showPurchaseSuccess = false
                    onDismiss()
                } label: {
                    Text("Continue")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(accentColor)
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

    // MARK: - Purchase Action

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
            let transaction = try await storeKit.purchase(storeKit.monthlyProduct!)
            // Only show success if transaction completed (not cancelled)
            if transaction != nil {
                showPurchaseSuccess = true
            }
            // If nil, user cancelled - do nothing
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            Spacer()
        }
    }
}

// MARK: - Tier Upgrade Card

private struct TierUpgradeCard: View {
    let tier: ReputationTier
    let isNext: Bool
    let requirements: String
    let benefits: [String]

    var body: some View {
        HStack(spacing: 14) {
            // Tier icon
            ZStack {
                Circle()
                    .fill(tier.color.opacity(isNext ? 0.15 : 0.08))
                    .frame(width: 50, height: 50)

                Image(systemName: tier.icon)
                    .font(.system(size: 22))
                    .foregroundColor(tier.color.opacity(isNext ? 1 : 0.5))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tier.displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isNext ? Color(hex: "#2D3B35") : Color(hex: "#8B9A94"))

                    if isNext {
                        Text("NEXT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(tier.color)
                            .cornerRadius(4)
                    }
                }

                Text(requirements)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8B9A94"))

                HStack(spacing: 8) {
                    ForEach(benefits, id: \.self) { benefit in
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                            Text(benefit)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(tier.color.opacity(isNext ? 1 : 0.6))
                    }
                }
            }

            Spacer()
        }
        .padding(14)
        .background(isNext ? tier.color.opacity(0.05) : Color(hex: "#F8F8F8"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isNext ? tier.color.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Preview

struct UpgradeMembershipView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeMembershipView(
        currentTier: .neighbor,
        monthlyLimit: 1,
        onDismiss: {},
        onUpgrade: {}
        )
    }
}
