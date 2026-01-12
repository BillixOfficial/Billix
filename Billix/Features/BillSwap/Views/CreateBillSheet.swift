//
//  CreateBillSheet.swift
//  Billix
//
//  Create Bill Walkthrough - 4-Step Wizard
//

import SwiftUI
import PhotosUI

// MARK: - Create Bill Step Enum

enum CreateBillStep: Int, CaseIterable {
    case upload = 0
    case category = 1
    case details = 2
    case review = 3

    var title: String {
        switch self {
        case .upload: return "Upload"
        case .category: return "Category"
        case .details: return "Details"
        case .review: return "Review"
        }
    }

    var subtitle: String {
        switch self {
        case .upload: return "Add a photo of your bill"
        case .category: return "Select bill type"
        case .details: return "Enter bill information"
        case .review: return "Confirm and create"
        }
    }

    var icon: String {
        switch self {
        case .upload: return "camera.fill"
        case .category: return "tag.fill"
        case .details: return "doc.text.fill"
        case .review: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Create Bill Sheet (Walkthrough Wizard)

struct CreateBillSheet: View {
    @ObservedObject var viewModel: BillSwapViewModel
    @Environment(\.dismiss) private var dismiss

    // Step state
    @State private var currentStep: CreateBillStep = .upload

    // Collected data
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var billImage: UIImage?
    @State private var selectedCategory: SwapBillCategory = .electric
    @State private var title: String = ""
    @State private var providerName: String = ""
    @State private var amountText: String = ""
    @State private var dueDate: Date = Date().addingTimeInterval(7 * 24 * 3600)
    @State private var paymentUrl: String = ""
    @State private var accountLast4: String = ""
    @State private var selectedSwapType: SwapTypeOption = .twoWay

    // State
    @State private var isCreating = false
    @State private var isUploadingImage = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Computed properties
    private var amountCents: Int {
        let cleanAmount = amountText.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        guard let amount = Double(cleanAmount) else { return 0 }
        return Int(amount * 100)
    }

    private var maxAmountCents: Int {
        viewModel.trustProfile?.tier.maxBillCents ?? 10000
    }

    private var formattedMaxAmount: String {
        String(format: "$%.0f", Double(maxAmountCents) / 100.0)
    }

    private var canProceedFromDetails: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        amountCents >= 100 &&
        amountCents <= maxAmountCents
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BillSwapTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    StepProgressIndicator(currentStep: currentStep)
                        .padding(.horizontal, BillSwapTheme.screenPadding)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    // Step content
                    TabView(selection: $currentStep) {
                        UploadStepView(
                            selectedPhoto: $selectedPhoto,
                            billImage: $billImage
                        )
                        .tag(CreateBillStep.upload)

                        CategoryStepView(
                            selectedCategory: $selectedCategory,
                            tierInfo: viewModel.tierInfo
                        )
                        .tag(CreateBillStep.category)

                        DetailsStepView(
                            title: $title,
                            providerName: $providerName,
                            amountText: $amountText,
                            dueDate: $dueDate,
                            paymentUrl: $paymentUrl,
                            accountLast4: $accountLast4,
                            maxAmount: formattedMaxAmount,
                            maxAmountCents: maxAmountCents,
                            amountCents: amountCents
                        )
                        .tag(CreateBillStep.details)

                        ReviewStepView(
                            billImage: billImage,
                            category: selectedCategory,
                            title: title,
                            providerName: providerName,
                            amountCents: amountCents,
                            dueDate: dueDate,
                            paymentUrl: paymentUrl,
                            accountLast4: accountLast4,
                            selectedSwapType: $selectedSwapType
                        )
                        .tag(CreateBillStep.review)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)

                    // Navigation buttons
                    navigationButtons
                        .padding(.horizontal, BillSwapTheme.screenPadding)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Add Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .foregroundColor(BillSwapTheme.secondaryText)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isCreating || isUploadingImage {
                    loadingOverlay
                }
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Back button (hidden on first step)
            if currentStep != .upload {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation {
                        if let prevIndex = CreateBillStep.allCases.firstIndex(of: currentStep),
                           prevIndex > 0 {
                            currentStep = CreateBillStep.allCases[prevIndex - 1]
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(BillSwapTheme.secondaryText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(BillSwapTheme.secondaryBackground)
                    .cornerRadius(12)
                }
            }

            Spacer()

            // Next / Create button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if currentStep == .review {
                    createBill()
                } else {
                    withAnimation {
                        if let nextIndex = CreateBillStep.allCases.firstIndex(of: currentStep),
                           nextIndex < CreateBillStep.allCases.count - 1 {
                            currentStep = CreateBillStep.allCases[nextIndex + 1]
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(currentStep == .review ? "Create Bill" : "Next")
                        .font(.system(size: 15, weight: .semibold))
                    if currentStep != .review {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(canProceedToNext ? BillSwapTheme.accent : BillSwapTheme.secondaryText.opacity(0.5))
                .cornerRadius(12)
            }
            .disabled(!canProceedToNext || isCreating)
        }
    }

    private var canProceedToNext: Bool {
        switch currentStep {
        case .upload:
            return true // Photo is optional
        case .category:
            return true // Category is always selected
        case .details:
            return canProceedFromDetails
        case .review:
            return canProceedFromDetails
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(BillSwapTheme.accent)

                Text(isUploadingImage ? "Uploading photo..." : "Creating bill...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(BillSwapTheme.primaryText)
            }
            .padding(24)
            .background(BillSwapTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10)
        }
    }

    // MARK: - Create Bill Action

    private func createBill() {
        isCreating = true

        Task {
            do {
                // Upload image first if one is selected
                var imageUrl: String? = nil
                if let image = billImage,
                   let imageData = image.jpegData(compressionQuality: 0.8) {
                    await MainActor.run {
                        isUploadingImage = true
                        isCreating = false
                    }

                    imageUrl = try await BillSwapService.shared.uploadBillImage(imageData)

                    await MainActor.run {
                        isUploadingImage = false
                        isCreating = true
                    }
                }

                _ = try await viewModel.createBill(
                    title: title.trimmingCharacters(in: .whitespaces),
                    category: selectedCategory,
                    providerName: providerName.isEmpty ? nil : providerName,
                    amountCents: amountCents,
                    dueDate: dueDate,
                    paymentUrl: paymentUrl.isEmpty ? nil : paymentUrl,
                    accountNumberLast4: accountLast4.isEmpty ? nil : accountLast4,
                    billImageUrl: imageUrl
                )

                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isCreating = false
                    isUploadingImage = false
                }
            }
        }
    }
}

// MARK: - Step Progress Indicator

private struct StepProgressIndicator: View {
    let currentStep: CreateBillStep

    var body: some View {
        VStack(spacing: 16) {
            // Step dots with connecting lines
            HStack(spacing: 0) {
                ForEach(CreateBillStep.allCases, id: \.self) { step in
                    let isCompleted = step.rawValue < currentStep.rawValue
                    let isCurrent = step == currentStep

                    // Step circle
                    ZStack {
                        Circle()
                            .fill(isCompleted || isCurrent ? BillSwapTheme.accent : BillSwapTheme.secondaryBackground)
                            .frame(width: 36, height: 36)

                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: step.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isCurrent ? .white : BillSwapTheme.secondaryText)
                        }
                    }

                    // Connecting line (not after last step)
                    if step.rawValue < CreateBillStep.allCases.count - 1 {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? BillSwapTheme.accent : BillSwapTheme.secondaryBackground)
                            .frame(height: 3)
                    }
                }
            }

            // Current step info
            VStack(spacing: 4) {
                Text(currentStep.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(BillSwapTheme.primaryText)

                Text(currentStep.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(BillSwapTheme.secondaryText)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Swap Type Option

enum SwapTypeOption: String, CaseIterable {
    case twoWay = "two_way"
    case oneSided = "one_sided"

    var displayName: String {
        switch self {
        case .twoWay: return "Two-Way Swap"
        case .oneSided: return "One-Sided Assist"
        }
    }

    var description: String {
        switch self {
        case .twoWay: return "Both parties pay each other's bills"
        case .oneSided: return "A helper pays your bill for you"
        }
    }

    var fee: String {
        switch self {
        case .twoWay: return "$0.99"
        case .oneSided: return "$1.49"
        }
    }

    var feeNote: String {
        switch self {
        case .twoWay: return "Fee charged to each party when matched"
        case .oneSided: return "Fee charged to helper when matched"
        }
    }

    var icon: String {
        switch self {
        case .twoWay: return "arrow.left.arrow.right"
        case .oneSided: return "hand.raised.fill"
        }
    }
}

// MARK: - Step 1: Upload Bill Image

private struct UploadStepView: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var billImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Illustration / Preview area
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(BillSwapTheme.cardBackground)
                        .frame(height: 280)
                        .shadow(color: BillSwapTheme.cardShadow, radius: 8, x: 0, y: 4)

                    if let image = billImage {
                        // Show selected image
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 260)
                                .cornerRadius(16)
                                .padding(10)

                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                billImage = nil
                                selectedPhoto = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white, Color.black.opacity(0.6))
                            }
                            .padding(16)
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(BillSwapTheme.accentLight)
                                    .frame(width: 80, height: 80)

                                Image(systemName: "doc.viewfinder")
                                    .font(.system(size: 36))
                                    .foregroundColor(BillSwapTheme.accent)
                            }

                            VStack(spacing: 6) {
                                Text("Upload Your Bill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(BillSwapTheme.primaryText)

                                Text("Take a photo or choose from your library")
                                    .font(.system(size: 14))
                                    .foregroundColor(BillSwapTheme.secondaryText)
                            }
                        }
                    }
                }
                .padding(.horizontal, BillSwapTheme.screenPadding)

                // Photo picker buttons
                VStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 18))
                            Text(billImage == nil ? "Choose from Library" : "Change Photo")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(BillSwapTheme.accent)
                        .cornerRadius(14)
                    }
                    .onChange(of: selectedPhoto) { _, newValue in
                        loadPhoto(from: newValue)
                    }

                    // Skip hint
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                        Text("Photo is optional but helps verify your bill")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(BillSwapTheme.secondaryText)
                }
                .padding(.horizontal, BillSwapTheme.screenPadding)

                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item = item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    billImage = image
                }
            }
        }
    }
}

// MARK: - Step 2: Category Selection

private struct CategoryStepView: View {
    @Binding var selectedCategory: SwapBillCategory
    let tierInfo: (name: String, maxBill: String, maxSwaps: Int)?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Tier info banner
                if let tier = tierInfo {
                    HStack(spacing: 12) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 20))
                            .foregroundColor(BillSwapTheme.accent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your Tier: \(tier.name)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(BillSwapTheme.primaryText)
                            Text("Max bill amount: \(tier.maxBill)")
                                .font(.system(size: 12))
                                .foregroundColor(BillSwapTheme.secondaryText)
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(BillSwapTheme.accentLight)
                    .cornerRadius(12)
                    .padding(.horizontal, BillSwapTheme.screenPadding)
                }

                // Category grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(SwapBillCategory.allCases, id: \.self) { category in
                        CategoryCard(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, BillSwapTheme.screenPadding)

                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
    }
}

private struct CategoryCard: View {
    let category: SwapBillCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? BillSwapTheme.accent : BillSwapTheme.categoryColor(for: category.rawValue).opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: category.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : BillSwapTheme.categoryColor(for: category.rawValue))
                }

                // Name
                Text(category.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(BillSwapTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(BillSwapTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? BillSwapTheme.accent : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: isSelected ? BillSwapTheme.accent.opacity(0.2) : BillSwapTheme.cardShadow,
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Step 3: Bill Details

private struct DetailsStepView: View {
    @Binding var title: String
    @Binding var providerName: String
    @Binding var amountText: String
    @Binding var dueDate: Date
    @Binding var paymentUrl: String
    @Binding var accountLast4: String

    let maxAmount: String
    let maxAmountCents: Int
    let amountCents: Int

    @FocusState private var focusedField: Field?

    enum Field {
        case title, provider, amount, url, account
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Required fields card
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader(icon: "asterisk", title: "Required Information")

                    // Title field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bill Title")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BillSwapTheme.secondaryText)

                        TextField("e.g., Electric Bill", text: $title)
                            .font(.system(size: 15))
                            .foregroundColor(BillSwapTheme.primaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(BillSwapTheme.secondaryBackground)
                            .cornerRadius(10)
                            .focused($focusedField, equals: .title)
                    }

                    // Amount field
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Amount")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(BillSwapTheme.secondaryText)

                            Spacer()

                            Text("Tier limit: \(maxAmount)")
                                .font(.system(size: 11))
                                .foregroundColor(BillSwapTheme.mutedText)
                        }

                        HStack(spacing: 8) {
                            Text("$")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(BillSwapTheme.secondaryText)

                            TextField("0.00", text: $amountText)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(BillSwapTheme.primaryText)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .amount)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(BillSwapTheme.secondaryBackground)
                        .cornerRadius(10)

                        // Validation
                        if amountCents > 0 {
                            validationMessage(amountCents: amountCents, maxAmountCents: maxAmountCents, maxAmount: maxAmount)
                        }
                    }

                    // Due date
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Due Date")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BillSwapTheme.secondaryText)

                        DatePicker(
                            "",
                            selection: $dueDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(BillSwapTheme.accent)
                    }
                }
                .padding(16)
                .background(BillSwapTheme.cardBackground)
                .cornerRadius(BillSwapTheme.cardCornerRadius)
                .shadow(color: BillSwapTheme.cardShadow, radius: BillSwapTheme.cardShadowRadius, x: 0, y: BillSwapTheme.cardShadowY)
                .padding(.horizontal, BillSwapTheme.screenPadding)

                // Optional fields card
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader(icon: "plus.circle", title: "Optional Information")

                    // Provider
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Provider Name")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BillSwapTheme.secondaryText)

                        TextField("e.g., ConEd, Spectrum", text: $providerName)
                            .font(.system(size: 15))
                            .foregroundColor(BillSwapTheme.primaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(BillSwapTheme.secondaryBackground)
                            .cornerRadius(10)
                            .focused($focusedField, equals: .provider)
                    }

                    // Payment URL
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Payment URL")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BillSwapTheme.secondaryText)

                        TextField("https://pay.provider.com", text: $paymentUrl)
                            .font(.system(size: 15))
                            .foregroundColor(BillSwapTheme.primaryText)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .autocapitalization(.none)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(BillSwapTheme.secondaryBackground)
                            .cornerRadius(10)
                            .focused($focusedField, equals: .url)
                    }

                    // Account last 4
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Account Last 4 Digits")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BillSwapTheme.secondaryText)

                        TextField("1234", text: $accountLast4)
                            .font(.system(size: 15))
                            .foregroundColor(BillSwapTheme.primaryText)
                            .keyboardType(.numberPad)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(BillSwapTheme.secondaryBackground)
                            .cornerRadius(10)
                            .focused($focusedField, equals: .account)
                            .onChange(of: accountLast4) { _, newValue in
                                if newValue.count > 4 {
                                    accountLast4 = String(newValue.prefix(4))
                                }
                            }
                    }

                    Text("This helps your swap partner pay the correct bill")
                        .font(.system(size: 12))
                        .foregroundColor(BillSwapTheme.secondaryText)
                }
                .padding(16)
                .background(BillSwapTheme.cardBackground)
                .cornerRadius(BillSwapTheme.cardCornerRadius)
                .shadow(color: BillSwapTheme.cardShadow, radius: BillSwapTheme.cardShadowRadius, x: 0, y: BillSwapTheme.cardShadowY)
                .padding(.horizontal, BillSwapTheme.screenPadding)

                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(BillSwapTheme.accent)

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(BillSwapTheme.primaryText)
        }
    }

    @ViewBuilder
    private func validationMessage(amountCents: Int, maxAmountCents: Int, maxAmount: String) -> some View {
        HStack(spacing: 4) {
            if amountCents > maxAmountCents {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                Text("Amount exceeds your tier limit (\(maxAmount))")
                    .font(.system(size: 11))
            } else if amountCents < 100 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                Text("Minimum amount is $1.00")
                    .font(.system(size: 11))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                Text("Amount is within your tier limit")
                    .font(.system(size: 11))
            }
        }
        .foregroundColor(
            amountCents > maxAmountCents || amountCents < 100
            ? BillSwapTheme.statusDispute
            : BillSwapTheme.statusComplete
        )
    }
}

// MARK: - Step 4: Review & Confirm

private struct ReviewStepView: View {
    let billImage: UIImage?
    let category: SwapBillCategory
    let title: String
    let providerName: String
    let amountCents: Int
    let dueDate: Date
    let paymentUrl: String
    let accountLast4: String
    @Binding var selectedSwapType: SwapTypeOption

    private var formattedAmount: String {
        String(format: "$%.2f", Double(amountCents) / 100.0)
    }

    private var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Bill summary card
                VStack(spacing: 16) {
                    // Header with image
                    HStack(spacing: 14) {
                        if let image = billImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(BillSwapTheme.categoryColor(for: category.rawValue).opacity(0.15))
                                    .frame(width: 60, height: 60)

                                Image(systemName: category.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(BillSwapTheme.categoryColor(for: category.rawValue))
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(title.isEmpty ? "Untitled Bill" : title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(BillSwapTheme.primaryText)

                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 12))
                                Text(category.displayName)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(BillSwapTheme.secondaryText)
                        }

                        Spacer()

                        Text(formattedAmount)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(BillSwapTheme.accent)
                    }

                    Divider()

                    // Details grid
                    VStack(spacing: 10) {
                        ReviewRow(label: "Due Date", value: formattedDueDate)

                        if !providerName.isEmpty {
                            ReviewRow(label: "Provider", value: providerName)
                        }

                        if !paymentUrl.isEmpty {
                            ReviewRow(label: "Payment URL", value: "Provided", icon: "checkmark.circle.fill")
                        }

                        if !accountLast4.isEmpty {
                            ReviewRow(label: "Account", value: "****\(accountLast4)")
                        }
                    }
                }
                .padding(16)
                .background(BillSwapTheme.cardBackground)
                .cornerRadius(BillSwapTheme.cardCornerRadius)
                .shadow(color: BillSwapTheme.cardShadow, radius: BillSwapTheme.cardShadowRadius, x: 0, y: BillSwapTheme.cardShadowY)
                .padding(.horizontal, BillSwapTheme.screenPadding)

                // Swap type selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Swap Type")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(BillSwapTheme.primaryText)
                        .padding(.horizontal, BillSwapTheme.screenPadding)

                    VStack(spacing: 12) {
                        ForEach(SwapTypeOption.allCases, id: \.self) { option in
                            SwapTypeCard(
                                option: option,
                                isSelected: selectedSwapType == option
                            ) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedSwapType = option
                            }
                        }
                    }
                    .padding(.horizontal, BillSwapTheme.screenPadding)
                }

                // Fee info
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(BillSwapTheme.accent)

                        Text("Payment collected when matched")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(BillSwapTheme.primaryText)
                    }

                    Text(selectedSwapType.feeNote)
                        .font(.system(size: 12))
                        .foregroundColor(BillSwapTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(BillSwapTheme.accentLight)
                .cornerRadius(12)
                .padding(.horizontal, BillSwapTheme.screenPadding)

                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
    }
}

private struct ReviewRow: View {
    let label: String
    let value: String
    var icon: String? = nil

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(BillSwapTheme.secondaryText)

            Spacer()

            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(BillSwapTheme.statusComplete)
                }
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(BillSwapTheme.primaryText)
            }
        }
    }
}

private struct SwapTypeCard: View {
    let option: SwapTypeOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? BillSwapTheme.accent : BillSwapTheme.secondaryBackground)
                        .frame(width: 44, height: 44)

                    Image(systemName: option.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .white : BillSwapTheme.secondaryText)
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(BillSwapTheme.primaryText)

                    Text(option.description)
                        .font(.system(size: 12))
                        .foregroundColor(BillSwapTheme.secondaryText)
                }

                Spacer()

                // Fee badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(option.fee)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(BillSwapTheme.accent)
                    Text("fee")
                        .font(.system(size: 10))
                        .foregroundColor(BillSwapTheme.secondaryText)
                }

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? BillSwapTheme.accent : BillSwapTheme.secondaryText.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(BillSwapTheme.accent)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(14)
            .background(BillSwapTheme.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? BillSwapTheme.accent : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: isSelected ? BillSwapTheme.accent.opacity(0.15) : BillSwapTheme.cardShadow,
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    CreateBillSheet(viewModel: BillSwapViewModel())
}
