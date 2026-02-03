//
//  UploadBillViewModel.swift
//  Billix
//
//  ViewModel for bill upload and OCR extraction
//

import Foundation
import UIKit
import Combine

/// ViewModel for uploading bills with OCR extraction
@MainActor
class UploadBillViewModel: ObservableObject {

    // MARK: - Published Properties

    // Image capture
    @Published var capturedImage: UIImage?
    @Published var showImagePicker = false
    @Published var showCamera = false

    // OCR results
    @Published var extractedAmount: Decimal?
    @Published var extractedDueDate: Date?
    @Published var extractedProvider: String?
    @Published var extractedAccountNumber: String?
    @Published var extractedCategory: String?

    // Full OCR analysis for verification
    @Published var fullBillAnalysis: BillAnalysis?
    @Published var isVerified: Bool = false

    // User editable fields
    @Published var amount: String = ""
    @Published var dueDate: Date = Date()
    @Published var providerName: String = ""
    @Published var category: SwapBillCategory = .electric
    @Published var accountNumber: String = ""
    @Published var guestPayLink: String = ""
    @Published var zipCode: String = ""

    // State
    @Published var isProcessing = false
    @Published var isUploading = false
    @Published var error: Error?
    @Published var showError = false
    @Published var uploadComplete = false

    // Tier limit tracking
    @Published var currentTier: Int = 1
    @Published var tierLimit: Decimal = 25
    @Published var tierLimitError: String?
    @Published var isLoadingTierInfo = false

    // MARK: - Services
    private let billService = SwapBillService.shared

    // MARK: - Computed Properties

    var hasImage: Bool {
        capturedImage != nil
    }

    var canSubmit: Bool {
        guard !amount.isEmpty, let amountVal = Decimal(string: amount) else { return false }
        // Check tier limit - cannot submit if over limit
        return amountVal <= tierLimit && tierLimitError == nil
    }

    var amountDecimal: Decimal? {
        Decimal(string: amount)
    }

    /// Formatted tier limit for display
    var formattedTierLimit: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: tierLimit as NSDecimalNumber) ?? "$\(tierLimit)"
    }

    /// Whether the current amount exceeds tier limit
    var isOverTierLimit: Bool {
        guard let amountVal = amountDecimal else { return false }
        return amountVal > tierLimit
    }

    // MARK: - Tier Management

    /// Fetch user's current tier and limit
    func fetchTierInfo() async {
        isLoadingTierInfo = true
        do {
            currentTier = try await billService.getUserTier()
            tierLimit = SwapTheme.Tiers.maxAmount(for: currentTier)
            // Validate current amount against new tier info
            validateAmountAgainstTier()
        } catch {
            // Default to Tier 1 if fetch fails
            currentTier = 1
            tierLimit = 25
        }
        isLoadingTierInfo = false
    }

    /// Validate amount against tier limit and set error message if exceeded
    func validateAmountAgainstTier() {
        guard let amountVal = amountDecimal else {
            tierLimitError = nil
            return
        }

        if amountVal > tierLimit {
            let tierName = SwapTheme.Tiers.tierName(currentTier)
            tierLimitError = "Your \(tierName) tier allows bills up to \(formattedTierLimit). Complete more swaps to increase your limit."
        } else {
            tierLimitError = nil
        }
    }

    /// Called when amount field changes
    func amountDidChange() {
        validateAmountAgainstTier()
    }

    // MARK: - Image Handling

    /// Process captured image with full OCR analysis
    func processImage(_ image: UIImage) async {
        capturedImage = image
        isProcessing = true
        error = nil

        do {
            // Use full analysis for verified listings
            let analysis = try await billService.uploadBillForFullAnalysis(image: image)

            // Store full analysis for verification
            self.fullBillAnalysis = analysis
            self.isVerified = true

            // Apply extracted values from full analysis
            self.extractedAmount = Decimal(analysis.amount)
            self.amount = String(format: "%.2f", analysis.amount)

            // Validate extracted amount against tier limit
            self.validateAmountAgainstTier()

            // Parse due date from string
            if let dueDateStr = analysis.dueDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let parsed = formatter.date(from: dueDateStr) {
                    self.extractedDueDate = parsed
                    self.dueDate = parsed
                }
            }

            // Apply provider
            self.extractedProvider = analysis.provider
            self.providerName = analysis.provider

            // Apply category from analysis
            self.extractedCategory = analysis.category
            if let swapCategory = SwapBillCategory(rawValue: analysis.category.lowercased()) {
                self.category = swapCategory
            } else {
                // Fallback to detection from provider name
                self.category = detectCategory(from: analysis.provider)
            }

            // Apply account number if available
            if let extractedAccount = analysis.accountNumber {
                self.extractedAccountNumber = extractedAccount
                self.accountNumber = extractedAccount
            }

            // Apply zip code if available
            if let zip = analysis.zipCode {
                self.zipCode = zip
            }

        } catch {
            // Fall back to basic OCR if full analysis fails
            do {
                let result = try await billService.uploadBillForOCR(image: image)

                if let extractedAmount = result.amount {
                    self.extractedAmount = extractedAmount
                    self.amount = "\(extractedAmount)"
                }

                if let extractedDueDate = result.dueDate {
                    self.extractedDueDate = extractedDueDate
                    self.dueDate = extractedDueDate
                }

                if let extractedProvider = result.providerName {
                    self.extractedProvider = extractedProvider
                    self.providerName = extractedProvider
                    self.category = detectCategory(from: extractedProvider)
                }

                if let extractedAccount = result.accountNumber {
                    self.extractedAccountNumber = extractedAccount
                    self.accountNumber = extractedAccount
                }

                // Not verified since we couldn't get full analysis
                self.isVerified = false
                self.fullBillAnalysis = nil
            } catch {
                self.error = error
                self.showError = true
            }
        }

        isProcessing = false
    }

    /// Clear captured image
    func clearImage() {
        capturedImage = nil
        extractedAmount = nil
        extractedDueDate = nil
        extractedProvider = nil
        extractedAccountNumber = nil
        extractedCategory = nil
        fullBillAnalysis = nil
        isVerified = false
    }

    // MARK: - Bill Submission

    /// Submit the bill for swap
    func submitBill() async {
        guard let amountDecimal = amountDecimal else {
            error = SwapUploadError.invalidAmount
            showError = true
            return
        }

        isUploading = true
        error = nil

        do {
            // Upload image if present
            var imageUrl: String?
            if let image = capturedImage {
                imageUrl = try await billService.uploadBillImage(image)
            }

            // Create verified bill if we have full analysis, otherwise create regular bill
            if let analysis = fullBillAnalysis {
                _ = try await billService.createVerifiedBill(
                    amount: amountDecimal,
                    dueDate: dueDate,
                    providerName: providerName.isEmpty ? nil : providerName,
                    category: category,
                    zipCode: zipCode.isEmpty ? nil : zipCode,
                    accountNumber: accountNumber.isEmpty ? nil : accountNumber,
                    guestPayLink: guestPayLink.isEmpty ? nil : guestPayLink,
                    imageUrl: imageUrl,
                    billAnalysis: analysis
                )
            } else {
                // Create regular unverified bill
                _ = try await billService.createBill(
                    amount: amountDecimal,
                    dueDate: dueDate,
                    providerName: providerName.isEmpty ? nil : providerName,
                    category: category,
                    zipCode: zipCode.isEmpty ? nil : zipCode,
                    accountNumber: accountNumber.isEmpty ? nil : accountNumber,
                    guestPayLink: guestPayLink.isEmpty ? nil : guestPayLink,
                    imageUrl: imageUrl
                )
            }

            uploadComplete = true
        } catch {
            self.error = error
            self.showError = true
        }

        isUploading = false
    }

    // MARK: - Helper Methods

    /// Reset form
    func reset() {
        capturedImage = nil
        extractedAmount = nil
        extractedDueDate = nil
        extractedProvider = nil
        extractedAccountNumber = nil
        extractedCategory = nil
        fullBillAnalysis = nil
        isVerified = false
        amount = ""
        dueDate = Date()
        providerName = ""
        category = .electric
        accountNumber = ""
        guestPayLink = ""
        zipCode = ""
        uploadComplete = false
        error = nil
        tierLimitError = nil
    }

    /// Detect category from provider name
    private func detectCategory(from provider: String) -> SwapBillCategory {
        let lowercased = provider.lowercased()

        if lowercased.contains("electric") || lowercased.contains("dte") || lowercased.contains("consumers") {
            return .electric
        } else if lowercased.contains("gas") || lowercased.contains("propane") {
            return .naturalGas
        } else if lowercased.contains("water") {
            return .water
        } else if lowercased.contains("comcast") || lowercased.contains("xfinity") || lowercased.contains("att") ||
                    lowercased.contains("verizon") || lowercased.contains("spectrum") || lowercased.contains("internet") {
            return .internet
        } else if lowercased.contains("phone") || lowercased.contains("mobile") || lowercased.contains("cellular") {
            return .phonePlan
        } else if lowercased.contains("renter") && lowercased.contains("insurance") {
            return .rentersInsurance
        } else if lowercased.contains("car") && lowercased.contains("insurance") {
            return .carInsurance
        } else if lowercased.contains("health") && lowercased.contains("insurance") {
            return .healthInsurance
        } else if lowercased.contains("home") && lowercased.contains("insurance") {
            return .homeInsurance
        } else if lowercased.contains("netflix") {
            return .netflix
        } else if lowercased.contains("spotify") {
            return .spotify
        } else if lowercased.contains("disney") {
            return .disneyPlus
        } else if lowercased.contains("hulu") {
            return .hulu
        }

        return .electric // Default to a common category
    }
}

// MARK: - Errors

enum SwapUploadError: LocalizedError {
    case invalidAmount
    case imageRequired
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Please enter a valid amount"
        case .imageRequired:
            return "Please capture or select a bill image"
        case .uploadFailed:
            return "Failed to upload bill. Please try again."
        }
    }
}
