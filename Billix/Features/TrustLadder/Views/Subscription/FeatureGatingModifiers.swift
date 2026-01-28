//
//  FeatureGatingModifiers.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  View modifiers and components for gating premium features
//

import SwiftUI

// MARK: - Feature Gate View Modifier

/// A view modifier that gates content behind a subscription/credit check
struct FeatureGateModifier: ViewModifier {
    let feature: PremiumFeature
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        if subscriptionService.hasAccess(to: feature) {
            content
        } else {
            // Show locked version with tap to unlock
            lockedContent(content)
        }
    }

    private func lockedContent(_ content: Content) -> some View {
        ZStack {
            // Blurred/dimmed background
            content
                .blur(radius: 8)
                .opacity(0.3)
                .allowsHitTesting(false)

            // Lock overlay
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))

                Text(feature.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("Requires \(feature.requiredTier.displayName)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))

                Button {
                    showPaywall = true
                } label: {
                    Text("Unlock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.4, green: 0.8, blue: 0.6))
                        .cornerRadius(8)
                }
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: .featureGate(feature))
        }
    }
}

// MARK: - Feature Gate Button

/// A button that checks feature access before executing action
struct FeatureGateButton<Label: View>: View {
    let feature: PremiumFeature
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showPaywall = false

    var body: some View {
        Button {
            if subscriptionService.hasAccess(to: feature) {
                action()
            } else {
                showPaywall = true
            }
        } label: {
            label()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: .featureGate(feature))
        }
    }
}

// MARK: - Premium Badge

/// A small badge indicating a feature is premium
struct PremiumBadge: View {
    let tier: BillixSubscriptionTier

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tier.icon)
                .font(.system(size: 10))
            Text(tier.displayName)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(tier.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(tier.color.opacity(0.15))
        .cornerRadius(4)
    }
}

// MARK: - Feature Lock Icon

/// An icon overlay showing lock status
struct FeatureLockIcon: View {
    let feature: PremiumFeature
    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        if !subscriptionService.hasAccess(to: feature) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
                .padding(4)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
    }
}

// MARK: - Gated Row

/// A list row that shows lock status and handles unlock flow
struct GatedFeatureRow: View {
    let feature: PremiumFeature
    let title: String
    let subtitle: String?
    let icon: String
    let action: () -> Void

    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showPaywall = false

    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let primaryText = Color.white
    private let secondaryText = Color.gray
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)

    var isUnlocked: Bool {
        subscriptionService.hasAccess(to: feature)
    }

    var body: some View {
        Button {
            if isUnlocked {
                action()
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isUnlocked ? accent : secondaryText)

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(3)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                            .offset(x: 10, y: 10)
                    }
                }
                .frame(width: 40, height: 40)
                .background(isUnlocked ? accent.opacity(0.15) : secondaryText.opacity(0.1))
                .cornerRadius(10)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(isUnlocked ? primaryText : secondaryText)

                        if !isUnlocked {
                            PremiumBadge(tier: feature.requiredTier)
                        }
                    }

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)
                    }
                }

                Spacer()

                // Chevron or unlock indicator
                if isUnlocked {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(secondaryText)
                } else if let cost = feature.creditCost {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(cost)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.yellow)
                        Text("credits")
                            .font(.system(size: 9))
                            .foregroundColor(secondaryText)
                    }
                }
            }
            .padding()
            .background(cardBg)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: .featureGate(feature))
        }
    }
}

// MARK: - Premium Feature Card

/// A card highlighting a premium feature with unlock option
struct PremiumFeatureCard: View {
    let feature: PremiumFeature
    let onTap: () -> Void

    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showPaywall = false

    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var isUnlocked: Bool {
        subscriptionService.hasAccess(to: feature)
    }

    var body: some View {
        Button {
            if isUnlocked {
                onTap()
            } else {
                showPaywall = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: feature.icon)
                        .font(.system(size: 24))
                        .foregroundColor(feature.requiredTier.color)

                    Spacer()

                    if !isUnlocked {
                        PremiumBadge(tier: feature.requiredTier)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                Text(feature.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)

                Text(feature.description)
                    .font(.system(size: 13))
                    .foregroundColor(secondaryText)
                    .lineLimit(2)

                if !isUnlocked {
                    HStack {
                        if let cost = feature.creditCost {
                            Label("\(cost) credits", systemImage: "star.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow)
                        }

                        Spacer()

                        Text("Tap to unlock")
                            .font(.system(size: 11))
                            .foregroundColor(secondaryText)
                    }
                }
            }
            .padding()
            .background(cardBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isUnlocked ? Color.green.opacity(0.3) : feature.requiredTier.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: .featureGate(feature))
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Gates this view behind a premium feature check
    func requiresFeature(_ feature: PremiumFeature) -> some View {
        modifier(FeatureGateModifier(feature: feature))
    }
}

// MARK: - Environment Key for Subscription

private struct SubscriptionTierKey: EnvironmentKey {
    static let defaultValue: BillixSubscriptionTier = .free
}

extension EnvironmentValues {
    var subscriptionTier: BillixSubscriptionTier {
        get { self[SubscriptionTierKey.self] }
        set { self[SubscriptionTierKey.self] = newValue }
    }
}

// MARK: - Paywall Trigger Modifier

/// Modifier that can trigger paywall from anywhere
struct PaywallTriggerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let context: PaywallContext

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                PaywallView(context: context)
            }
    }
}

extension View {
    func paywall(isPresented: Binding<Bool>, context: PaywallContext) -> some View {
        modifier(PaywallTriggerModifier(isPresented: isPresented, context: context))
    }
}

// MARK: - Preview

#Preview("Feature Gate Components") {
    ZStack {
        Color(red: 0.06, green: 0.06, blue: 0.08).ignoresSafeArea()

        ScrollView {
            VStack(spacing: 20) {
                // Gated Row examples
                GatedFeatureRow(
                    feature: .fractionalSwaps,
                    title: "Fractional Swaps",
                    subtitle: "Cover only a portion of a bill",
                    icon: "chart.pie"
                ) {
                }

                GatedFeatureRow(
                    feature: .exactMatchSwaps,
                    title: "Exact Match Swaps",
                    subtitle: "1:1 bill coordination",
                    icon: "arrow.left.arrow.right"
                ) {
                }

                // Feature cards
                PremiumFeatureCard(feature: .multiPartySwaps) {
                }

                PremiumFeatureCard(feature: .groupSwaps) {
                }

                // Badge examples
                HStack {
                    PremiumBadge(tier: .basic)
                    PremiumBadge(tier: .pro)
                    PremiumBadge(tier: .premium)
                }
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
