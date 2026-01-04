//
//  PortfolioSetupView.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Setup flow for adding bills and payday schedule
//

import SwiftUI

// MARK: - Theme

private enum Theme {
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let accent = Color(hex: "#5B8A6B")
    static let accentLight = Color(hex: "#5B8A6B").opacity(0.1)
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 20
}

// MARK: - Portfolio Setup View

struct PortfolioSetupView: View {
    @StateObject private var viewModel = PortfolioSetupViewModel()
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: viewModel.progress)
                        .tint(Theme.accent)
                        .padding(.horizontal, Theme.padding)
                        .padding(.top, 8)

                    // Step header
                    VStack(spacing: 8) {
                        Text(viewModel.currentStep.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.primaryText)

                        Text(viewModel.currentStep.subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, Theme.padding)

                    // Step content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            switch viewModel.currentStep {
                            case .payday:
                                paydayStepContent
                            case .bills:
                                billsStepContent
                            case .review:
                                reviewStepContent
                            }
                        }
                        .padding(Theme.padding)
                        .padding(.bottom, 100)
                    }

                    Spacer()

                    // Bottom buttons
                    bottomButtons
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.currentStep != .payday {
                        Button("Back") {
                            viewModel.previousStep()
                        }
                        .foregroundColor(Theme.accent)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.secondaryText)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onChange(of: viewModel.isComplete) { _, complete in
                if complete {
                    onComplete?()
                    dismiss()
                }
            }
            .task {
                await viewModel.loadExistingData()
            }
        }
    }

    // MARK: - Payday Step

    private var paydayStepContent: some View {
        VStack(spacing: 20) {
            // Payday type selector
            VStack(alignment: .leading, spacing: 12) {
                Text("How often do you get paid?")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                ForEach(PaydayType.allCases) { type in
                    PaydayTypeRow(
                        type: type,
                        isSelected: viewModel.selectedPaydayType == type,
                        onSelect: { viewModel.selectedPaydayType = type }
                    )
                }
            }

            Divider()

            // Day selection
            VStack(alignment: .leading, spacing: 12) {
                Text(paydayDaySelectionTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                paydayDaySelector
            }
        }
    }

    private var paydayDaySelectionTitle: String {
        switch viewModel.selectedPaydayType {
        case .weekly, .biweekly:
            return "What day of the week?"
        case .semiMonthly:
            return "Select two days of the month"
        case .monthly:
            return "What day of the month?"
        }
    }

    @ViewBuilder
    private var paydayDaySelector: some View {
        switch viewModel.selectedPaydayType {
        case .weekly, .biweekly:
            weekdayPicker
        case .semiMonthly, .monthly:
            monthDayPicker
        }
    }

    private var weekdayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.weekdayOptions, id: \.value) { option in
                    Button {
                        viewModel.selectedWeekday = option.value
                        haptic()
                    } label: {
                        Text(String(option.name.prefix(3)))
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 50, height: 44)
                            .background(viewModel.selectedWeekday == option.value ? Theme.accent : Theme.cardBackground)
                            .foregroundColor(viewModel.selectedWeekday == option.value ? .white : Theme.primaryText)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4)
                    }
                }
            }
        }
    }

    private var monthDayPicker: some View {
        let maxSelections = viewModel.selectedPaydayType == .semiMonthly ? 2 : 1

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(viewModel.monthDayOptions, id: \.self) { day in
                let isSelected = viewModel.selectedMonthDays.contains(day)

                Button {
                    if isSelected {
                        viewModel.selectedMonthDays.removeAll { $0 == day }
                    } else if viewModel.selectedMonthDays.count < maxSelections {
                        viewModel.selectedMonthDays.append(day)
                    } else if maxSelections == 1 {
                        viewModel.selectedMonthDays = [day]
                    }
                    haptic()
                } label: {
                    Text("\(day)")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 40, height: 40)
                        .background(isSelected ? Theme.accent : Theme.cardBackground)
                        .foregroundColor(isSelected ? .white : Theme.primaryText)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.03), radius: 2)
                }
            }
        }
    }

    // MARK: - Bills Step

    private var billsStepContent: some View {
        VStack(spacing: 24) {
            // Added bills
            if !viewModel.addedBills.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your bills (\(viewModel.addedBills.count))")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.primaryText)

                    ForEach(viewModel.addedBills) { bill in
                        AddedBillRow(bill: bill) {
                            Task { await viewModel.removeBill(bill) }
                        }
                    }
                }
            }

            Divider()

            // Add new bill form
            VStack(alignment: .leading, spacing: 16) {
                Text("Add a bill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                // Category selection
                Text("Bill type")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.secondaryText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.availableCategories) { category in
                            CategoryChip(
                                category: category,
                                isSelected: viewModel.selectedCategory == category,
                                onSelect: { viewModel.selectCategory(category) }
                            )
                        }
                    }
                }

                if let category = viewModel.selectedCategory {
                    // Provider name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Provider name")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.secondaryText)

                        TextField("", text: $viewModel.billProviderName, prompt: Text("e.g., Netflix").foregroundColor(Color(hex: "#9CA8A2")))
                            .textFieldStyle(RoundedTextFieldStyle())
                    }

                    // Amount
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Amount")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.secondaryText)
                            Spacer()
                            Text("Max: $\(Int(category.tier.maxAmount))")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.accent)
                        }

                        TextField("", text: $viewModel.billAmount, prompt: Text("$0.00").foregroundColor(Color(hex: "#9CA8A2")))
                            .textFieldStyle(RoundedTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }

                    // Due day
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Due day of month")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.secondaryText)

                        Picker("Due Day", selection: $viewModel.billDueDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                    }

                    // Add button
                    Button {
                        Task { await viewModel.addBill() }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Bill")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.canAddBill ? Theme.accent : Theme.secondaryText)
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.canAddBill)
                }
            }
        }
    }

    // MARK: - Review Step

    private var reviewStepContent: some View {
        VStack(spacing: 24) {
            // Payday summary
            VStack(alignment: .leading, spacing: 12) {
                Label("Payday Schedule", systemImage: "calendar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                HStack {
                    Image(systemName: viewModel.selectedPaydayType.icon)
                        .foregroundColor(Theme.accent)
                    Text(viewModel.selectedPaydayType.displayName)
                        .foregroundColor(Theme.primaryText)
                    Spacer()
                    Text(paydayDaysDescription)
                        .foregroundColor(Theme.secondaryText)
                }
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.03), radius: 4)
            }

            // Bills summary
            VStack(alignment: .leading, spacing: 12) {
                Label("Bills (\(viewModel.addedBills.count))", systemImage: "doc.text.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                ForEach(viewModel.addedBills) { bill in
                    ReviewBillRow(bill: bill)
                }
            }

            // Total
            HStack {
                Text("Monthly Total")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
                Spacer()
                Text(String(format: "$%.2f", viewModel.addedBills.reduce(0) { $0 + $1.typicalAmount }))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.accent)
            }
            .padding()
            .background(Theme.accentLight)
            .cornerRadius(12)
        }
    }

    private var paydayDaysDescription: String {
        switch viewModel.selectedPaydayType {
        case .weekly, .biweekly:
            return viewModel.weekdayOptions.first { $0.value == viewModel.selectedWeekday }?.name ?? ""
        case .semiMonthly:
            let days = viewModel.selectedMonthDays.sorted()
            return "\(ordinal(days[safe: 0] ?? 1)) & \(ordinal(days[safe: 1] ?? 15))"
        case .monthly:
            return ordinal(viewModel.selectedMonthDays.first ?? 1)
        }
    }

    private func ordinal(_ day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(day)\(suffix)"
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    switch viewModel.currentStep {
                    case .payday:
                        await viewModel.savePaydaySchedule()
                    case .bills:
                        viewModel.nextStep()
                    case .review:
                        await viewModel.completeSetup()
                    }
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(continueButtonTitle)
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canContinue ? Theme.accent : Theme.secondaryText)
                .cornerRadius(14)
            }
            .disabled(!canContinue || viewModel.isLoading)
        }
        .padding(Theme.padding)
        .background(Theme.background)
    }

    private var continueButtonTitle: String {
        switch viewModel.currentStep {
        case .payday: return "Continue"
        case .bills: return "Review"
        case .review: return "Complete Setup"
        }
    }

    private var canContinue: Bool {
        switch viewModel.currentStep {
        case .payday: return viewModel.canProceedFromPayday
        case .bills: return viewModel.canProceedFromBills
        case .review: return true
        }
    }

    private func haptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Supporting Views

private struct PaydayTypeRow: View {
    let type: PaydayType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? Theme.accent : Theme.secondaryText)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.primaryText)
                    Text(type.description)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Theme.accent : Theme.secondaryText)
            }
            .padding()
            .background(isSelected ? Theme.accentLight : Theme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.accent : Color.clear, lineWidth: 2)
            )
        }
    }
}

private struct CategoryChip: View {
    let category: SwapBillCategory
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.displayName)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? category.color : Theme.cardBackground)
            .foregroundColor(isSelected ? .white : Theme.primaryText)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 4)
        }
    }
}

private struct AddedBillRow: View {
    let bill: UserBill
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: bill.category?.icon ?? "doc")
                .font(.system(size: 18))
                .foregroundColor(bill.category?.color ?? Theme.accent)
                .frame(width: 36, height: 36)
                .background((bill.category?.color ?? Theme.accent).opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(bill.providerName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.primaryText)
                Text("Due \(bill.formattedDueDay)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.secondaryText)
            }

            Spacer()

            Text(bill.formattedAmount)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.primaryText)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 4)
    }
}

private struct ReviewBillRow: View {
    let bill: UserBill

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: bill.category?.icon ?? "doc")
                .foregroundColor(bill.category?.color ?? Theme.accent)

            Text(bill.providerName)
                .foregroundColor(Theme.primaryText)

            Spacer()

            Text(bill.formattedAmount)
                .foregroundColor(Theme.secondaryText)

            Text("• \(bill.formattedDueDay)")
                .foregroundColor(Theme.secondaryText)
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 4)
    }
}

private struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .foregroundColor(Theme.primaryText)
            .background(Theme.cardBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "#D0D9D4"), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 4)
    }
}

// MARK: - Array Extension

// MARK: - Preview

#Preview {
    PortfolioSetupView()
}
