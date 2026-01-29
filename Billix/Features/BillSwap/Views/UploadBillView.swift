//
//  UploadBillView.swift
//  Billix
//
//  Professional bill upload flow with step-by-step progress tracker
//

import SwiftUI
import PhotosUI

// MARK: - Upload Steps

enum UploadStep: Int, CaseIterable {
    case capture = 0
    case details = 1
    case payment = 2
    case review = 3

    var title: String {
        switch self {
        case .capture: return "Capture"
        case .details: return "Details"
        case .payment: return "Payment"
        case .review: return "Review"
        }
    }

    var icon: String {
        switch self {
        case .capture: return "camera.fill"
        case .details: return "doc.text.fill"
        case .payment: return "creditcard.fill"
        case .review: return "checkmark.shield.fill"
        }
    }
}

struct UploadBillView: View {
    @StateObject private var viewModel = UploadBillViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let onComplete: () -> Void

    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var currentStep: UploadStep = .capture

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemBackground) : Color(.systemGray6).opacity(0.5)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress Tracker
                    StepProgressTracker(
                        currentStep: currentStep,
                        hasImage: viewModel.hasImage,
                        hasDetails: viewModel.hasBasicDetails,
                        hasPayment: viewModel.hasPaymentInfo
                    )
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            switch currentStep {
                            case .capture:
                                captureStepView
                            case .details:
                                detailsStepView
                            case .payment:
                                paymentStepView
                            case .review:
                                reviewStepView
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }

                    // Bottom Navigation
                    bottomNavigation
                }
            }
            .navigationTitle("Upload Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await viewModel.processImage(image)
                        withAnimation(.spring(response: 0.4)) {
                            currentStep = .details
                        }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
            .onChange(of: viewModel.uploadComplete) { oldValue, newValue in
                if newValue {
                    onComplete()
                    dismiss()
                }
            }
            .overlay {
                if viewModel.isProcessing || viewModel.isUploading {
                    loadingOverlay
                }
            }
        }
    }

    // MARK: - Step 1: Capture

    private var captureStepView: some View {
        VStack(spacing: 24) {
            if let image = viewModel.capturedImage {
                // Show captured image
                VStack(spacing: 16) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                        Button {
                            viewModel.clearImage()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white, Color.black.opacity(0.6))
                        }
                        .padding(12)
                    }

                    // Success indicator
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.billixMoneyGreen)
                        Text("Bill captured successfully")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.billixMoneyGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.billixMoneyGreen.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                // Capture prompt
                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .stroke(Color.billixMoneyGreen, lineWidth: 2)
                            .frame(width: 100, height: 100)

                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.billixDarkTeal)
                    }

                    VStack(spacing: 12) {
                        Text("Capture Your Bill")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Take a clear photo of your bill or select one from your photo library")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Capture buttons
                    VStack(spacing: 12) {
                        Button {
                            viewModel.showCamera = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                }
                                Text("Take Photo")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.billixDarkTeal)
                            .cornerRadius(12)
                        }

                        Button {
                            showPhotosPicker = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.billixDarkTeal.opacity(0.3), lineWidth: 1.5)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 16))
                                }
                                Text("Choose from Library")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.billixDarkTeal)
                            .padding()
                            .background(Color.billixDarkTeal.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }

                    // Security note
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.billixMoneyGreen)
                        Text("Your bill images are encrypted and secure")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 24)
            }
        }
    }

    // MARK: - Step 2: Details

    private var detailsStepView: some View {
        VStack(spacing: 20) {
            // Section header
            UploadSectionHeader(
                title: "Bill Details",
                subtitle: "Enter the basic information from your bill",
                icon: "doc.text.fill"
            )

            // Amount
            FormField(
                label: "Amount",
                icon: "dollarsign.circle.fill",
                isRequired: true
            ) {
                HStack {
                    Text("$")
                        .foregroundColor(.secondary)
                        .font(.title3)

                    TextField("0.00", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                        .font(.title3)
                }
            }

            // Due Date
            FormField(
                label: "Due Date",
                icon: "calendar.circle.fill",
                isRequired: true
            ) {
                DatePicker("", selection: $viewModel.dueDate, displayedComponents: .date)
                    .labelsHidden()
            }

            // Provider
            FormField(
                label: "Provider",
                icon: "building.2.fill",
                isRequired: false
            ) {
                TextField("e.g., DTE Energy, Comcast", text: $viewModel.providerName)
            }

            // Category
            FormField(
                label: "Category",
                icon: "square.grid.2x2.fill",
                isRequired: true
            ) {
                Picker("Category", selection: $viewModel.category) {
                    ForEach(SwapBillCategory.utilityCategories, id: \.self) { category in
                        Label(category.displayName, systemImage: category.icon)
                            .tag(category)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Zip Code
            FormField(
                label: "Zip Code",
                icon: "location.circle.fill",
                isRequired: false
            ) {
                TextField("e.g., 48201", text: $viewModel.zipCode)
                    .keyboardType(.numberPad)
            }
        }
    }

    // MARK: - Step 3: Payment Info

    private var paymentStepView: some View {
        VStack(spacing: 20) {
            // Section header
            UploadSectionHeader(
                title: "Payment Information",
                subtitle: "Help your swap partner pay your bill",
                icon: "creditcard.fill"
            )

            // Account Number
            FormField(
                label: "Account Number",
                icon: "number.circle.fill",
                isRequired: false,
                hint: "This will be shared with your swap partner"
            ) {
                TextField("Last 4 digits or full number", text: $viewModel.accountNumber)
                    .keyboardType(.numberPad)
            }

            // Guest Pay Link
            FormField(
                label: "Guest Pay Link",
                icon: "link.circle.fill",
                isRequired: false,
                hint: "URL where your partner can pay your bill"
            ) {
                TextField("https://...", text: $viewModel.guestPayLink)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            // Info card
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(Color.billixMoneyGreen, lineWidth: 1.5)
                            .frame(width: 32, height: 32)
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.billixMoneyGreen)
                    }
                    Text("Why provide payment info?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text("Guest pay links allow your swap partner to pay your bill directly without needing your login credentials. This keeps your account secure while enabling seamless bill swapping.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding()
            .background(Color.billixMoneyGreen.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.billixMoneyGreen.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Step 4: Review

    private var reviewStepView: some View {
        VStack(spacing: 20) {
            // Section header
            UploadSectionHeader(
                title: "Review & Submit",
                subtitle: "Confirm your bill details before submitting",
                icon: "checkmark.shield.fill"
            )

            // Bill preview card
            VStack(spacing: 16) {
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .cornerRadius(12)
                }

                VStack(spacing: 12) {
                    ReviewRow(label: "Amount", value: "$\(viewModel.amount)", icon: "dollarsign.circle.fill")
                    ReviewRow(label: "Due Date", value: viewModel.dueDate.formatted(date: .abbreviated, time: .omitted), icon: "calendar.circle.fill")
                    ReviewRow(label: "Provider", value: viewModel.providerName.isEmpty ? "Not specified" : viewModel.providerName, icon: "building.2.fill")
                    ReviewRow(label: "Category", value: viewModel.category.displayName, icon: "square.grid.2x2.fill")
                    if !viewModel.zipCode.isEmpty {
                        ReviewRow(label: "Zip Code", value: viewModel.zipCode, icon: "location.circle.fill")
                    }
                    if !viewModel.accountNumber.isEmpty {
                        ReviewRow(label: "Account", value: "****\(viewModel.accountNumber.suffix(4))", icon: "number.circle.fill")
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)

            // Terms
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.billixMoneyGreen)

                Text("By submitting, you confirm this bill is accurate and agree to our swap terms. Your bill will be visible to potential swap partners.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 16) {
                // Back button
                if currentStep != .capture {
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            if let previous = UploadStep(rawValue: currentStep.rawValue - 1) {
                                currentStep = previous
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.billixDarkTeal)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.billixDarkTeal.opacity(0.1))
                        .cornerRadius(10)
                    }
                }

                Spacer()

                // Next/Submit button
                Button {
                    if currentStep == .review {
                        Task {
                            await viewModel.submitBill()
                        }
                    } else {
                        withAnimation(.spring(response: 0.4)) {
                            if let next = UploadStep(rawValue: currentStep.rawValue + 1) {
                                currentStep = next
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(currentStep == .review ? "Submit Bill" : "Continue")
                            .fontWeight(.semibold)
                        Image(systemName: currentStep == .review ? "checkmark" : "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(canProceed ? Color.billixDarkTeal : Color.gray)
                    .cornerRadius(10)
                }
                .disabled(!canProceed || viewModel.isUploading)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case .capture:
            return viewModel.hasImage
        case .details:
            return viewModel.hasBasicDetails
        case .payment:
            return true // Payment info is optional
        case .review:
            return viewModel.canSubmit
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.billixMoneyGreen.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)

                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(.billixDarkTeal)
                }

                Text(viewModel.isProcessing ? "Processing bill..." : "Uploading...")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Please wait")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(32)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.15), radius: 20)
        }
    }
}

// MARK: - Step Progress Tracker

struct StepProgressTracker: View {
    let currentStep: UploadStep
    let hasImage: Bool
    let hasDetails: Bool
    let hasPayment: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(UploadStep.allCases, id: \.rawValue) { step in
                HStack(spacing: 0) {
                    // Step circle
                    StepIndicator(
                        step: step,
                        isActive: step == currentStep,
                        isCompleted: isStepCompleted(step)
                    )

                    // Connector line
                    if step != .review {
                        Rectangle()
                            .fill(isStepCompleted(step) ? Color.billixMoneyGreen : Color(.systemGray4))
                            .frame(height: 2)
                    }
                }
            }
        }
    }

    private func isStepCompleted(_ step: UploadStep) -> Bool {
        switch step {
        case .capture:
            return hasImage && currentStep.rawValue > step.rawValue
        case .details:
            return hasDetails && currentStep.rawValue > step.rawValue
        case .payment:
            return currentStep.rawValue > step.rawValue
        case .review:
            return false
        }
    }
}

struct StepIndicator: View {
    let step: UploadStep
    let isActive: Bool
    let isCompleted: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(strokeColor, lineWidth: 2)
                    .frame(width: 44, height: 44)

                if isCompleted {
                    Circle()
                        .fill(Color.billixMoneyGreen)
                        .frame(width: 44, height: 44)

                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: step.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isActive ? .billixDarkTeal : .secondary)
                }
            }

            Text(step.title)
                .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .billixDarkTeal : .secondary)
        }
        .frame(width: 60)
    }

    private var strokeColor: Color {
        if isCompleted {
            return .billixMoneyGreen
        } else if isActive {
            return .billixMoneyGreen
        } else {
            return Color(.systemGray4)
        }
    }
}

// MARK: - Upload Section Header

struct UploadSectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.billixMoneyGreen, lineWidth: 2)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.billixDarkTeal)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Form Field

struct FormField<Content: View>: View {
    let label: String
    let icon: String
    let isRequired: Bool
    var hint: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Color.billixMoneyGreen.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 24, height: 24)

                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundColor(.billixDarkTeal)
                }

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
            }

            content
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )

            if let hint = hint {
                Text(hint)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Review Row

struct ReviewRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.billixDarkTeal)
                    .frame(width: 20)

                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ViewModel Extensions

extension UploadBillViewModel {
    var hasBasicDetails: Bool {
        !amount.isEmpty && Double(amount) != nil
    }

    var hasPaymentInfo: Bool {
        !accountNumber.isEmpty || !guestPayLink.isEmpty
    }
}

// MARK: - Preview

#Preview("Upload Bill View") {
    UploadBillView { }
}

#Preview("Upload Bill - Dark Mode") {
    UploadBillView { }
    .preferredColorScheme(.dark)
}
