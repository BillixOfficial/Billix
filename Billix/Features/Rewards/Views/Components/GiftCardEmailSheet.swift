//
//  GiftCardEmailSheet.swift
//  Billix
//
//  Created by Claude Code on 12/22/24.
//  Email collection sheet for gift card delivery
//

import SwiftUI

struct GiftCardEmailSheet: View {
    let reward: Reward
    let userPoints: Int
    let onRedeem: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var isValidEmail: Bool = false
    @FocusState private var isEmailFieldFocused: Bool

    private var canAfford: Bool {
        userPoints >= reward.pointsCost
    }

    private var pointsNeeded: Int {
        max(reward.pointsCost - userPoints, 0)
    }

    private var brandColor: Color {
        Color(hex: reward.accentColor)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 24) {
                // Reward Icon
                ZStack {
                    Circle()
                        .fill(brandColor.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: reward.iconName)
                        .font(.system(size: 36))
                        .foregroundColor(brandColor)
                }

                // Reward Info
                VStack(spacing: 8) {
                    Text(reward.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.billixDarkGreen)

                    Text(reward.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                        .multilineTextAlignment(.center)

                    // Points cost
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(brandColor)

                        Text("\(reward.pointsCost) pts")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.billixDarkGreen)
                    }
                    .padding(.top, 8)
                }

                // Email Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("ENTER YOUR EMAIL")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.billixMediumGreen)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    VStack(alignment: .leading, spacing: 8) {
                        TextField("your.email@example.com", text: $email)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.billixDarkGreen)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($isEmailFieldFocused)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderColor, lineWidth: 2)
                            )
                            .onChange(of: email) { oldValue, newValue in
                                validateEmail(newValue)
                            }

                        // Explanation text
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.billixMediumGreen)

                            Text("We'll send your gift card code to this email")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.billixMediumGreen)
                        }
                        .padding(.leading, 4)
                    }
                }

                // Delivery Information Section
                VStack(alignment: .leading, spacing: 16) {
                    // How it works header
                    Text("HOW IT WORKS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.billixMediumGreen)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    // Step-by-step delivery info
                    VStack(alignment: .leading, spacing: 14) {
                        // Step 1
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(brandColor.opacity(0.15))
                                    .frame(width: 32, height: 32)

                                Text("1")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(brandColor)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Instant Redemption")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.billixDarkGreen)

                                Text("Points are deducted immediately from your account")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.billixMediumGreen)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        // Step 2
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(brandColor.opacity(0.15))
                                    .frame(width: 32, height: 32)

                                Text("2")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(brandColor)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email Delivery in 24-48 Hours")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.billixDarkGreen)

                                Text("Check your inbox (and spam folder) for your digital gift card code")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.billixMediumGreen)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        // Step 3
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(brandColor.opacity(0.15))
                                    .frame(width: 32, height: 32)

                                Text("3")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(brandColor)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start Shopping")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.billixDarkGreen)

                                Text("Use your code online or in-store at \(reward.brand ?? "the retailer")")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.billixMediumGreen)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Support note
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.billixMoneyGreen)

                        Text("Questions? Contact support@billix.com")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.billixMoneyGreen.opacity(0.08))
                    )
                }

                Spacer()

                // Affordability & Redeem Button
                VStack(spacing: 16) {
                    // Affordability indicator
                    if !canAfford {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)

                            Text("Need \(pointsNeeded) more points")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.billixMediumGreen)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }

                    // Redeem button
                    Button {
                        if canAfford && isValidEmail {
                            onRedeem(email)
                            dismiss()
                        }
                    } label: {
                        Text(buttonTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: canRedeemColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                    }
                    .disabled(!canRedeem)
                    .buttonStyle(ScaleButtonStyle(scale: 0.97))
                }
            }
            .padding(24)
            .background(Color.white)

            // X Close Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.billixMediumGreen.opacity(0.1))
                    )
            }
            .padding(16)
        }
        .onAppear {
            // Auto-focus email field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isEmailFieldFocused = true
            }
        }
    }

    // MARK: - Helpers

    private var borderColor: Color {
        if !email.isEmpty && !isValidEmail {
            return .red
        } else if isValidEmail {
            return brandColor
        } else {
            return .billixBorderGreen
        }
    }

    private var canRedeem: Bool {
        canAfford && isValidEmail
    }

    private var buttonTitle: String {
        if !canAfford {
            return "Not Enough Points"
        } else if !isValidEmail {
            return "Enter Valid Email"
        } else {
            return "Redeem Gift Card"
        }
    }

    private var canRedeemColors: [Color] {
        if canRedeem {
            return [brandColor, brandColor.opacity(0.8)]
        } else {
            return [.gray.opacity(0.3), .gray.opacity(0.3)]
        }
    }

    private func validateEmail(_ email: String) {
        // Simple email validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        isValidEmail = emailPredicate.evaluate(with: email)
    }
}

// MARK: - Preview

#Preview {
    GiftCardEmailSheet(
        reward: Reward(
            id: UUID(),
            type: .giftCard,
            category: .giftCard,
            title: "$10 Target Gift Card",
            description: "Shop at Target stores or online",
            pointsCost: 20000,
            brand: "Target",
            brandGroup: "target",
            dollarValue: 10,
            iconName: "target",
            accentColor: "#CC0000"
        ),
        userPoints: 25000,
        onRedeem: { email in
            print("Redeem with email: \(email)")
        }
    )
}
