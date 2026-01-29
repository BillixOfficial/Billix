//
//  DealBuilderSheet.swift
//  Billix
//
//  Sheet for proposing or countering swap terms (Deal Builder)
//

import SwiftUI

struct DealBuilderSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DealBuilderViewModel

    // MARK: - Properties

    let swap: BillSwapTransaction
    let existingDeal: SwapDeal?
    let onDealProposed: (SwapDeal) -> Void

    // MARK: - State

    @State private var showingConfirmation = false

    // MARK: - Initialization

    init(
        swap: BillSwapTransaction,
        existingDeal: SwapDeal? = nil,
        onDealProposed: @escaping (SwapDeal) -> Void
    ) {
        self.swap = swap
        self.existingDeal = existingDeal
        self.onDealProposed = onDealProposed
        _viewModel = StateObject(wrappedValue: DealBuilderViewModel(
            swap: swap,
            existingDeal: existingDeal
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Payment Order
                    paymentOrderSection

                    // Amounts
                    amountsSection

                    // Deadlines
                    deadlinesSection

                    // Proof Required
                    proofRequiredSection

                    // Fallback Action
                    fallbackSection

                    // Summary Card Preview
                    if viewModel.isValid {
                        summaryPreview
                    }

                    // Submit Button
                    submitButton
                }
                .padding()
            }
            .background(Color.billixCreamBeige.ignoresSafeArea())
            .navigationTitle(existingDeal == nil ? "Propose Terms" : "Counter Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Confirm Terms", isPresented: $showingConfirmation) {
                Button("Send Proposal", role: .none) {
                    Task {
                        await submitDeal()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your partner will have 24 hours to accept, counter, or reject these terms.")
            }
            .overlay {
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 40))
                .foregroundColor(.billixMoneyGreen)

            Text(existingDeal == nil ? "Set Your Swap Terms" : "Modify & Counter")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.billixDarkTeal)

            Text("Both parties must agree to these terms before the swap activates.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let deal = existingDeal {
                HStack {
                    Text("Counter #\(deal.version + 1)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.billixGoldenAmber)
                        .cornerRadius(12)

                    Text("of 3 max")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }

    // MARK: - Payment Order Section

    private var paymentOrderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Who Pays First?", icon: "arrow.left.arrow.right")

            VStack(spacing: 8) {
                ForEach(PaymentOrder.allCases, id: \.self) { order in
                    PaymentOrderOptionRow(
                        order: order,
                        isSelected: viewModel.whoPaysFirst == order,
                        isUserA: swap.isUserA(userId: SupabaseService.shared.currentUserId ?? UUID())
                    ) {
                        viewModel.whoPaysFirst = order
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Amounts Section

    private var amountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Swap Amounts", icon: "dollarsign.circle")

            VStack(spacing: 16) {
                // User's amount
                AmountInputRow(
                    label: "You pay",
                    amount: viewModel.isUserA ? $viewModel.amountA : $viewModel.amountB,
                    color: .billixMoneyGreen
                )

                // Partner's amount
                AmountInputRow(
                    label: "Partner pays",
                    amount: viewModel.isUserA ? $viewModel.amountB : $viewModel.amountA,
                    color: .billixDarkTeal
                )

                // Difference indicator
                if viewModel.amountDifference != 0 {
                    HStack {
                        Image(systemName: viewModel.amountDifference > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(viewModel.amountDifference > 0 ? .billixMoneyGreen : .billixGoldenAmber)

                        Text("Difference: \(viewModel.formattedDifference)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Deadlines Section

    private var deadlinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Return Deadlines", icon: "calendar.badge.clock")

            VStack(spacing: 16) {
                // User's deadline
                DeadlinePickerRow(
                    label: "Your deadline",
                    date: viewModel.isUserA ? $viewModel.deadlineA : $viewModel.deadlineB,
                    minDate: Date()
                )

                // Partner's deadline
                DeadlinePickerRow(
                    label: "Partner's deadline",
                    date: viewModel.isUserA ? $viewModel.deadlineB : $viewModel.deadlineA,
                    minDate: Date()
                )

                // Quick presets
                HStack(spacing: 8) {
                    ForEach(["48h", "72h", "1 week"], id: \.self) { preset in
                        Button {
                            viewModel.applyDeadlinePreset(preset)
                        } label: {
                            Text(preset)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.billixCreamBeige)
                                .cornerRadius(8)
                        }
                        .foregroundColor(.billixDarkTeal)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Proof Required Section

    private var proofRequiredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Proof Required", icon: "checkmark.shield")

            VStack(spacing: 8) {
                ForEach(ProofType.allCases, id: \.self) { proofType in
                    ProofTypeOptionRow(
                        proofType: proofType,
                        isSelected: viewModel.proofRequired == proofType
                    ) {
                        viewModel.proofRequired = proofType
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Fallback Section

    private var fallbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("If Deadline Missed", icon: "exclamationmark.triangle")

            Text("What happens if either party misses their deadline?")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                ForEach(FallbackAction.allCases, id: \.self) { action in
                    FallbackOptionRow(
                        action: action,
                        isSelected: viewModel.fallbackIfLate == action
                    ) {
                        viewModel.fallbackIfLate = action
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Summary Preview

    private var summaryPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.billixDarkTeal)
                Text("Deal Preview")
                    .font(.headline)
                    .foregroundColor(.billixDarkTeal)
            }

            DealCardPreview(
                whoPaysFirst: viewModel.whoPaysFirst,
                amountA: viewModel.amountA,
                amountB: viewModel.amountB,
                deadlineA: viewModel.deadlineA,
                deadlineB: viewModel.deadlineB,
                proofRequired: viewModel.proofRequired,
                fallbackIfLate: viewModel.fallbackIfLate,
                isUserA: viewModel.isUserA
            )
        }
        .padding()
        .background(Color.billixDarkTeal.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            showingConfirmation = true
        } label: {
            HStack {
                Image(systemName: "paperplane.fill")
                Text(existingDeal == nil ? "Propose Terms" : "Send Counter")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                viewModel.isValid ? Color.billixMoneyGreen : Color.gray
            )
            .cornerRadius(16)
        }
        .disabled(!viewModel.isValid)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Sending proposal...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.billixDarkTeal)
            .cornerRadius(20)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.billixDarkTeal)
            Text(title)
                .font(.headline)
                .foregroundColor(.billixDarkTeal)
        }
    }

    // MARK: - Actions

    private func submitDeal() async {
        do {
            let deal = try await viewModel.submitDeal()
            onDealProposed(deal)
            dismiss()
        } catch {
            viewModel.error = error
        }
    }
}

// MARK: - Payment Order Option Row

private struct PaymentOrderOptionRow: View {
    let order: PaymentOrder
    let isSelected: Bool
    let isUserA: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .billixMoneyGreen : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(isSelected ? Color.billixMoneyGreen.opacity(0.1) : Color.billixCreamBeige.opacity(0.5))
            .cornerRadius(12)
        }
    }

    private var displayName: String {
        switch order {
        case .userAPaysFirst:
            return isUserA ? "You pay first" : "Partner pays first"
        case .userBPaysFirst:
            return isUserA ? "Partner pays first" : "You pay first"
        case .simultaneous:
            return "Simultaneous"
        }
    }

    private var description: String {
        switch order {
        case .userAPaysFirst, .userBPaysFirst:
            return "One party pays, then the other"
        case .simultaneous:
            return "Both pay at the same time"
        }
    }
}

// MARK: - Amount Input Row

private struct AmountInputRow: View {
    let label: String
    @Binding var amount: Decimal
    let color: Color

    @State private var amountText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("$")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                TextField("0.00", text: $amountText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .keyboardType(.decimalPad)
                    .foregroundColor(color)
                    .onChange(of: amountText) { _, newValue in
                        if let value = Decimal(string: newValue) {
                            amount = value
                        }
                    }
            }
            .padding()
            .background(Color.billixCreamBeige.opacity(0.5))
            .cornerRadius(12)
        }
        .onAppear {
            if amount > 0 {
                amountText = "\(amount)"
            }
        }
    }
}

// MARK: - Deadline Picker Row

private struct DeadlinePickerRow: View {
    let label: String
    @Binding var date: Date
    let minDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            DatePicker(
                "",
                selection: $date,
                in: minDate...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .padding()
            .background(Color.billixCreamBeige.opacity(0.5))
            .cornerRadius(12)
        }
    }
}

// MARK: - Proof Type Option Row

private struct ProofTypeOptionRow: View {
    let proofType: ProofType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .billixMoneyGreen : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text(proofType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(proofType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: proofType.icon)
                    .foregroundColor(isSelected ? .billixMoneyGreen : .gray)
            }
            .padding()
            .background(isSelected ? Color.billixMoneyGreen.opacity(0.1) : Color.billixCreamBeige.opacity(0.5))
            .cornerRadius(12)
        }
    }
}

// MARK: - Fallback Option Row

private struct FallbackOptionRow: View {
    let action: FallbackAction
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .billixGoldenAmber : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(action.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: action.icon)
                    .foregroundColor(isSelected ? .billixGoldenAmber : .gray)
            }
            .padding()
            .background(isSelected ? Color.billixGoldenAmber.opacity(0.1) : Color.billixCreamBeige.opacity(0.5))
            .cornerRadius(12)
        }
    }
}

// MARK: - Deal Card Preview

private struct DealCardPreview: View {
    let whoPaysFirst: PaymentOrder
    let amountA: Decimal
    let amountB: Decimal
    let deadlineA: Date
    let deadlineB: Date
    let proofRequired: ProofType
    let fallbackIfLate: FallbackAction
    let isUserA: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Amounts
            HStack {
                VStack(alignment: .leading) {
                    Text("You pay")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatAmount(isUserA ? amountA : amountB))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.billixMoneyGreen)
                }

                Spacer()

                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(.billixDarkTeal)

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Partner pays")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatAmount(isUserA ? amountB : amountA))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.billixDarkTeal)
                }
            }

            Divider()

            // Details grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                DealDetailPill(icon: "arrow.right", text: whoPaysFirst.displayName)
                DealDetailPill(icon: "calendar", text: formatDeadline(isUserA ? deadlineA : deadlineB))
                DealDetailPill(icon: proofRequired.icon, text: proofRequired.displayName)
                DealDetailPill(icon: fallbackIfLate.icon, text: fallbackIfLate.shortName)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }

    private func formatDeadline(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct DealDetailPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundColor(.billixDarkTeal)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.billixCreamBeige)
        .cornerRadius(8)
    }
}

// MARK: - Deal Builder ViewModel

@MainActor
class DealBuilderViewModel: ObservableObject {
    // MARK: - Properties

    let swap: BillSwapTransaction
    let existingDeal: SwapDeal?

    @Published var whoPaysFirst: PaymentOrder = .simultaneous
    @Published var amountA: Decimal = 0
    @Published var amountB: Decimal = 0
    @Published var deadlineA: Date = Date().addingTimeInterval(48 * 3600)
    @Published var deadlineB: Date = Date().addingTimeInterval(48 * 3600)
    @Published var proofRequired: ProofType = .screenshot
    @Published var fallbackIfLate: FallbackAction = .trustPointPenalty

    @Published var isLoading = false
    @Published var error: Error?

    var isUserA: Bool {
        swap.isUserA(userId: SupabaseService.shared.currentUserId ?? UUID())
    }

    // MARK: - Initialization

    init(swap: BillSwapTransaction, existingDeal: SwapDeal?) {
        self.swap = swap
        self.existingDeal = existingDeal

        // Pre-populate from existing deal if countering
        if let deal = existingDeal {
            whoPaysFirst = deal.whoPaysFirst
            amountA = deal.amountA
            amountB = deal.amountB
            deadlineA = deal.deadlineA
            deadlineB = deal.deadlineB
            proofRequired = deal.proofRequired
            fallbackIfLate = deal.fallbackIfLate
        }
    }

    // MARK: - Computed Properties

    var isValid: Bool {
        amountA > 0 && amountB > 0 &&
        deadlineA > Date() && deadlineB > Date()
    }

    var amountDifference: Decimal {
        let myAmount = isUserA ? amountA : amountB
        let partnerAmount = isUserA ? amountB : amountA
        return myAmount - partnerAmount
    }

    var formattedDifference: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let diff = abs(amountDifference)
        return formatter.string(from: NSDecimalNumber(decimal: diff)) ?? "$0.00"
    }

    // MARK: - Actions

    func applyDeadlinePreset(_ preset: String) {
        let hours: Int
        switch preset {
        case "48h": hours = 48
        case "72h": hours = 72
        case "1 week": hours = 168
        default: hours = 48
        }

        let newDeadline = Date().addingTimeInterval(Double(hours) * 3600)
        deadlineA = newDeadline
        deadlineB = newDeadline
    }

    func submitDeal() async throws -> SwapDeal {
        isLoading = true
        defer { isLoading = false }

        let terms = DealTermsInput(
            whoPaysFirst: whoPaysFirst,
            amountA: amountA,
            amountB: amountB,
            deadlineA: deadlineA,
            deadlineB: deadlineB,
            proofRequired: proofRequired,
            fallbackIfLate: fallbackIfLate
        )

        if let existing = existingDeal {
            // Counter the existing deal
            return try await DealService.shared.counterDeal(
                dealId: existing.id,
                newTerms: terms
            )
        } else {
            // Propose new deal
            return try await DealService.shared.proposeDeal(
                swapId: swap.id,
                terms: terms
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    DealBuilderSheet(
        swap: BillSwapTransaction.mockActiveSwap(userAId: UUID(), userBId: UUID()),
        existingDeal: nil
    ) { _ in }
}
#endif
