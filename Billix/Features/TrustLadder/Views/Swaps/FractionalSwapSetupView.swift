//
//  FractionalSwapSetupView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  View for setting up fractional and multi-party swaps
//

import SwiftUI

struct FractionalSwapSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var swapService = MultiPartySwapService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared

    // Form state
    @State private var selectedSwapType: SwapType = .fractional
    @State private var targetAmount: String = ""
    @State private var minContribution: String = ""
    @State private var maxParticipants: Int = 3
    @State private var selectedCategory: ReceiptBillCategory = .electricity
    @State private var providerName: String = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(7 * 24 * 3600)

    // UI state
    @State private var showCategoryPicker = false
    @State private var isCreating = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var createdSwap: MultiPartySwap?

    // Theme colors
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationView {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Swap type selector
                        swapTypeSelector

                        // Feature requirement info
                        if !hasAccess {
                            featureLockedCard
                        }

                        // Form fields
                        if hasAccess {
                            formFields
                        }

                        // Preview card
                        if hasAccess && isFormValid {
                            swapPreviewCard
                        }

                        // Create button
                        if hasAccess {
                            createButton
                        }

                        // Error message
                        if let error = errorMessage {
                            errorBanner(error)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Create Swap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(secondaryText)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                ReceiptCategoryPickerSheet(selectedCategory: $selectedCategory)
            }
            .sheet(isPresented: $showSuccess) {
                SwapCreatedSuccessView(swap: createdSwap) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var hasAccess: Bool {
        subscriptionService.hasAccess(to: selectedSwapType.requiredFeature)
    }

    private var targetAmountDecimal: Decimal {
        Decimal(string: targetAmount) ?? 0
    }

    private var minContributionDecimal: Decimal {
        Decimal(string: minContribution) ?? 0
    }

    private var isFormValid: Bool {
        targetAmountDecimal > 0 &&
        minContributionDecimal > 0 &&
        minContributionDecimal <= targetAmountDecimal &&
        maxParticipants >= 2
    }

    // MARK: - Swap Type Selector

    private var swapTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Swap Type")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(secondaryText)

            HStack(spacing: 10) {
                ForEach([SwapType.fractional, .multiParty], id: \.self) { type in
                    swapTypeButton(type)
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func swapTypeButton(_ type: SwapType) -> some View {
        let isSelected = selectedSwapType == type
        let hasTypeAccess = subscriptionService.hasAccess(to: type.requiredFeature)

        return Button {
            selectedSwapType = type
        } label: {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .black : type.color)

                Text(type.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .black : primaryText)

                if !hasTypeAccess {
                    HStack(spacing: 2) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                        Text(type.requiredTier.displayName)
                            .font(.system(size: 9))
                    }
                    .foregroundColor(isSelected ? .black.opacity(0.6) : secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? type.color : cardBg.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : type.color.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Feature Locked Card

    private var featureLockedCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 36))
                .foregroundColor(selectedSwapType.color)

            VStack(spacing: 4) {
                Text("\(selectedSwapType.displayName) Swaps")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(primaryText)

                Text(selectedSwapType.description)
                    .font(.system(size: 13))
                    .foregroundColor(secondaryText)
                    .multilineTextAlignment(.center)
            }

            Text("Requires \(selectedSwapType.requiredTier.displayName)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(selectedSwapType.requiredTier.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedSwapType.requiredTier.color.opacity(0.15))
                .cornerRadius(8)

            NavigationLink {
                PaywallView(context: .featureGate(selectedSwapType.requiredFeature))
            } label: {
                Text("Upgrade Now")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(selectedSwapType.color)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: - Form Fields

    private var formFields: some View {
        VStack(spacing: 16) {
            // Target amount
            formField(
                title: "Target Amount",
                icon: "dollarsign.circle"
            ) {
                HStack {
                    Text("$")
                        .foregroundColor(secondaryText)
                    TextField("0.00", text: $targetAmount)
                        .keyboardType(.decimalPad)
                        .foregroundColor(primaryText)
                }
            }

            // Minimum contribution
            formField(
                title: "Minimum Contribution",
                icon: "chart.pie"
            ) {
                HStack {
                    Text("$")
                        .foregroundColor(secondaryText)
                    TextField("0.00", text: $minContribution)
                        .keyboardType(.decimalPad)
                        .foregroundColor(primaryText)
                }
            }

            // Suggested contributions
            if targetAmountDecimal > 0 {
                suggestedContributions
            }

            // Max participants
            formField(
                title: "Maximum Participants",
                icon: "person.3"
            ) {
                Stepper("\(maxParticipants)", value: $maxParticipants, in: 2...10)
                    .foregroundColor(primaryText)
            }

            // Category
            formField(
                title: "Bill Category",
                icon: selectedCategory.icon
            ) {
                Button {
                    showCategoryPicker = true
                } label: {
                    HStack {
                        Text(selectedCategory.displayName)
                            .foregroundColor(primaryText)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(secondaryText)
                    }
                }
            }

            // Provider (optional)
            formField(
                title: "Provider Name (Optional)",
                icon: "building.2"
            ) {
                TextField("e.g., Electric Company", text: $providerName)
                    .foregroundColor(primaryText)
            }

            // Deadline toggle
            Toggle(isOn: $hasDeadline) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(accent)
                    Text("Set Deadline")
                        .font(.system(size: 14))
                        .foregroundColor(primaryText)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: accent))
            .padding()
            .background(cardBg)
            .cornerRadius(12)

            // Deadline picker
            if hasDeadline {
                formField(
                    title: "Deadline",
                    icon: "calendar"
                ) {
                    DatePicker("", selection: $deadline, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
        }
    }

    private func formField<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(accent)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryText)
            }

            content()
                .padding()
                .background(background)
                .cornerRadius(10)
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Suggested Contributions

    private var suggestedContributions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested Contributions")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(secondaryText)

            HStack(spacing: 8) {
                ForEach(ContributionOption.options(for: targetAmountDecimal)) { option in
                    Button {
                        minContribution = "\(option.amount)"
                    } label: {
                        VStack(spacing: 4) {
                            Text(option.displayPercentage)
                                .font(.system(size: 12, weight: .bold))
                            Text(option.formattedAmount)
                                .font(.system(size: 10))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(minContributionDecimal == option.amount ? accent : background)
                        .foregroundColor(minContributionDecimal == option.amount ? .black : primaryText)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Preview Card

    private var swapPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(accent)
                Text("Swap Preview")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)
            }

            VStack(spacing: 8) {
                previewRow("Target Amount", value: formatCurrency(targetAmountDecimal))
                previewRow("Min. Contribution", value: formatCurrency(minContributionDecimal))
                previewRow("Max. Participants", value: "\(maxParticipants)")
                previewRow("Category", value: selectedCategory.displayName)
                if hasDeadline {
                    previewRow("Deadline", value: deadline.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.3), lineWidth: 1)
        )
    }

    private func previewRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(primaryText)
        }
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            createSwap()
        } label: {
            HStack {
                if isCreating {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "plus.circle.fill")
                    Text("Create \(selectedSwapType.displayName) Swap")
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isFormValid ? accent : secondaryText)
            .cornerRadius(14)
        }
        .disabled(!isFormValid || isCreating)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.red)

            Spacer()

            Button {
                errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.red.opacity(0.15))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func createSwap() {
        isCreating = true
        errorMessage = nil

        Task {
            do {
                let request = FractionalSwapRequest(
                    targetBillId: nil,
                    targetAmount: targetAmountDecimal,
                    minContribution: minContributionDecimal,
                    maxParticipants: maxParticipants,
                    executionDeadline: hasDeadline ? deadline : nil,
                    category: selectedCategory,
                    providerName: providerName.isEmpty ? nil : providerName
                )

                let swap = try await swapService.createFractionalSwap(request: request)
                createdSwap = swap
                showSuccess = true

            } catch {
                errorMessage = error.localizedDescription
            }

            isCreating = false
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }
}

// MARK: - Receipt Category Picker Sheet

struct ReceiptCategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: ReceiptBillCategory

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let primaryText = Color.white

    var body: some View {
        NavigationView {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(ReceiptBillCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                                dismiss()
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(category.color)

                                    Text(category.displayName)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(primaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(selectedCategory == category ? category.color.opacity(0.2) : cardBg)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedCategory == category ? category.color : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Swap Created Success View

struct SwapCreatedSuccessView: View {
    let swap: MultiPartySwap?
    let onDismiss: () -> Void

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Success animation
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(accent)

                VStack(spacing: 8) {
                    Text("Swap Created!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(primaryText)

                    Text("Your swap is now live and accepting participants")
                        .font(.system(size: 14))
                        .foregroundColor(secondaryText)
                        .multilineTextAlignment(.center)
                }

                // Swap details
                if let swap = swap {
                    VStack(spacing: 12) {
                        detailRow("Target", value: swap.formattedTargetAmount)
                        detailRow("Status", value: swap.swapStatus?.displayName ?? "Recruiting")
                        detailRow("Max Participants", value: "\(swap.maxParticipants)")
                    }
                    .padding()
                    .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                    .cornerRadius(16)
                }

                Spacer()

                // Done button
                Button {
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accent)
                        .cornerRadius(14)
                }
            }
            .padding(24)
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(primaryText)
        }
    }
}

// MARK: - Preview

#Preview {
    FractionalSwapSetupView()
        .preferredColorScheme(.dark)
}
