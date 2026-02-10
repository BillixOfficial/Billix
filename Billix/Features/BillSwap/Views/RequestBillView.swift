//
//  RequestBillView.swift
//  Billix
//
//  View for creating a new support request (posting a bill to the Community Board)
//

import SwiftUI
import PhotosUI
import Supabase
import UniformTypeIdentifiers

// MARK: - Theme

private enum RequestTheme {
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let accent = Color(hex: "#5B8A6B")
    static let accentLight = Color(hex: "#5B8A6B").opacity(0.08)
    static let danger = Color(hex: "#E07A6B")
    static let warning = Color(hex: "#E8A54B")
}

// MARK: - Request Bill View

struct RequestBillView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RequestBillViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                RequestTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header info
                        headerCard

                        // Bill upload section (required)
                        billUploadSection

                        // Bill details form
                        billDetailsSection

                        // Guest pay link
                        guestPaySection

                        // Token cost info
                        tokenCostCard

                        // Submit button
                        submitButton

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Post Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(RequestTheme.accent)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .fullScreenCover(item: $viewModel.uploadedBill) { bill in
                RequestSuccessView(bill: bill) {
                    dismiss()
                }
            }
            // File source selection dialog
            .confirmationDialog("Upload Bill", isPresented: $viewModel.showImageSourceDialog) {
                Button("Take Photo") {
                    viewModel.showCamera = true
                }
                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    Text("Choose from Photos")
                }
                Button("Choose PDF/Document") {
                    viewModel.showDocumentPicker = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Select how you'd like to upload your bill")
            }
            // Camera sheet
            .sheet(isPresented: $viewModel.showCamera) {
                RequestBillCameraView(image: $viewModel.selectedImage)
            }
            // Document picker sheet
            .sheet(isPresented: $viewModel.showDocumentPicker) {
                RequestBillDocumentPicker { url in
                    viewModel.handleDocumentSelection(url: url)
                }
            }
            // Handle photo selection
            .onChange(of: viewModel.selectedPhotoItem) { _, newValue in
                if newValue != nil {
                    Task {
                        await viewModel.processSelectedPhoto()
                    }
                }
            }
            // Handle camera capture (triggers when camera sheet dismisses with image)
            .onChange(of: viewModel.showCamera) { _, isShowing in
                if !isShowing && viewModel.selectedImage != nil && viewModel.selectedPhotoItem == nil {
                    // Camera just closed with a captured image
                    Task {
                        await viewModel.analyzeBill()
                    }
                }
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(RequestTheme.accent.opacity(0.12))
                    .frame(width: 56, height: 56)

                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 24))
                    .foregroundColor(RequestTheme.accent)
            }

            VStack(spacing: 4) {
                Text("Request Support")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(RequestTheme.primaryText)

                Text("Post your bill to the Community Board\nand let neighbors help out")
                    .font(.system(size: 13))
                    .foregroundColor(RequestTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(RequestTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Bill Upload Section

    private var billUploadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("UPLOAD BILL")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(RequestTheme.secondaryText)
                    .tracking(0.5)

                Text("(Required)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(RequestTheme.accent)
            }

            VStack(spacing: 16) {
                if let image = viewModel.selectedImage {
                    // Show selected image
                    VStack(spacing: 12) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(RequestTheme.accent, lineWidth: 2)
                            )

                        HStack(spacing: 12) {
                            Button {
                                viewModel.showImageSourceDialog = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Change")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(RequestTheme.accent)
                            }

                            Button {
                                viewModel.clearBillImage()
                            } label: {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Remove")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(RequestTheme.danger)
                            }
                        }
                    }
                } else if let fileName = viewModel.selectedFileName {
                    // Show selected PDF/document
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(RequestTheme.accent.opacity(0.1))
                                    .frame(width: 48, height: 48)

                                Image(systemName: "doc.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(RequestTheme.accent)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(fileName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(RequestTheme.primaryText)
                                    .lineLimit(1)

                                if let data = viewModel.selectedFileData {
                                    Text("\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
                                        .font(.system(size: 12))
                                        .foregroundColor(RequestTheme.secondaryText)
                                }
                            }

                            Spacer()

                            Button {
                                viewModel.clearBillImage()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(RequestTheme.secondaryText)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        Button {
                            viewModel.showImageSourceDialog = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Change file")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(RequestTheme.accent)
                        }
                    }
                } else {
                    // Empty state - show upload button
                    Button {
                        viewModel.showImageSourceDialog = true
                    } label: {
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 2, dash: [8])
                                    )
                                    .foregroundColor(RequestTheme.accent.opacity(0.4))

                                VStack(spacing: 10) {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.system(size: 32))
                                        .foregroundColor(RequestTheme.accent)

                                    Text("Tap to upload your bill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(RequestTheme.primaryText)

                                    Text("Photo or PDF")
                                        .font(.system(size: 12))
                                        .foregroundColor(RequestTheme.secondaryText)
                                }
                            }
                            .frame(height: 140)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Analysis status indicator
                if viewModel.isAnalyzing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing bill...")
                            .font(.system(size: 13))
                            .foregroundColor(RequestTheme.secondaryText)
                    }
                    .padding(.top, 8)
                }

                if let error = viewModel.analysisError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(RequestTheme.warning)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(RequestTheme.warning)
                    }
                    .padding(10)
                    .background(RequestTheme.warning.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.top, 8)
                }

                if viewModel.analysisResult != nil && !viewModel.isAnalyzing {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(RequestTheme.accent)
                        Text("Bill analyzed - fields auto-filled")
                            .font(.system(size: 12))
                            .foregroundColor(RequestTheme.accent)
                    }
                    .padding(10)
                    .background(RequestTheme.accentLight)
                    .cornerRadius(8)
                    .padding(.top, 8)
                }

                // Help tip
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(RequestTheme.accent)

                    Text("Upload a clear photo or PDF of your bill. This helps supporters verify your request.")
                        .font(.system(size: 12))
                        .foregroundColor(RequestTheme.secondaryText)
                }
                .padding(12)
                .background(RequestTheme.accentLight)
                .cornerRadius(10)
            }
            .padding(16)
            .background(RequestTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Bill Details Section

    private var billDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BILL DETAILS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(RequestTheme.secondaryText)
                .tracking(0.5)

            VStack(spacing: 16) {
                // Category picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(RequestTheme.secondaryText)

                    Menu {
                        ForEach(SwapBillCategory.allCases, id: \.self) { category in
                            Button {
                                viewModel.selectedCategory = category
                            } label: {
                                Label(category.displayName, systemImage: category.icon)
                            }
                        }
                    } label: {
                        HStack {
                            if let category = viewModel.selectedCategory {
                                Image(systemName: category.icon)
                                    .foregroundColor(RequestTheme.accent)
                                Text(category.displayName)
                                    .foregroundColor(RequestTheme.primaryText)
                            } else {
                                Text("Select category")
                                    .foregroundColor(RequestTheme.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(RequestTheme.secondaryText)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }

                // Provider name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Provider Name")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(RequestTheme.secondaryText)

                    TextField("e.g., DTE Energy, Comcast", text: $viewModel.providerName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }

                // Amount
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Amount")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(RequestTheme.secondaryText)

                        Spacer()

                        Text("Max: \(viewModel.tierLimitFormatted)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(RequestTheme.accent)
                    }

                    HStack {
                        Text("$")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(RequestTheme.secondaryText)

                        TextField("0.00", text: $viewModel.amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    if viewModel.isAmountOverLimit {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                            Text("Amount exceeds your tier limit")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(RequestTheme.danger)
                    }
                }

                // Due date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Due Date")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(RequestTheme.secondaryText)

                    DatePicker(
                        "",
                        selection: $viewModel.dueDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding(16)
            .background(RequestTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Guest Pay Section

    private var guestPaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("GUEST PAY LINK")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(RequestTheme.secondaryText)
                    .tracking(0.5)

                Text("(Recommended)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(RequestTheme.accent)
            }

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste your utility's guest payment URL")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(RequestTheme.secondaryText)

                    TextField("https://...", text: $viewModel.guestPayLink)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }

                // Help tip
                HStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 14))
                        .foregroundColor(RequestTheme.accent)

                    Text("Guest Pay links let supporters pay your bill without seeing your account number. This is the safest way to get help.")
                        .font(.system(size: 12))
                        .foregroundColor(RequestTheme.secondaryText)
                }
                .padding(12)
                .background(RequestTheme.accentLight)
                .cornerRadius(10)
            }
            .padding(16)
            .background(RequestTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Token Cost Card

    private var tokenCostCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(RequestTheme.warning.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "token.fill")
                    .font(.system(size: 16))
                    .foregroundColor(RequestTheme.warning)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Posting costs 1 token")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RequestTheme.primaryText)

                Text("You have \(viewModel.currentTokens) token\(viewModel.currentTokens == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(RequestTheme.secondaryText)
            }

            Spacer()

            if viewModel.currentTokens < 1 {
                Text("Not enough")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(RequestTheme.danger)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RequestTheme.danger.opacity(0.12))
                    .cornerRadius(6)
            }
        }
        .padding(16)
        .background(RequestTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            Task {
                await viewModel.submitRequest()
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 16))
                    Text("Post to Community Board")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.canSubmit ? RequestTheme.accent : RequestTheme.secondaryText)
            .cornerRadius(14)
        }
        .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
    }
}

// MARK: - ViewModel

@MainActor
class RequestBillViewModel: ObservableObject {
    @Published var selectedCategory: SwapBillCategory?
    @Published var providerName = ""
    @Published var amountText = ""
    @Published var dueDate = Date()
    @Published var guestPayLink = ""

    @Published var isSubmitting = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var uploadedBill: SupportBill?  // Triggers success view when set

    @Published var currentTokens: Int = 0
    @Published var tierLimit: Decimal = 25  // Default to Neighbor tier

    // Bill upload state
    @Published var selectedImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedFileData: Data?
    @Published var selectedFileName: String?
    @Published var showImageSourceDialog = false
    @Published var showCamera = false
    @Published var showDocumentPicker = false
    @Published var isUploadingFile = false

    // Bill analysis state
    @Published var isAnalyzing = false
    @Published var analysisResult: BillAnalysis?
    @Published var analysisError: String?

    private let uploadService: BillUploadServiceProtocol = BillUploadServiceFactory.create()

    init() {
        Task {
            await loadUserData()
        }
    }

    // MARK: - Computed Properties

    var amount: Decimal? {
        guard !amountText.isEmpty else { return nil }
        return Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }

    var isAmountOverLimit: Bool {
        guard let amount = amount else { return false }
        return amount > tierLimit
    }

    var tierLimitFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: tierLimit as NSDecimalNumber) ?? "$\(tierLimit)"
    }

    var hasBillImage: Bool {
        selectedImage != nil || (selectedFileData != nil && selectedFileName != nil)
    }

    var canSubmit: Bool {
        guard let amount = amount else { return false }
        return selectedCategory != nil &&
               !providerName.isEmpty &&
               amount > 0 &&
               !isAmountOverLimit &&
               currentTokens >= 1 &&
               hasBillImage &&
               !isSubmitting
    }

    // MARK: - Methods

    func loadUserData() async {
        // Load token balance
        await TokenService.shared.loadTokenBalance()
        currentTokens = TokenService.shared.tokenBalance

        // Load tier limit
        if let tier = try? await ReputationService.shared.loadUserReputation() {
            tierLimit = Decimal(tier.reputationTier.maxAmount)
        }
    }

    // MARK: - File Upload Methods

    func processSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
                // Clear any PDF data when selecting an image
                selectedFileData = nil
                selectedFileName = nil

                // Automatically analyze the bill
                await analyzeBill()
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }

    func handleDocumentSelection(url: URL) {
        // With asCopy: true, the file is already copied to a local temp directory
        // No security-scoped access needed
        do {
            let data = try Data(contentsOf: url)
            selectedFileData = data
            selectedFileName = url.lastPathComponent
            // Clear image when selecting a document
            selectedImage = nil
            selectedPhotoItem = nil

            // Automatically analyze the bill
            Task {
                await analyzeBill()
            }
        } catch {
            print("Error reading document: \(error)")
            // Show error to user
            errorMessage = "Could not read the selected file. Please try again."
            showError = true
        }
    }

    func clearBillImage() {
        selectedImage = nil
        selectedPhotoItem = nil
        selectedFileData = nil
        selectedFileName = nil
        analysisResult = nil
        analysisError = nil
    }

    // MARK: - Bill Analysis

    func analyzeBill() async {
        guard hasBillImage else { return }

        isAnalyzing = true
        analysisError = nil

        do {
            let fileData: Data
            let fileName: String

            if let image = selectedImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                fileData = imageData
                fileName = "support-\(Int(Date().timeIntervalSince1970)).jpg"
            } else if let data = selectedFileData, let name = selectedFileName {
                fileData = data
                fileName = name
            } else {
                throw RequestBillError.noFileSelected
            }

            // Call the AI analysis API
            let analysis = try await uploadService.uploadAndAnalyzeBill(
                fileData: fileData,
                fileName: fileName,
                source: .photos
            )

            // Validate it's a real bill
            guard analysis.isValidBill() else {
                analysisError = "This doesn't appear to be a bill. Please upload a clear photo of your bill."
                isAnalyzing = false
                return
            }

            // Store analysis result
            analysisResult = analysis

            // Auto-fill form fields
            autoFillFromAnalysis(analysis)

        } catch {
            analysisError = "Could not analyze bill: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    private func autoFillFromAnalysis(_ analysis: BillAnalysis) {
        // Provider name
        if providerName.isEmpty {
            providerName = analysis.provider
        }

        // Amount
        if amountText.isEmpty {
            amountText = String(format: "%.2f", analysis.amount)
        }

        // Category - map from analysis.category string to SwapBillCategory
        if selectedCategory == nil {
            selectedCategory = mapCategoryFromAnalysis(analysis.category)
        }

        // Due date
        if let dueDateStr = analysis.dueDate,
           let parsedDate = parseDueDate(dueDateStr) {
            dueDate = parsedDate
        }
    }

    private func mapCategoryFromAnalysis(_ category: String) -> SwapBillCategory? {
        switch category.lowercased() {
        case "electric", "electricity": return .electric
        case "gas", "natural_gas", "natural gas": return .naturalGas
        case "water": return .water
        case "sewer": return .sewer
        case "trash", "garbage", "waste": return .trash
        case "internet", "wifi", "broadband": return .internet
        case "phone", "mobile", "cell", "cellular": return .phonePlan
        case "cable", "tv", "television": return .cable
        case "netflix": return .netflix
        case "spotify": return .spotify
        case "hulu": return .hulu
        case "disney", "disney+", "disney_plus": return .disneyPlus
        case "hbo", "hbo_max", "max": return .hboMax
        case "rent": return .rent
        case "mortgage": return .mortgage
        case "car_insurance", "auto_insurance": return .carInsurance
        case "health_insurance", "health": return .healthInsurance
        default: return nil  // User will need to select manually for unknown categories
        }
    }

    private func parseDueDate(_ dateString: String) -> Date? {
        // Try ISO8601 format first
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withFullDate]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        // Try common date formats
        let df = DateFormatter()
        for format in ["yyyy-MM-dd", "MM/dd/yyyy", "MMMM d, yyyy", "MMM d, yyyy"] {
            df.dateFormat = format
            if let date = df.date(from: dateString) {
                return date
            }
        }
        return nil
    }

    func uploadBillImage() async throws -> String {
        let supabase = SupabaseService.shared.client

        // Handle image upload
        if let image = selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            let filename = "bill_\(UUID().uuidString)_\(Int(Date().timeIntervalSince1970)).jpg"

            try await supabase.storage
                .from("bills")
                .upload(
                    path: "support/\(filename)",
                    file: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg"
                    )
                )

            let publicUrl = try supabase.storage
                .from("bills")
                .getPublicURL(path: "support/\(filename)")

            return publicUrl.absoluteString
        }

        // Handle PDF/document upload
        if let fileData = selectedFileData, let fileName = selectedFileName {
            let ext = (fileName as NSString).pathExtension.lowercased()
            let uniqueFileName = "bill_\(UUID().uuidString)_\(Int(Date().timeIntervalSince1970)).\(ext)"
            let contentType = getMimeType(for: fileName)

            try await supabase.storage
                .from("bills")
                .upload(
                    path: "support/\(uniqueFileName)",
                    file: fileData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: contentType
                    )
                )

            let publicUrl = try supabase.storage
                .from("bills")
                .getPublicURL(path: "support/\(uniqueFileName)")

            return publicUrl.absoluteString
        }

        throw RequestBillError.noFileSelected
    }

    private func getMimeType(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "application/pdf"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "heic": return "image/heic"
        default: return "application/octet-stream"
        }
    }

    func submitRequest() async {
        guard canSubmit, let amount = amount, let category = selectedCategory else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            guard let userId = AuthService.shared.currentUser?.id else {
                throw ConnectionError.notAuthenticated
            }

            // Upload bill image first
            isUploadingFile = true
            let imageUrl = try await uploadBillImage()
            isUploadingFile = false

            // Create the support bill with image URL and analysis data
            // NOTE: Connection is NOT created here - user selects type in success view
            let bill = try await createSupportBill(
                userId: userId,
                amount: amount,
                category: category,
                providerName: providerName,
                dueDate: dueDate,
                guestPayLink: guestPayLink.isEmpty ? nil : guestPayLink,
                imageUrl: imageUrl,
                analysisResult: analysisResult
            )

            // Show success view with connection type selection
            uploadedBill = bill
        } catch {
            isUploadingFile = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func createSupportBill(
        userId: UUID,
        amount: Decimal,
        category: SwapBillCategory,
        providerName: String,
        dueDate: Date,
        guestPayLink: String?,
        imageUrl: String?,
        analysisResult: BillAnalysis?
    ) async throws -> SupportBill {
        let supabase = SupabaseService.shared.client

        // Get user's zip code from profile
        let profile: RequestProfileZipData? = try? await supabase
            .from("profiles")
            .select("zip_code")
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        // Create analysis data if available
        let analysisData: SupportBillAnalysisData? = analysisResult.map {
            SupportBillAnalysisData(from: $0)
        }

        let insertData = SupportBillInsert(
            userId: userId,
            providerName: providerName,
            category: category.rawValue,
            amount: amount,
            dueDate: dueDate,
            guestPayLink: guestPayLink,
            status: "posted",
            zipCode: profile?.zipCode,
            imageUrl: imageUrl,
            billAnalysis: analysisData,
            isVerified: analysisData != nil,
            verifiedAt: analysisData != nil ? Date() : nil
        )

        let bill: SupportBill = try await supabase
            .from("support_bills")
            .insert(insertData)
            .select()
            .single()
            .execute()
            .value

        return bill
    }
}

// MARK: - Support Models

private struct SupportBillInsert: Encodable {
    let userId: UUID
    let providerName: String
    let category: String
    let amount: Decimal
    let dueDate: Date
    let guestPayLink: String?
    let status: String
    let zipCode: String?
    let imageUrl: String?
    let billAnalysis: SupportBillAnalysisData?
    let isVerified: Bool
    let verifiedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case providerName = "provider_name"
        case category
        case amount
        case dueDate = "due_date"
        case guestPayLink = "guest_pay_link"
        case status
        case zipCode = "zip_code"
        case imageUrl = "image_url"
        case billAnalysis = "bill_analysis"
        case isVerified = "is_verified"
        case verifiedAt = "verified_at"
    }
}

// MARK: - Request Bill Error

enum RequestBillError: LocalizedError {
    case noFileSelected
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .noFileSelected:
            return "Please upload a photo or PDF of your bill"
        case .uploadFailed(let message):
            return "Failed to upload bill: \(message)"
        }
    }
}

private struct RequestProfileZipData: Decodable {
    let zipCode: String?

    enum CodingKeys: String, CodingKey {
        case zipCode = "zip_code"
    }
}

// MARK: - Camera View

struct RequestBillCameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: RequestBillCameraView

        init(_ parent: RequestBillCameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Document Picker

struct RequestBillDocumentPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onDocumentSelected: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Use asCopy mode to import files (copies to local temp directory)
        // This handles iCloud files and external providers that may not be downloaded
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image, .jpeg, .png], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: RequestBillDocumentPicker

        init(_ parent: RequestBillDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentSelected(url)
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    RequestBillView()
}
