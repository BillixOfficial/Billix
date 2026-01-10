//
//  CreateBillSheet.swift
//  Billix
//
//  Create Bill Sheet for Bill Swap - Redesigned
//

import SwiftUI
import PhotosUI

struct CreateBillSheet: View {
    @ObservedObject var viewModel: BillSwapViewModel
    @Environment(\.dismiss) private var dismiss

    // Bill details
    @State private var title: String = ""
    @State private var category: SwapBillCategory = .electric
    @State private var providerName: String = ""
    @State private var amountText: String = ""
    @State private var dueDate: Date = Date().addingTimeInterval(7 * 24 * 3600)
    @State private var paymentUrl: String = ""
    @State private var accountLast4: String = ""

    // Photo picker
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var billImage: UIImage?
    @State private var isUploadingImage = false

    // State
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Focus
    @FocusState private var focusedField: Field?

    enum Field {
        case title, provider, amount, url, account
    }

    private var amountCents: Int {
        let cleanAmount = amountText.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        guard let amount = Double(cleanAmount) else { return 0 }
        return Int(amount * 100)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        amountCents >= 100 && // Min $1
        amountCents <= maxAmountCents
    }

    private var maxAmountCents: Int {
        viewModel.trustProfile?.tier.maxBillCents ?? 10000
    }

    private var formattedMaxAmount: String {
        String(format: "$%.0f", Double(maxAmountCents) / 100.0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                BillSwapTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Bill Photo Card
                        photoSection

                        // Bill Details Card
                        detailsSection

                        // Amount & Due Date Card
                        amountSection

                        // Payment Info Card
                        paymentInfoSection

                        // Swap Types Info
                        swapTypesInfo

                        // Create Button
                        createButton
                            .padding(.top, 8)
                    }
                    .padding(BillSwapTheme.screenPadding)
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
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "camera.fill", title: "Bill Photo")

            VStack(spacing: 12) {
                if let image = billImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .cornerRadius(12)

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            billImage = nil
                            selectedPhoto = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        .padding(8)
                    }
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: billImage == nil ? "photo.on.rectangle.angled" : "arrow.triangle.2.circlepath")
                            .font(.system(size: 16))
                        Text(billImage == nil ? "Add Bill Photo" : "Change Photo")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(BillSwapTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(BillSwapTheme.accentLight)
                    .cornerRadius(10)
                }
                .onChange(of: selectedPhoto) { oldValue, newValue in
                    loadPhoto(from: newValue)
                }

                Text("Upload a photo of your bill to help verify the payment details")
                    .font(.system(size: 12))
                    .foregroundColor(BillSwapTheme.secondaryText)
            }
            .padding(16)
            .background(BillSwapTheme.cardBackground)
            .cornerRadius(BillSwapTheme.cardCornerRadius)
            .shadow(
                color: BillSwapTheme.cardShadow,
                radius: BillSwapTheme.cardShadowRadius,
                x: 0,
                y: BillSwapTheme.cardShadowY
            )
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "doc.text.fill", title: "Bill Details")

            VStack(spacing: 16) {
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

                // Category picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Category")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(BillSwapTheme.secondaryText)

                    Menu {
                        ForEach(SwapBillCategory.allCases, id: \.self) { cat in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                category = cat
                            } label: {
                                Label(cat.displayName, systemImage: cat.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .font(.system(size: 18))
                                .foregroundColor(BillSwapTheme.categoryColor(for: category.rawValue))

                            Text(category.displayName)
                                .font(.system(size: 15))
                                .foregroundColor(BillSwapTheme.primaryText)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(BillSwapTheme.secondaryText)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(BillSwapTheme.secondaryBackground)
                        .cornerRadius(10)
                    }
                }

                // Provider field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Provider Name (Optional)")
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
            }
            .padding(16)
            .background(BillSwapTheme.cardBackground)
            .cornerRadius(BillSwapTheme.cardCornerRadius)
            .shadow(
                color: BillSwapTheme.cardShadow,
                radius: BillSwapTheme.cardShadowRadius,
                x: 0,
                y: BillSwapTheme.cardShadowY
            )
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "dollarsign.circle.fill", title: "Amount & Due Date")

            VStack(spacing: 16) {
                // Amount field
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Amount")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BillSwapTheme.secondaryText)

                        Spacer()

                        Text("Tier limit: \(formattedMaxAmount)")
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

                    // Validation messages
                    if amountCents > 0 {
                        if amountCents > maxAmountCents {
                            validationMessage(
                                "Amount exceeds your tier limit (\(formattedMaxAmount))",
                                isError: true
                            )
                        } else if amountCents < 100 {
                            validationMessage(
                                "Minimum amount is $1.00",
                                isError: true
                            )
                        } else {
                            validationMessage(
                                "Amount is within your tier limit",
                                isError: false
                            )
                        }
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
            .shadow(
                color: BillSwapTheme.cardShadow,
                radius: BillSwapTheme.cardShadowRadius,
                x: 0,
                y: BillSwapTheme.cardShadowY
            )
        }
    }

    // MARK: - Payment Info Section

    private var paymentInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "creditcard.fill", title: "Payment Info (Optional)")

            VStack(spacing: 16) {
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
                        .onChange(of: accountLast4) { oldValue, newValue in
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
            .shadow(
                color: BillSwapTheme.cardShadow,
                radius: BillSwapTheme.cardShadowRadius,
                x: 0,
                y: BillSwapTheme.cardShadowY
            )
        }
    }

    // MARK: - Swap Types Info

    private var swapTypesInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "info.circle.fill", title: "Swap Types Available")

            VStack(spacing: 12) {
                // Two-sided
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(BillSwapTheme.accentLight)
                            .frame(width: 40, height: 40)

                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 16))
                            .foregroundColor(BillSwapTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Two-Sided Swap")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BillSwapTheme.primaryText)

                        Text("Both parties pay each other's bills • Fee: $0.99 each")
                            .font(.system(size: 12))
                            .foregroundColor(BillSwapTheme.secondaryText)
                    }

                    Spacer()
                }

                Divider()

                // One-sided
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(BillSwapTheme.statusPending.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 16))
                            .foregroundColor(BillSwapTheme.statusPending)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("One-Sided Assist")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BillSwapTheme.primaryText)

                        Text("A helper pays your bill • Fee: $1.49 (helper pays)")
                            .font(.system(size: 12))
                            .foregroundColor(BillSwapTheme.secondaryText)
                    }

                    Spacer()
                }
            }
            .padding(16)
            .background(BillSwapTheme.cardBackground)
            .cornerRadius(BillSwapTheme.cardCornerRadius)
            .shadow(
                color: BillSwapTheme.cardShadow,
                radius: BillSwapTheme.cardShadowRadius,
                x: 0,
                y: BillSwapTheme.cardShadowY
            )
        }
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            createBill()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Create Bill")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isValid ? BillSwapTheme.accent : BillSwapTheme.secondaryText)
            .cornerRadius(14)
        }
        .disabled(!isValid || isCreating || isUploadingImage)
    }

    // MARK: - Helper Views

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(BillSwapTheme.accent)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(BillSwapTheme.primaryText)
        }
    }

    private func validationMessage(_ text: String, isError: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 11))

            Text(text)
                .font(.system(size: 11))
        }
        .foregroundColor(isError ? BillSwapTheme.statusDispute : BillSwapTheme.statusComplete)
    }

    // MARK: - Actions

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
                    category: category,
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

#Preview {
    CreateBillSheet(viewModel: BillSwapViewModel())
}
