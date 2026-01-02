//
//  SwapPaymentSheet.swift
//  Billix
//
//  Swap Payment Sheet for Bill Swap
//

import SwiftUI

struct SwapPaymentSheet: View {
    @ObservedObject var viewModel: SwapDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPaymentMethod: PaymentMethod = .applePay
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum PaymentMethod: String, CaseIterable {
        case applePay = "Apple Pay"
        case points = "Billix Points"

        var icon: String {
            switch self {
            case .applePay: return "apple.logo"
            case .points: return "star.fill"
            }
        }
    }

    private var feeAmount: String {
        SwapPaymentService.shared.formattedPrice(for: viewModel.swap.swapType)
    }

    private var pointsBalance: Int {
        PointsService.shared.currentBalance
    }

    private var canUsePoints: Bool {
        pointsBalance >= PointsConstants.feeWaiverCost
    }

    private var pointsNeeded: Int {
        PointsConstants.feeWaiverCost
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Fee summary
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.billixMoneyGreen)

                    Text("Pay Swap Fee")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(feeAmount)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color.billixMoneyGreen)

                    Text(viewModel.swap.swapType == .twoSided
                         ? "Two-sided swap fee"
                         : "One-sided assist fee")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Payment methods
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Method")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    // Apple Pay option
                    PaymentMethodCard(
                        method: .applePay,
                        isSelected: selectedPaymentMethod == .applePay,
                        subtitle: "Pay with Apple Pay",
                        isDisabled: false
                    )
                    .onTapGesture {
                        selectedPaymentMethod = .applePay
                    }

                    // Points option
                    PaymentMethodCard(
                        method: .points,
                        isSelected: selectedPaymentMethod == .points,
                        subtitle: canUsePoints
                            ? "Use \(pointsNeeded) points (Balance: \(pointsBalance))"
                            : "Need \(pointsNeeded - pointsBalance) more points",
                        isDisabled: !canUsePoints
                    )
                    .onTapGesture {
                        if canUsePoints {
                            selectedPaymentMethod = .points
                        }
                    }
                }

                Spacer()

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Label("Secure Payment", systemImage: "lock.shield")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Your payment is processed securely. Fees are non-refundable once the swap is locked.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)

                // Pay button
                Button {
                    processPayment()
                } label: {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            if selectedPaymentMethod == .applePay {
                                Image(systemName: "apple.logo")
                            } else {
                                Image(systemName: "star.fill")
                            }
                            Text(selectedPaymentMethod == .applePay
                                 ? "Pay \(feeAmount)"
                                 : "Use \(pointsNeeded) Points")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.billixMoneyGreen)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(isProcessing)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func processPayment() {
        isProcessing = true

        Task {
            do {
                if selectedPaymentMethod == .applePay {
                    try await viewModel.payFee()
                } else {
                    try await viewModel.waiveFeeWithPoints()
                }

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Payment Method Card

struct PaymentMethodCard: View {
    let method: SwapPaymentSheet.PaymentMethod
    let isSelected: Bool
    let subtitle: String
    let isDisabled: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: method.icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconBackground)
                .cornerRadius(10)

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(method.rawValue)
                    .font(.headline)
                    .foregroundColor(isDisabled ? .secondary : .primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isSelected ? Color.billixMoneyGreen : .gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.billixMoneyGreen : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .opacity(isDisabled ? 0.6 : 1)
        .padding(.horizontal)
    }

    private var iconColor: Color {
        switch method {
        case .applePay:
            return isDisabled ? .gray : .primary
        case .points:
            return isDisabled ? .gray : Color.billixGoldenAmber
        }
    }

    private var iconBackground: Color {
        switch method {
        case .applePay:
            return Color(UIColor.tertiarySystemBackground)
        case .points:
            return Color.billixGoldenAmber.opacity(0.2)
        }
    }
}

// MARK: - Points Balance View

struct PointsBalanceView: View {
    let balance: Int
    let needed: Int

    var progress: Double {
        min(1.0, Double(balance) / Double(needed))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Points Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(balance) / \(needed)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            ProgressView(value: progress)
                .tint(balance >= needed ? Color.green : Color.billixGoldenAmber)

            if balance < needed {
                Text("Earn \(needed - balance) more points to waive fees!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    SwapPaymentSheet(viewModel: SwapDetailViewModel(swap: BillSwap(
        id: UUID(),
        swapType: .twoSided,
        status: .acceptedPendingFee,
        initiatorUserId: UUID(),
        counterpartyUserId: UUID(),
        billAId: UUID(),
        billBId: nil,
        counterOfferAmountCents: nil,
        counterOfferByUserId: nil,
        feeAmountCentsInitiator: 99,
        feeAmountCentsCounterparty: 99,
        feePaidInitiator: false,
        feePaidCounterparty: false,
        pointsWaiverInitiator: false,
        pointsWaiverCounterparty: false,
        acceptDeadline: nil,
        proofDueDeadline: nil,
        createdAt: Date(),
        updatedAt: Date(),
        acceptedAt: Date(),
        lockedAt: nil,
        completedAt: nil,
        billA: nil,
        billB: nil,
        initiatorProfile: nil,
        counterpartyProfile: nil
    )))
}
