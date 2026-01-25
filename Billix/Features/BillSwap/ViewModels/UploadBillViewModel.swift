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

    // MARK: - Services
    private let billService = SwapBillService.shared

    // MARK: - Computed Properties

    var hasImage: Bool {
        capturedImage != nil
    }

    var canSubmit: Bool {
        !amount.isEmpty && Decimal(string: amount) != nil
    }

    var amountDecimal: Decimal? {
        Decimal(string: amount)
    }

    // MARK: - Image Handling

    /// Process captured image with OCR
    func processImage(_ image: UIImage) async {
        capturedImage = image
        isProcessing = true
        error = nil

        do {
            let result = try await billService.uploadBillForOCR(image: image)

            // Apply extracted values
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
                // Try to auto-detect category
                self.category = detectCategory(from: extractedProvider)
            }

            if let extractedAccount = result.accountNumber {
                self.extractedAccountNumber = extractedAccount
                self.accountNumber = extractedAccount
            }

        } catch {
            self.error = error
            self.showError = true
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

            // Create the bill
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
        amount = ""
        dueDate = Date()
        providerName = ""
        category = .electric
        accountNumber = ""
        guestPayLink = ""
        zipCode = ""
        uploadComplete = false
        error = nil
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
