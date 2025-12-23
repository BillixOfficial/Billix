//
//  LegalDisclaimerComponents.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Legal disclaimer components for proper platform positioning
//
//  IMPORTANT: Billix is a COORDINATION platform, NOT a financial intermediary.
//  All financial transactions occur DIRECTLY between users and service providers.
//

import SwiftUI

// MARK: - Disclaimer Type

enum DisclaimerType {
    case onboarding
    case swapConfirmation
    case paymentInstructions
    case general
    case receipt
    case marketplace

    var title: String {
        switch self {
        case .onboarding: return "How Billix Works"
        case .swapConfirmation: return "Important"
        case .paymentInstructions: return "Payment Instructions"
        case .general: return "About Billix"
        case .receipt: return "Receipt Verification"
        case .marketplace: return "Marketplace Activity"
        }
    }

    var icon: String {
        switch self {
        case .onboarding: return "info.circle.fill"
        case .swapConfirmation: return "exclamationmark.triangle.fill"
        case .paymentInstructions: return "dollarsign.circle.fill"
        case .general: return "building.2.fill"
        case .receipt: return "doc.text.image"
        case .marketplace: return "chart.line.uptrend.xyaxis"
        }
    }

    var color: Color {
        switch self {
        case .onboarding: return .blue
        case .swapConfirmation: return .orange
        case .paymentInstructions: return .green
        case .general: return .gray
        case .receipt: return .purple
        case .marketplace: return .cyan
        }
    }

    var text: String {
        switch self {
        case .onboarding:
            return "Billix facilitates peer coordination for bill payments. We do not transfer money, hold funds, or guarantee payments. You and your swap partner pay each other's bills directly to the service providers."

        case .swapConfirmation:
            return "By confirming this swap, you agree to pay your partner's bill directly to their service provider. Billix does not handle or guarantee any payments. Payment verification is done through screenshot confirmation."

        case .paymentInstructions:
            return "Pay directly to your partner's service provider using their account details. Do NOT send money to Billix or your swap partner. Upload a screenshot of your payment confirmation to complete the swap."

        case .general:
            return "Billix is a coordination platform that connects people to help each other with bills. All payments are made directly between users and service providers. We never handle, hold, or transfer money."

        case .receipt:
            return "Upload receipts to verify you've paid a bill. This earns you credits and builds trust in the community. Receipts are verified automatically and never shared with other users."

        case .marketplace:
            return "The marketplace shows anonymized swap activity to help you understand demand. All personal details are hidden. Actual swaps are matched based on compatibility and trust scores."
        }
    }
}

// MARK: - Compact Disclaimer Banner

struct DisclaimerBanner: View {
    var type: DisclaimerType = .general
    var isExpandable: Bool = false
    @State private var isExpanded = false

    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                if isExpandable {
                    withAnimation { isExpanded.toggle() }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: type.icon)
                        .font(.system(size: 16))
                        .foregroundColor(type.color)

                    Text(type.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(primaryText)

                    Spacer()

                    if isExpandable {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            if !isExpandable || isExpanded {
                Text(type.text)
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(type.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Full Page Disclaimer

struct FullPageDisclaimer: View {
    let onAccept: () -> Void

    @State private var hasScrolledToBottom = false

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(accent)

                Text("Understanding Billix")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(primaryText)

                Text("Please read before continuing")
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)
            }
            .padding(.vertical, 24)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // What Billix IS
                    sectionCard(
                        title: "What Billix IS",
                        icon: "checkmark.circle.fill",
                        color: .green,
                        points: [
                            "A coordination platform connecting people for bill assistance",
                            "A trust system to help you find reliable swap partners",
                            "A verification system using screenshot proof",
                            "A community-based approach to mutual aid"
                        ]
                    )

                    // What Billix is NOT
                    sectionCard(
                        title: "What Billix is NOT",
                        icon: "xmark.circle.fill",
                        color: .red,
                        points: [
                            "NOT a money transfer service",
                            "NOT an escrow or payment processor",
                            "NOT a guarantor of payments",
                            "NOT responsible for failed swap agreements"
                        ]
                    )

                    // How payments work
                    sectionCard(
                        title: "How Payments Work",
                        icon: "arrow.left.arrow.right",
                        color: .blue,
                        points: [
                            "You pay your partner's bill directly to their provider",
                            "Your partner pays your bill directly to your provider",
                            "No money ever passes through Billix",
                            "Screenshot verification confirms completion"
                        ]
                    )

                    // Your responsibility
                    sectionCard(
                        title: "Your Responsibility",
                        icon: "person.fill.checkmark",
                        color: .orange,
                        points: [
                            "Verify partner's bill details before paying",
                            "Upload proof of payment promptly",
                            "Communicate with your partner if issues arise",
                            "Report any problems to Billix support"
                        ]
                    )

                    // Bottom detector
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .global).maxY)
                    }
                    .frame(height: 1)
                }
                .padding()
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { maxY in
                let screenHeight = UIScreen.main.bounds.height
                if maxY < screenHeight + 100 {
                    hasScrolledToBottom = true
                }
            }

            // Accept button
            VStack(spacing: 12) {
                if !hasScrolledToBottom {
                    Text("Scroll to read all terms")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)
                }

                Button {
                    onAccept()
                } label: {
                    Text("I Understand")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(hasScrolledToBottom ? accent : accent.opacity(0.5))
                        .cornerRadius(12)
                }
                .disabled(!hasScrolledToBottom)
            }
            .padding()
            .background(cardBg)
        }
        .background(background.ignoresSafeArea())
    }

    private func sectionCard(title: String, icon: String, color: Color, points: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(points, id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(color.opacity(0.5))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(point)
                            .font(.system(size: 14))
                            .foregroundColor(secondaryText)
                    }
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }
}

// MARK: - Inline Disclaimer Text

struct InlineDisclaimer: View {
    let text: String
    var fontSize: CGFloat = 11

    private let secondaryText = Color.gray

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .foregroundColor(secondaryText.opacity(0.8))
            .multilineTextAlignment(.center)
    }
}

// MARK: - Swap Confirmation Disclaimer

struct SwapConfirmationDisclaimer: View {
    let partnerName: String
    let billProvider: String
    let billAmount: Decimal

    @Binding var hasAccepted: Bool

    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Warning header
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)

                Text("Confirm Your Agreement")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)
            }

            // Agreement text
            VStack(alignment: .leading, spacing: 8) {
                Text("By confirming, you agree to:")
                    .font(.system(size: 13))
                    .foregroundColor(secondaryText)

                agreementPoint("Pay \(formatCurrency(billAmount)) directly to \(billProvider)")
                agreementPoint("Upload proof of payment within 48 hours")
                agreementPoint("Communicate with \(partnerName) if any issues arise")
            }

            // Disclaimer
            Text("Billix does not transfer, hold, or guarantee any payments. You are paying the service provider directly, not Billix or your partner.")
                .font(.system(size: 11))
                .foregroundColor(.orange.opacity(0.8))
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)

            // Checkbox
            Button {
                hasAccepted.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: hasAccepted ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundColor(hasAccepted ? Color(red: 0.4, green: 0.8, blue: 0.6) : secondaryText)

                    Text("I understand and accept these terms")
                        .font(.system(size: 13))
                        .foregroundColor(primaryText)

                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    private func agreementPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(primaryText)
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }
}

// MARK: - Payment Instructions Card

struct PaymentInstructionsCard: View {
    let providerName: String
    let accountNumber: String?
    let amount: Decimal

    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)

                Text("Payment Instructions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)
            }

            // Steps
            VStack(alignment: .leading, spacing: 12) {
                stepRow(number: 1, text: "Go to \(providerName)'s website or app")
                stepRow(number: 2, text: "Log in or enter account: \(accountNumber ?? "See details")")
                stepRow(number: 3, text: "Pay \(formatCurrency(amount))")
                stepRow(number: 4, text: "Take a screenshot of the confirmation")
                stepRow(number: 5, text: "Upload the screenshot to Billix")
            }

            // Warning
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)

                Text("Do NOT send money to your swap partner or to Billix")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
                .background(accent)
                .cornerRadius(12)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(primaryText)
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview("Disclaimers") {
    ZStack {
        Color(red: 0.06, green: 0.06, blue: 0.08).ignoresSafeArea()

        ScrollView {
            VStack(spacing: 20) {
                DisclaimerBanner(type: DisclaimerType.onboarding)
                DisclaimerBanner(type: DisclaimerType.swapConfirmation)
                DisclaimerBanner(type: DisclaimerType.paymentInstructions, isExpandable: true)

                SwapConfirmationDisclaimer(
                    partnerName: "Alex",
                    billProvider: "AT&T",
                    billAmount: 85.00,
                    hasAccepted: .constant(false)
                )

                PaymentInstructionsCard(
                    providerName: "Verizon",
                    accountNumber: "***-***-1234",
                    amount: 120.50
                )

                InlineDisclaimer(text: "Billix is a coordination platform. We do not transfer money, hold funds, or guarantee payments.")
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
