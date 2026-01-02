//
//  HomePageZones.swift
//  Billix
//
//  Home page zone components for the redesigned dashboard
//

import SwiftUI

// MARK: - Utility Checkup Zone

struct UtilityCheckupZone: View {
    @State private var selectedCategory: String? = nil

    private let categories = [
        ("Electric", "bolt.fill", Color(hex: "#F59E0B")),
        ("Gas", "flame.fill", Color(hex: "#EF4444")),
        ("Water", "drop.fill", Color(hex: "#3B82F6")),
        ("Internet", "wifi", Color(hex: "#8B5CF6"))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#5B8A6B"))

                Text("30-Second Checkup")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Spacer()

                Text("Regional signals")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            HStack(spacing: 10) {
                ForEach(categories, id: \.0) { category in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = selectedCategory == category.0 ? nil : category.0
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(selectedCategory == category.0 ? category.2 : category.2.opacity(0.1))
                                    .frame(width: 44, height: 44)

                                Image(systemName: category.1)
                                    .font(.system(size: 18))
                                    .foregroundColor(selectedCategory == category.0 ? .white : category.2)
                            }

                            Text(category.0)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "#2D3B35"))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)

            if let selected = selectedCategory {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#4CAF7A"))

                    Text("Your \(selected.lowercased()) rates are competitive for your area")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#2D3B35"))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#4CAF7A").opacity(0.1))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Utility Insight Zone

struct UtilityInsightZone: View {
    let zipCode: String

    var body: some View {
        VStack(spacing: 12) {
            // Weather-Based Rate Alert Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#3B82F6"))

                    Text("Weather Rate Alert")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Spacer()

                    Text("Today")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Text("Cooler temperatures expected this week. Consider reducing heating to save on your gas bill.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#5D6D66"))
                    .lineLimit(2)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 11))
                        Text("45°F")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#3B82F6"))

                    Text("Potential savings: $8-12")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#5B8A6B"))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#3B82F6").opacity(0.08), Color(hex: "#60A5FA").opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "#3B82F6").opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Learn to Lower Zone

struct LearnToLowerZone: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#F59E0B"))

                Text("Quick Tip")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))
            }

            Text("Switching to budget billing can help smooth out seasonal spikes in your electric bill.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#8B9A94"))
                .lineLimit(3)

            Button {
                // Learn more
            } label: {
                Text("Learn how →")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#5B8A6B"))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#F59E0B").opacity(0.06))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Community Poll Zone

struct CommunityPollZoneNew: View {
    @State private var selectedOption: Int? = nil
    @State private var hasVoted = false

    private let question = "How do you handle unexpected bill increases?"
    private let options = [
        "Call provider immediately",
        "Wait and see next month",
        "Switch providers",
        "Reduce usage"
    ]
    private let votes = [42, 18, 25, 15] // percentages

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#5BA4D4"))

                Text("Community Poll")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Spacer()

                if hasVoted {
                    Text("248 votes")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }
            }

            Text(question)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#2D3B35"))

            VStack(spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button {
                        if !hasVoted {
                            withAnimation(.spring(response: 0.3)) {
                                selectedOption = index
                                hasVoted = true
                            }
                        }
                    } label: {
                        HStack {
                            Text(option)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#2D3B35"))

                            Spacer()

                            if hasVoted {
                                Text("\(votes[index])%")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(selectedOption == index ? Color(hex: "#5B8A6B") : Color(hex: "#8B9A94"))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedOption == index ? Color(hex: "#5B8A6B").opacity(0.1) : Color(hex: "#F7F9F8"))

                                if hasVoted {
                                    GeometryReader { geo in
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: "#5B8A6B").opacity(0.15))
                                            .frame(width: geo.size.width * CGFloat(votes[index]) / 100)
                                    }
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedOption == index ? Color(hex: "#5B8A6B") : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(hasVoted)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Invite & Earn Banner

struct InviteEarnBannerNew: View {
    @State private var showInviteSheet = false
    @State private var showNativeShareSheet = false
    @State private var referralCode = ""
    @State private var shareMessage = ""
    @State private var isLoading = false

    private let purpleColor = Color(hex: "#9B7EB8")

    var body: some View {
        Button {
            print("🔵 Invite button tapped")
            loadReferralData()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(purpleColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "gift.fill")
                        .font(.system(size: 18))
                        .foregroundColor(purpleColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Invite friends, earn rewards")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Text("Get $5 for each friend who uploads a bill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [purpleColor.opacity(0.08), purpleColor.opacity(0.03)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(purpleColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .sheet(isPresented: $showInviteSheet) {
            InviteOptionsSheet(
                referralCode: referralCode,
                shareMessage: shareMessage,
                onShare: {
                    showInviteSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showNativeShareSheet = true
                    }
                },
                onCopy: {
                    UIPasteboard.general.string = referralCode
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            )
            .presentationDetents([.height(380)])
            .presentationBackground(Color(hex: "#F5F7F6"))
        }
        .sheet(isPresented: $showNativeShareSheet) {
            NativeShareSheet(items: [shareMessage])
        }
    }

    private func loadReferralData() {
        print("🔵 loadReferralData() called")
        isLoading = true

        // Generate referral code and message
        if referralCode.isEmpty {
            referralCode = "BILLIX-\(String(UUID().uuidString.prefix(6)).uppercased())"
        }
        if shareMessage.isEmpty {
            shareMessage = "Join me on Billix and save money on your bills! Use my code: \(referralCode) to get started. Download now!"
        }

        print("🟢 Generated code: \(referralCode)")
        isLoading = false
        showInviteSheet = true
    }
}

// MARK: - Invite Options Sheet

private struct InviteOptionsSheet: View {
    let referralCode: String
    let shareMessage: String
    let onShare: () -> Void
    let onCopy: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var codeCopied = false

    private let purpleColor = Color(hex: "#9B7EB8")

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Invite Friends")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#CBD5E0"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Referral Code Display
            VStack(spacing: 8) {
                Text("Your Referral Code")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))

                Text(referralCode)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(purpleColor)
                    .tracking(2)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(purpleColor.opacity(0.08))
            )
            .padding(.horizontal, 20)

            // 500 Points Bonus Messaging
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#FFD700").opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#FFD700"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Invite 5 friends, earn 500 bonus points!")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))
                    Text("100 points per referral + 500 point bonus")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#FFD700").opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#FFD700").opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)

            // Action Buttons
            HStack(spacing: 12) {
                // Copy Code Button
                Button {
                    onCopy()
                    codeCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        codeCopied = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                        Text(codeCopied ? "Copied!" : "Copy Code")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(codeCopied ? .white : purpleColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(codeCopied ? Color.green : purpleColor.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)

                // Share Button
                Button {
                    onShare()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Share")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(purpleColor)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

// MARK: - Native Share Sheet

struct NativeShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
