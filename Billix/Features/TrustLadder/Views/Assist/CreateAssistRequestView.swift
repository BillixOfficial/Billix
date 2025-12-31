//
//  CreateAssistRequestView.swift
//  Billix
//
//  Created by Claude Code on 12/31/24.
//  Multi-step wizard for creating an assist request
//

import SwiftUI

// MARK: - Wizard Step

enum AssistWizardStep: Int, CaseIterable {
    case bill = 0
    case amount = 1
    case terms = 2
    case review = 3

    var title: String {
        switch self {
        case .bill: return "Bill Info"
        case .amount: return "Amount"
        case .terms: return "Terms"
        case .review: return "Review"
        }
    }

    var icon: String {
        switch self {
        case .bill: return "doc.text"
        case .amount: return "dollarsign.circle"
        case .terms: return "handshake"
        case .review: return "checkmark.circle"
        }
    }
}

// MARK: - Create Assist Request View

struct CreateAssistRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assistService = AssistRequestService.shared

    // Wizard state
    @State private var currentStep: AssistWizardStep = .bill

    // Bill Info
    @State private var selectedBill: UserBill?
    @State private var billCategory: String = "Electric"
    @State private var billProvider: String = ""
    @State private var billAmount: String = ""
    @State private var billDueDate: Date = Date().addingTimeInterval(7 * 24 * 3600)
    @State private var billScreenshotData: Data?
    @State private var showImagePicker = false

    // Amount & Urgency
    @State private var amountRequested: String = ""
    @State private var urgency: AssistUrgency = .medium
    @State private var description: String = ""

    // Terms
    @State private var assistType: AssistType = .loan
    @State private var interestRate: String = ""
    @State private var repaymentDate: Date = Date().addingTimeInterval(30 * 24 * 3600)
    @State private var installmentCount: Int = 1
    @State private var termsNotes: String = ""

    // UI State
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showCategoryPicker = false
    @State private var createdRequest: AssistRequest?

    // Preset bills (would come from user's saved bills)
    @State private var userBills: [UserBill] = []

    // Categories
    private let categories = ["Electric", "Gas", "Water", "Internet", "Phone", "Cable", "Insurance", "Rent", "Other"]

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator

                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Step content
                            stepContent

                            // Error message
                            if let error = errorMessage {
                                errorBanner(error)
                            }

                            // Legal disclaimer
                            if currentStep == .review {
                                assistDisclaimer
                            }
                        }
                        .padding()
                    }

                    // Navigation buttons
                    navigationButtons
                }
            }
            .navigationTitle("Request Assist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                AssistCategoryPickerSheet(selectedCategory: $billCategory, categories: categories)
            }
            .sheet(isPresented: $showSuccess) {
                AssistRequestCreatedView(request: createdRequest) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 4) {
            ForEach(AssistWizardStep.allCases, id: \.rawValue) { step in
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue ? Color.blue : Color(.systemGray4))
                            .frame(width: 32, height: 32)

                        if step.rawValue < currentStep.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step.rawValue + 1)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(step.rawValue == currentStep.rawValue ? .white : .gray)
                        }
                    }

                    Text(step.title)
                        .font(.system(size: 10))
                        .foregroundColor(step.rawValue <= currentStep.rawValue ? .primary : .secondary)
                }

                if step.rawValue < AssistWizardStep.allCases.count - 1 {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.blue : Color(.systemGray4))
                        .frame(height: 2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .bill:
            billInfoStep
        case .amount:
            amountStep
        case .terms:
            termsStep
        case .review:
            reviewStep
        }
    }

    // MARK: - Step 1: Bill Info

    private var billInfoStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            stepHeader(
                title: "What bill do you need help with?",
                subtitle: "Provide details about the bill you're requesting assistance for"
            )

            // Category selector
            formCard(title: "Bill Category", icon: "tag") {
                Button {
                    showCategoryPicker = true
                } label: {
                    HStack {
                        Image(systemName: categoryIcon(for: billCategory))
                            .foregroundColor(categoryColor(for: billCategory))
                        Text(billCategory)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
            }

            // Provider name
            formCard(title: "Provider Name", icon: "building.2") {
                TextField("e.g., Duke Energy, Comcast", text: $billProvider)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
            }

            // Bill amount
            formCard(title: "Total Bill Amount", icon: "dollarsign.circle") {
                HStack {
                    Text("$")
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $billAmount)
                        .keyboardType(.decimalPad)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
            }

            // Due date
            formCard(title: "Bill Due Date", icon: "calendar") {
                DatePicker("", selection: $billDueDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
            }

            // Screenshot upload hint
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("A bill screenshot will be required for verification")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
    }

    // MARK: - Step 2: Amount & Urgency

    private var amountStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            stepHeader(
                title: "How much help do you need?",
                subtitle: "Specify the amount you're requesting and urgency level"
            )

            // Amount requested
            formCard(title: "Amount Needed", icon: "dollarsign.circle.fill") {
                HStack {
                    Text("$")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.secondary)
                    TextField("0", text: $amountRequested)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)

                // Quick amounts
                if let total = Double(billAmount), total > 0 {
                    HStack(spacing: 8) {
                        quickAmountButton(amount: total, label: "Full")
                        quickAmountButton(amount: total * 0.75, label: "75%")
                        quickAmountButton(amount: total * 0.5, label: "50%")
                        quickAmountButton(amount: total * 0.25, label: "25%")
                    }
                    .padding(.top, 8)
                }
            }

            // Urgency level
            formCard(title: "Urgency Level", icon: "clock.fill") {
                VStack(spacing: 8) {
                    ForEach(AssistUrgency.allCases, id: \.rawValue) { level in
                        urgencyOption(level)
                    }
                }
            }

            // Description
            formCard(title: "Additional Details (Optional)", icon: "text.alignleft") {
                TextEditor(text: $description)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .overlay(
                        Group {
                            if description.isEmpty {
                                Text("Explain your situation to potential helpers...")
                                    .foregroundColor(.gray)
                                    .padding(12)
                            }
                        },
                        alignment: .topLeading
                    )
            }
        }
    }

    // MARK: - Step 3: Terms

    private var termsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            stepHeader(
                title: "What terms are you offering?",
                subtitle: "Set your preferred repayment terms - helpers can propose alternatives"
            )

            // Assist type
            formCard(title: "Assistance Type", icon: "handshake") {
                VStack(spacing: 8) {
                    ForEach(AssistType.allCases, id: \.rawValue) { type in
                        assistTypeOption(type)
                    }
                }
            }

            // Loan-specific options
            if assistType == .loan || assistType == .partialGift {
                // Interest rate
                formCard(title: "Interest Offered", icon: "percent") {
                    HStack {
                        TextField("0", text: $interestRate)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                        Text("%")
                            .foregroundColor(.secondary)
                        Spacer()

                        // Quick rates
                        HStack(spacing: 8) {
                            ForEach([0, 5, 10, 15], id: \.self) { rate in
                                Button {
                                    interestRate = "\(rate)"
                                } label: {
                                    Text("\(rate)%")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(interestRate == "\(rate)" ? .white : .blue)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(interestRate == "\(rate)" ? Color.blue : Color.blue.opacity(0.15))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }

                // Repayment date
                formCard(title: "Repayment By", icon: "calendar.badge.clock") {
                    DatePicker("", selection: $repaymentDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)

                    // Quick dates
                    HStack(spacing: 8) {
                        ForEach([7, 14, 30, 60], id: \.self) { days in
                            quickDateButton(days: days)
                        }
                    }
                    .padding(.top, 8)
                }

                // Installments
                formCard(title: "Payment Installments", icon: "calendar.day.timeline.left") {
                    Stepper("\(installmentCount) payment\(installmentCount > 1 ? "s" : "")", value: $installmentCount, in: 1...12)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)

                    if installmentCount > 1, let amount = Double(amountRequested), amount > 0 {
                        Text("≈ $\(String(format: "%.2f", amount / Double(installmentCount))) per payment")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }

            // Notes
            formCard(title: "Terms Notes (Optional)", icon: "note.text") {
                TextEditor(text: $termsNotes)
                    .frame(minHeight: 60)
                    .padding(8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Step 4: Review

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            stepHeader(
                title: "Review Your Request",
                subtitle: "Make sure everything looks correct before publishing"
            )

            // Bill summary
            reviewCard(title: "Bill Information", icon: "doc.text.fill", color: .blue) {
                VStack(spacing: 12) {
                    reviewRow("Category", value: billCategory)
                    reviewRow("Provider", value: billProvider)
                    reviewRow("Bill Amount", value: "$\(billAmount)")
                    reviewRow("Due Date", value: billDueDate.formatted(date: .abbreviated, time: .omitted))
                }
            }

            // Request summary
            reviewCard(title: "Request Details", icon: "dollarsign.circle.fill", color: .green) {
                VStack(spacing: 12) {
                    reviewRow("Amount Requested", value: "$\(amountRequested)", highlight: true)
                    reviewRow("Urgency", value: urgency.displayName, valueColor: urgency.color)
                    if !description.isEmpty {
                        reviewRow("Description", value: description)
                    }
                }
            }

            // Terms summary
            reviewCard(title: "Preferred Terms", icon: "handshake.fill", color: .orange) {
                VStack(spacing: 12) {
                    reviewRow("Type", value: assistType.displayName, valueColor: assistType.color)
                    if assistType == .loan || assistType == .partialGift {
                        if !interestRate.isEmpty && interestRate != "0" {
                            reviewRow("Interest", value: "\(interestRate)%")
                        }
                        reviewRow("Repay By", value: repaymentDate.formatted(date: .abbreviated, time: .omitted))
                        if installmentCount > 1 {
                            reviewRow("Installments", value: "\(installmentCount) payments")
                        }
                    }
                }
            }

            // Fee info
            feeInfoCard
        }
    }

    // MARK: - Helper Views

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }

    private func formCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func reviewCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }

            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func reviewRow(_ label: String, value: String, highlight: Bool = false, valueColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: highlight ? .bold : .medium))
                .foregroundColor(valueColor ?? .primary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }

    private func quickAmountButton(amount: Double, label: String) -> some View {
        let isSelected = amountRequested == String(format: "%.0f", amount)
        return Button {
            amountRequested = String(format: "%.0f", amount)
        } label: {
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                Text("$\(String(format: "%.0f", amount))")
                    .font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .white : .blue)
            .background(isSelected ? Color.blue : Color.blue.opacity(0.15))
            .cornerRadius(8)
        }
    }

    private func quickDateButton(days: Int) -> some View {
        let date = Date().addingTimeInterval(Double(days) * 24 * 3600)
        let isSelected = Calendar.current.isDate(repaymentDate, equalTo: date, toGranularity: .day)
        return Button {
            repaymentDate = date
        } label: {
            Text("\(days)d")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.15))
                .cornerRadius(6)
        }
    }

    private func urgencyOption(_ level: AssistUrgency) -> some View {
        let isSelected = urgency == level
        return Button {
            urgency = level
        } label: {
            HStack {
                Image(systemName: level.icon)
                    .foregroundColor(level.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    Text(level.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }

    private func assistTypeOption(_ type: AssistType) -> some View {
        let isSelected = assistType == type
        return Button {
            assistType = type
        } label: {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    Text(type.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? type.color.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
    }

    private var feeInfoCard: some View {
        let amount = Double(amountRequested) ?? 0
        let tier = AssistConnectionFeeTier.tier(for: amount)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Connection Fee")
                    .font(.system(size: 14, weight: .semibold))
            }

            Text("Both you and your helper will pay a \(tier.formattedFee) connection fee when the match is made. This fee is non-refundable after both parties pay.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private var assistDisclaimer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Important")
                    .font(.system(size: 14, weight: .semibold))
            }

            Text("Billix is a marketplace connecting users for bill payment assistance. Billix is NOT a lender and does not guarantee transactions. All terms are negotiated between users. Billix has no liability for outcomes.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

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
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Back button
            if currentStep.rawValue > 0 {
                Button {
                    withAnimation {
                        currentStep = AssistWizardStep(rawValue: currentStep.rawValue - 1) ?? .bill
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(12)
                }
            }

            // Next/Submit button
            Button {
                if currentStep == .review {
                    submitRequest()
                } else {
                    withAnimation {
                        currentStep = AssistWizardStep(rawValue: currentStep.rawValue + 1) ?? .review
                    }
                }
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentStep == .review ? "Publish Request" : "Continue")
                        if currentStep != .review {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canProceed ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!canProceed || isSubmitting)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Validation

    private var canProceed: Bool {
        switch currentStep {
        case .bill:
            return !billProvider.isEmpty && !billAmount.isEmpty && (Double(billAmount) ?? 0) > 0
        case .amount:
            return !amountRequested.isEmpty && (Double(amountRequested) ?? 0) > 0
        case .terms:
            return true // Terms are optional
        case .review:
            return true
        }
    }

    // MARK: - Actions

    private func submitRequest() {
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                // Build repayment terms
                var terms: RepaymentTerms? = nil
                if assistType == .loan || assistType == .partialGift {
                    terms = RepaymentTerms(
                        assistType: assistType,
                        interestRate: Double(interestRate),
                        repaymentDate: repaymentDate,
                        installmentCount: installmentCount > 1 ? installmentCount : nil,
                        installmentAmount: installmentCount > 1 ? (Double(amountRequested) ?? 0) / Double(installmentCount) : nil,
                        gracePeriodDays: nil,
                        notes: termsNotes.isEmpty ? nil : termsNotes
                    )
                } else {
                    terms = RepaymentTerms(
                        assistType: assistType,
                        interestRate: nil,
                        repaymentDate: nil,
                        installmentCount: nil,
                        installmentAmount: nil,
                        gracePeriodDays: nil,
                        notes: termsNotes.isEmpty ? nil : termsNotes
                    )
                }

                let request = try await assistService.createRequest(
                    billId: selectedBill?.id,
                    billCategory: billCategory,
                    billProvider: billProvider,
                    billAmount: Double(billAmount) ?? 0,
                    billDueDate: billDueDate,
                    billScreenshotUrl: nil,
                    amountRequested: Double(amountRequested) ?? 0,
                    urgency: urgency,
                    description: description.isEmpty ? nil : description,
                    preferredTerms: terms
                )

                createdRequest = request
                showSuccess = true

            } catch {
                errorMessage = error.localizedDescription
            }

            isSubmitting = false
        }
    }

    // MARK: - Helpers

    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "electric", "electricity": return "bolt.fill"
        case "gas", "natural gas": return "flame.fill"
        case "water": return "drop.fill"
        case "internet", "wifi": return "wifi"
        case "phone", "mobile": return "phone.fill"
        case "cable", "tv": return "tv.fill"
        case "insurance": return "shield.fill"
        case "rent", "mortgage": return "house.fill"
        default: return "doc.text.fill"
        }
    }

    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "electric", "electricity": return .yellow
        case "gas", "natural gas": return .orange
        case "water": return .blue
        case "internet", "wifi": return .purple
        case "phone", "mobile": return .green
        case "cable", "tv": return .red
        case "insurance": return .indigo
        case "rent", "mortgage": return .brown
        default: return .gray
        }
    }
}

// MARK: - Category Picker Sheet

struct AssistCategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: String
    let categories: [String]

    var body: some View {
        NavigationView {
            List {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: categoryIcon(for: category))
                                .foregroundColor(categoryColor(for: category))
                                .frame(width: 30)

                            Text(category)
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
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

    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "electric", "electricity": return "bolt.fill"
        case "gas", "natural gas": return "flame.fill"
        case "water": return "drop.fill"
        case "internet", "wifi": return "wifi"
        case "phone", "mobile": return "phone.fill"
        case "cable", "tv": return "tv.fill"
        case "insurance": return "shield.fill"
        case "rent", "mortgage": return "house.fill"
        default: return "doc.text.fill"
        }
    }

    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "electric", "electricity": return .yellow
        case "gas", "natural gas": return .orange
        case "water": return .blue
        case "internet", "wifi": return .purple
        case "phone", "mobile": return .green
        case "cable", "tv": return .red
        case "insurance": return .indigo
        case "rent", "mortgage": return .brown
        default: return .gray
        }
    }
}

// MARK: - Success View

struct AssistRequestCreatedView: View {
    let request: AssistRequest?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 8) {
                Text("Request Published!")
                    .font(.system(size: 24, weight: .bold))

                Text("Your assist request is now visible to potential helpers")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Request summary
            if let request = request {
                VStack(spacing: 12) {
                    summaryRow("Amount", value: "$\(String(format: "%.0f", request.amountRequested))")
                    summaryRow("Provider", value: request.billProvider)
                    summaryRow("Urgency", value: request.urgency.displayName)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }

            // Tips
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("What's Next?")
                        .font(.system(size: 14, weight: .semibold))
                }

                Text("Helpers will review your request and send offers. You'll be notified when someone wants to help!")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)

            Spacer()

            // Done button
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding(24)
    }

    private func summaryRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CreateAssistRequestView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAssistRequestView()
    }
}
#endif
