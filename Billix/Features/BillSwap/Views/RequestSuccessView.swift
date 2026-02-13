//
//  RequestSuccessView.swift
//  Billix
//
//  Success screen after uploading a bill - allows user to select connection type
//

import SwiftUI

struct RequestSuccessView: View {
    let bill: SupportBill
    let onComplete: () -> Void

    @State private var selectedType: ConnectionType?
    @State private var isCreatingConnection = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var animateCheckmark = false
    @State private var animateContent = false
    @State private var tokenBalance: Int = 0
    @State private var showUpgradeView = false
    @State private var showIDVerificationSheet = false
    @State private var currentTier: ReputationTier = .neighbor
    @State private var monthlyLimit: Int = 1

    private let accentColor = Color(hex: "#5B8A6B")
    private let cardBackground = Color.white
    private let primaryText = Color(hex: "#2D3B35")
    private let secondaryText = Color(hex: "#8B9A94")

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "#F0F7F4"),
                    Color(hex: "#E8F5E9").opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Animated success header
                    successHeader
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    // Bill summary card
                    billSummaryCard
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    // Connection type selection
                    connectionTypeSection
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    // Confirm button
                    confirmButton
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
            }
        }
        .onAppear {
            loadTokenBalance()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateCheckmark = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                animateContent = true
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showUpgradeView) {
            UpgradeMembershipView(
                currentTier: currentTier,
                monthlyLimit: monthlyLimit,
                onDismiss: {
                    showUpgradeView = false
                },
                onUpgrade: {
                    navigateToVerification()
                }
            )
        }
        .sheet(isPresented: $showIDVerificationSheet) {
            IDVerificationView(onVerificationComplete: {
                // User submitted verification - dismiss sheet
                // They'll need to wait for approval before posting
                showIDVerificationSheet = false
            })
        }
    }

    // MARK: - Success Header

    private var successHeader: some View {
        VStack(spacing: 16) {
            // Animated checkmark circle
            ZStack {
                // Outer ring
                Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 100, height: 100)

                // Animated fill circle
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(animateCheckmark ? 1 : 0)

                // Checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(accentColor)
                    .scaleEffect(animateCheckmark ? 1 : 0)
                    .rotationEffect(.degrees(animateCheckmark ? 0 : -90))

                // Sparkles
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(accentColor)
                        .frame(width: 8, height: 8)
                        .offset(y: -60)
                        .rotationEffect(.degrees(Double(index) * 60))
                        .scaleEffect(animateCheckmark ? 1 : 0)
                        .opacity(animateCheckmark ? 0.6 : 0)
                }
            }

            VStack(spacing: 8) {
                Text("Bill Uploaded!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(primaryText)

                Text("Now choose how you'd like to connect")
                    .font(.system(size: 15))
                    .foregroundColor(secondaryText)
            }
        }
    }

    // MARK: - Bill Summary Card

    private var billSummaryCard: some View {
        HStack(spacing: 16) {
            // Category icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 50, height: 50)

                Image(systemName: categoryIcon)
                    .font(.system(size: 22))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(bill.providerName ?? "Bill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)

                Text(bill.category?.displayName ?? "Utility")
                    .font(.system(size: 13))
                    .foregroundColor(secondaryText)
            }

            Spacer()

            Text(formattedAmount)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(accentColor)
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    // MARK: - Connection Type Section

    private var connectionTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Choose your support type")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryText)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "coins")
                        .font(.system(size: 12))
                    Text("\(tokenBalance) tokens")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(secondaryText)
            }

            // Mutual Support Card
            ConnectionTypeCard(
                type: .mutual,
                icon: "arrow.left.arrow.right",
                title: "Mutual Support",
                description: "Help others & get help back. Build community karma!",
                tokenCost: 1,
                isSelected: selectedType == .mutual,
                accentColor: accentColor
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedType = .mutual
                }
            }

            // One-Way Support Card
            ConnectionTypeCard(
                type: .oneWay,
                icon: "hand.raised.fill",
                title: "One-Way Support",
                description: "Just need help this time. No obligation to help back.",
                tokenCost: 1,
                isSelected: selectedType == .oneWay,
                accentColor: Color(hex: "#E8A54B")
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedType = .oneWay
                }
            }
        }
    }

    // MARK: - Confirm Button

    @ViewBuilder
    private var confirmButton: some View {
        VStack(spacing: 0) {
            Button {
                Task {
                    await createConnection()
                }
            } label: {
                HStack(spacing: 10) {
                    if isCreatingConnection {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "megaphone.fill")
                            .font(.system(size: 16))
                        Text("Post to Community Board")
                            .font(.system(size: 16, weight: .semibold))

                        if selectedType != nil {
                            Text("• 1 token")
                                .font(.system(size: 14, weight: .medium))
                                .opacity(0.8)
                        }
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    selectedType != nil ? accentColor : secondaryText.opacity(0.5)
                )
                .cornerRadius(14)
                .shadow(color: (selectedType != nil ? accentColor : Color.clear).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(selectedType == nil || isCreatingConnection || tokenBalance < 1)

            // Insufficient tokens warning
            if tokenBalance < 1 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text("Not enough tokens to post")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(hex: "#E07A6B"))
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Helpers

    private var categoryIcon: String {
        bill.category?.icon ?? "doc.text.fill"
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: bill.amount as NSDecimalNumber) ?? "$\(bill.amount)"
    }

    @MainActor
    private func loadTokenBalance() {
        tokenBalance = TokenService.shared.tokenBalance
    }

    private func createConnection() async {
        guard let connectionType = selectedType else { return }

        isCreatingConnection = true

        do {
            // Create connection with selected type (this charges the token)
            _ = try await ConnectionService.shared.createRequest(
                bill: bill,
                connectionType: connectionType
            )

            // Success - close the flow
            await MainActor.run {
                onComplete()
            }
        } catch let error as ConnectionError {
            await MainActor.run {
                isCreatingConnection = false

                switch error {
                case .velocityLimitReached(let limit, let tier):
                    // Show upgrade view for velocity limit errors
                    currentTier = tier
                    monthlyLimit = limit
                    showUpgradeView = true
                case .idVerificationRequired:
                    // Show ID verification view instead of alert
                    showIDVerificationSheet = true
                default:
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isCreatingConnection = false
            }
        }
    }

    private func navigateToVerification() {
        // Dismiss upgrade view and navigate to verification
        showUpgradeView = false
        // TODO: Navigate to verification flow
        onComplete()
    }
}

// MARK: - Connection Type Card

struct ConnectionTypeCard: View {
    let type: ConnectionType
    let icon: String
    let title: String
    let description: String
    let tokenCost: Int
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? accentColor.opacity(0.15) : Color(hex: "#F5F5F5"))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? accentColor : Color(hex: "#8B9A94"))
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        Spacer()

                        // Token cost badge
                        HStack(spacing: 4) {
                            Image(systemName: "coins")
                                .font(.system(size: 10))
                            Text("\(tokenCost)")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(isSelected ? accentColor : Color(hex: "#8B9A94"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isSelected ? accentColor.opacity(0.1) : Color(hex: "#F5F5F5"))
                        .cornerRadius(8)
                    }

                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8B9A94"))
                        .lineLimit(2)
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.04), radius: isSelected ? 12 : 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct RequestSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        RequestSuccessView(
        bill: SupportBill(
        id: UUID(),
        userId: UUID(),
        amount: 9.00,
        dueDate: Date(),
        providerName: "Rutgers University",
        category: .electric,
        status: .posted
        ),
        onComplete: {}
        )
    }
}
