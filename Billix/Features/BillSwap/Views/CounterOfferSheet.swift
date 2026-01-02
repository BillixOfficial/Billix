//
//  CounterOfferSheet.swift
//  Billix
//
//  Counter Offer Sheet for Bill Swap
//

import SwiftUI

struct CounterOfferSheet: View {
    @ObservedObject var viewModel: SwapDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedBillId: UUID?
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""

    let availableBills: [SwapBill]

    private var canSubmit: Bool {
        selectedBillId != nil && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header info
                VStack(alignment: .leading, spacing: 8) {
                    Label("Counter with Your Bill", systemImage: "arrow.left.arrow.right")
                        .font(.headline)

                    Text("Select one of your bills to offer in exchange for this swap.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.billixCreamBeige.opacity(0.5))

                if availableBills.isEmpty {
                    // No bills available
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))

                        Text("No Bills Available")
                            .font(.headline)

                        Text("You need to create a bill first before you can make a counter offer.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                    .frame(maxHeight: .infinity)
                } else {
                    // Bill selection list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(availableBills) { bill in
                                BillSelectionCard(
                                    bill: bill,
                                    isSelected: selectedBillId == bill.id
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if selectedBillId == bill.id {
                                            selectedBillId = nil
                                        } else {
                                            selectedBillId = bill.id
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Counter Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitCounterOffer()
                    }
                    .disabled(!canSubmit)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isSubmitting {
                    ProgressView("Submitting...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
        }
    }

    private func submitCounterOffer() {
        guard let billId = selectedBillId else { return }

        isSubmitting = true

        Task {
            do {
                try await viewModel.acceptSwap(withBillId: billId)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Bill Selection Card

struct BillSelectionCard: View {
    let bill: SwapBill
    let isSelected: Bool

    var body: some View {
        HStack {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isSelected ? Color.billixMoneyGreen : .gray)

            // Bill icon
            Image(systemName: bill.category.icon)
                .font(.title3)
                .foregroundColor(Color.billixDarkTeal)
                .frame(width: 36, height: 36)
                .background(Color.billixDarkTeal.opacity(0.1))
                .cornerRadius(8)

            // Bill info
            VStack(alignment: .leading, spacing: 2) {
                Text(bill.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    if let provider = bill.providerName {
                        Text(provider)
                    }
                    Text("Due \(bill.formattedDueDate)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Amount
            Text(bill.formattedAmount)
                .font(.headline)
                .foregroundColor(Color.billixMoneyGreen)
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
    }
}

#Preview {
    CounterOfferSheet(
        viewModel: SwapDetailViewModel(swap: BillSwap(
            id: UUID(),
            swapType: .twoSided,
            status: .offered,
            initiatorUserId: UUID(),
            counterpartyUserId: nil,
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
            acceptDeadline: Date().addingTimeInterval(24 * 3600),
            proofDueDeadline: nil,
            createdAt: Date(),
            updatedAt: Date(),
            acceptedAt: nil,
            lockedAt: nil,
            completedAt: nil,
            billA: nil,
            billB: nil,
            initiatorProfile: nil,
            counterpartyProfile: nil
        )),
        availableBills: [
            SwapBill(
                id: UUID(),
                ownerUserId: UUID(),
                title: "Electric Bill",
                category: .electric,
                providerName: "PG&E",
                amountCents: 12500,
                dueDate: Date().addingTimeInterval(7 * 24 * 3600),
                status: .active,
                paymentUrl: nil,
                accountNumberLast4: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    )
}
