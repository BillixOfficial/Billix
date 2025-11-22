import SwiftUI

struct InviteScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TodayViewModel()

    @State private var showCopiedAlert = false

    var body: some View {
        ZStack {
            Color.billixLightGreen.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                InviteScreenHeader(dismiss: dismiss)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Hero Section
                        InviteHeroCard()
                            .padding(.horizontal, 18)
                            .padding(.top, 11)

                        // Your Code Card
                        YourInviteCodeCard(
                            inviteCode: viewModel.userInviteCode,
                            showCopiedAlert: $showCopiedAlert
                        )
                        .padding(.horizontal, 18)

                        // Stats Card
                        InviteStatsCard()
                            .padding(.horizontal, 18)

                        // How It Works
                        HowItWorksCard()
                            .padding(.horizontal, 18)

                        // Share Buttons
                        ShareButtonsSection(inviteCode: viewModel.userInviteCode)
                            .padding(.horizontal, 18)
                            .padding(.bottom, 24)
                    }
                }
            }

            // Copied Toast
            if showCopiedAlert {
                VStack {
                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.billixMoneyGreen)
                        Text("Code copied!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.billixDarkGray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 32)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Header

struct InviteScreenHeader: View {
    let dismiss: DismissAction

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGray)
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Invite & Earn")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.billixDarkGray)

                Text("Get rewards for referrals")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.billixDarkGray.opacity(0.6))
            }

            Spacer()

            Text("🎁")
                .font(.system(size: 28))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.billixLightGreen)
    }
}

// MARK: - Hero Card

struct InviteHeroCard: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("🎉")
                .font(.system(size: 64))

            Text("Share Billix, Earn Together")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.billixDarkGray)
                .multilineTextAlignment(.center)

            Text("Invite friends and you both get rewards when they join and upload their first bill.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.billixDarkGray.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 12)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.billixStarGold.opacity(0.15),
                    Color.billixStarGold.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.billixStarGold.opacity(0.3), lineWidth: 1.5)
        )
    }
}

// MARK: - Your Code Card

struct YourInviteCodeCard: View {
    let inviteCode: String
    @Binding var showCopiedAlert: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Invite Code")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.billixDarkGray.opacity(0.7))

                Spacer()
            }

            // Code Display
            HStack(spacing: 12) {
                Text(inviteCode)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.billixLoginTeal)
                    .tracking(2)

                Spacer()

                Button {
                    UIPasteboard.general.string = inviteCode

                    // Show toast
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showCopiedAlert = true
                    }

                    // Hide toast after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showCopiedAlert = false
                        }
                    }

                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                        Text("Copy")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.billixLoginTeal)
                    .cornerRadius(10)
                }
            }
            .padding(18)
            .background(Color.billixLightGreen)
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Stats Card

struct InviteStatsCard: View {
    // Mock data - would come from API in production
    let totalInvites = 8
    let pendingRewards = 150
    let earnedRewards = 320

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Your Referral Stats")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.billixDarkGray.opacity(0.7))

                Spacer()
            }

            HStack(spacing: 14) {
                // Total Invites
                StatBox(
                    icon: "person.2.fill",
                    value: "\(totalInvites)",
                    label: "Friends",
                    color: .billixLoginTeal
                )

                // Pending
                StatBox(
                    icon: "clock.fill",
                    value: "$\(pendingRewards)",
                    label: "Pending",
                    color: .billixPendingOrange
                )

                // Earned
                StatBox(
                    icon: "star.fill",
                    value: "$\(earnedRewards)",
                    label: "Earned",
                    color: .billixStarGold
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }
}

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.15))
                .cornerRadius(10)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.billixDarkGray)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.billixDarkGray.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.billixLightGreen)
        .cornerRadius(12)
    }
}

// MARK: - How It Works

struct HowItWorksCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("How It Works")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.billixDarkGray.opacity(0.7))

                Spacer()
            }

            VStack(spacing: 16) {
                HowItWorksStep(
                    number: "1",
                    title: "Share your code",
                    description: "Send your unique invite code to friends"
                )

                HowItWorksStep(
                    number: "2",
                    title: "They sign up",
                    description: "Friend creates account using your code"
                )

                HowItWorksStep(
                    number: "3",
                    title: "You both earn",
                    description: "Get $20 each when they upload first bill"
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }
}

struct HowItWorksStep: View {
    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Number Badge
            Text(number)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.billixLoginTeal)
                .cornerRadius(16)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.billixDarkGray)

                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.billixDarkGray.opacity(0.6))
                    .lineSpacing(2)
            }

            Spacer()
        }
    }
}

// MARK: - Share Buttons

struct ShareButtonsSection: View {
    let inviteCode: String

    private var shareMessage: String {
        "Join me on Billix and let's save on bills together! Use my code \(inviteCode) when you sign up and we both get $20. Download: https://billix.app"
    }

    var body: some View {
        VStack(spacing: 12) {
            ShareButton(
                icon: "square.and.arrow.up",
                title: "Share via...",
                color: .billixLoginTeal
            ) {
                shareViaSheet()
            }

            HStack(spacing: 12) {
                ShareButton(
                    icon: "message.fill",
                    title: "Message",
                    color: .billixMoneyGreen
                ) {
                    shareViaMessages()
                }

                ShareButton(
                    icon: "envelope.fill",
                    title: "Email",
                    color: .billixPendingOrange
                ) {
                    shareViaEmail()
                }
            }
        }
    }

    private func shareViaSheet() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [shareMessage],
            applicationActivities: nil
        )

        rootVC.present(activityVC, animated: true)
    }

    private func shareViaMessages() {
        let sms = "sms:&body=\(shareMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: sms) {
            UIApplication.shared.open(url)
        }
    }

    private func shareViaEmail() {
        let subject = "Join Billix and Save Together!"
        let body = shareMessage
        let mailto = "mailto:?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: mailto) {
            UIApplication.shared.open(url)
        }
    }
}

struct ShareButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))

                Text(title)
                    .font(.system(size: 15, weight: .semibold))

                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(color)
            .cornerRadius(14)
        }
    }
}

#Preview {
    InviteScreen()
}
