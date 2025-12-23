//
//  BillReceiptExchangeService.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Service for uploading paid bill receipts to earn credits
//

import Foundation
import Supabase
import UIKit

// MARK: - Receipt Service Errors

enum ReceiptServiceError: LocalizedError {
    case notAuthenticated
    case uploadFailed
    case storageFailed
    case verificationFailed
    case limitExceeded
    case invalidReceipt

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .uploadFailed:
            return "Failed to upload receipt"
        case .storageFailed:
            return "Failed to save receipt image"
        case .verificationFailed:
            return "Receipt verification failed"
        case .limitExceeded:
            return "Upload limit reached. Try again later."
        case .invalidReceipt:
            return "Invalid receipt data"
        }
    }
}

// MARK: - Bill Receipt Exchange Service

@MainActor
class BillReceiptExchangeService: ObservableObject {

    // MARK: - Singleton
    static let shared = BillReceiptExchangeService()

    // MARK: - Published Properties
    @Published var receipts: [BillReceipt] = []
    @Published var statistics: ReceiptStatistics = .empty
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var creditsService: UnlockCreditsService {
        UnlockCreditsService.shared
    }

    // MARK: - Initialization

    private init() {
        Task {
            await loadReceipts()
        }
    }

    // MARK: - Load Receipts

    /// Loads user's receipts from Supabase
    func loadReceipts() async {
        guard let session = try? await supabase.auth.session else {
            receipts = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedReceipts: [BillReceipt] = try await supabase
                .from("bill_receipts")
                .select()
                .eq("user_id", value: session.user.id.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            receipts = fetchedReceipts
            await calculateStatistics()

        } catch {
            print("Failed to load receipts: \(error)")
        }
    }

    // MARK: - Upload Receipt

    /// Uploads a new bill receipt
    func uploadReceipt(_ request: ReceiptUploadRequest) async throws -> BillReceipt {
        guard let session = try? await supabase.auth.session else {
            throw ReceiptServiceError.notAuthenticated
        }

        // Validate request
        try validateRequest(request)

        // Check upload limits
        try await checkUploadLimits(userId: session.user.id)

        isUploading = true
        uploadProgress = 0
        defer {
            isUploading = false
            uploadProgress = 0
        }

        // Upload image to storage
        uploadProgress = 0.2
        let imageUrl = try await uploadImage(request.imageData, userId: session.user.id)

        uploadProgress = 0.5

        // Create receipt record
        let dateFormatter = ISO8601DateFormatter()
        let paidDateString = dateFormatter.string(from: request.paidDate)

        let insert = BillReceiptInsert(
            userId: session.user.id.uuidString,
            billCategory: request.category.rawValue,
            providerName: request.providerName,
            amount: request.amount,
            paidDate: paidDateString,
            screenshotUrl: imageUrl,
            ocrVerified: false,
            creditsEarned: 0, // Will be updated after verification
            status: ReceiptStatus.pending.rawValue
        )

        uploadProgress = 0.7

        do {
            let insertedReceipts: [BillReceipt] = try await supabase
                .from("bill_receipts")
                .insert(insert)
                .select()
                .execute()
                .value

            guard let receipt = insertedReceipts.first else {
                throw ReceiptServiceError.uploadFailed
            }

            uploadProgress = 0.9

            // Trigger auto-verification (simplified - in production would use Vision API)
            await autoVerifyReceipt(receipt)

            uploadProgress = 1.0

            // Reload receipts
            await loadReceipts()

            return receipt

        } catch {
            throw ReceiptServiceError.uploadFailed
        }
    }

    // MARK: - Image Upload

    /// Uploads image to Supabase Storage
    private func uploadImage(_ imageData: Data, userId: UUID) async throws -> String {
        let fileName = "\(userId.uuidString)/\(UUID().uuidString).jpg"

        do {
            // Compress image if needed
            let compressedData = compressImage(imageData)

            // Upload to storage using newer API
            _ = try await supabase.storage
                .from("receipts")
                .upload(fileName, data: compressedData, options: FileOptions(contentType: "image/jpeg"))

            // Get public URL
            let publicUrl = try supabase.storage
                .from("receipts")
                .getPublicURL(path: fileName)

            return publicUrl.absoluteString

        } catch {
            throw ReceiptServiceError.storageFailed
        }
    }

    /// Compresses image to reduce file size
    private func compressImage(_ data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }

        // Target max dimension of 1500px
        let maxDimension: CGFloat = 1500
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)

        if scale < 1.0 {
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )

            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resized = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            if let resized = resized, let compressed = resized.jpegData(compressionQuality: 0.8) {
                return compressed
            }
        }

        return image.jpegData(compressionQuality: 0.8) ?? data
    }

    // MARK: - Auto Verification

    /// Auto-verifies receipt (simplified - would use OCR in production)
    private func autoVerifyReceipt(_ receipt: BillReceipt) async {
        // In production, this would:
        // 1. Use Vision API for OCR
        // 2. Extract amount, date, provider from image
        // 3. Compare with user-submitted data
        // 4. Calculate confidence score

        // For now, simulate verification with a delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Auto-approve receipts (in production, would have real verification)
        await verifyReceipt(receiptId: receipt.id, approved: true)
    }

    /// Manually verifies or rejects a receipt
    func verifyReceipt(receiptId: UUID, approved: Bool, rejectionReason: String? = nil) async {
        guard let session = try? await supabase.auth.session else { return }

        let status: ReceiptStatus = approved ? .verified : .rejected
        let creditsEarned = approved ? (receipts.first { $0.id == receiptId }?.category?.creditsEarned ?? 10) : 0

        do {
            let update = BillReceiptUpdate(
                status: status.rawValue,
                ocrVerified: approved,
                creditsEarned: creditsEarned,
                rejectionReason: rejectionReason,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            try await supabase
                .from("bill_receipts")
                .update(update)
                .eq("id", value: receiptId.uuidString)
                .execute()

            // Award credits if approved
            if approved && creditsEarned > 0 {
                try await creditsService.earnCredits(
                    creditsEarned,
                    type: UnlockCreditType.receiptUpload,
                    description: "Receipt verified",
                    referenceId: receiptId
                )
            }

            // Reload receipts
            await loadReceipts()

        } catch {
            print("Failed to verify receipt: \(error)")
        }
    }

    // MARK: - Validation

    /// Validates upload request
    private func validateRequest(_ request: ReceiptUploadRequest) throws {
        // Check image size
        if request.imageData.count > ReceiptLimits.maxImageSizeBytes {
            throw ReceiptValidationError.imageTooLarge
        }

        // Check amount
        if request.amount < ReceiptLimits.minAmount {
            throw ReceiptValidationError.amountTooLow
        }

        if request.amount > ReceiptLimits.maxAmount {
            throw ReceiptValidationError.amountTooHigh
        }

        // Check date
        let calendar = Calendar.current
        let maxAgeDate = calendar.date(byAdding: .day, value: -ReceiptLimits.maxAgeDays, to: Date())!

        if request.paidDate < maxAgeDate {
            throw ReceiptValidationError.dateTooOld
        }

        if request.paidDate > Date() {
            throw ReceiptValidationError.dateInFuture
        }
    }

    /// Checks upload limits
    private func checkUploadLimits(userId: UUID) async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!

        // Count today's uploads
        let todayReceipts = receipts.filter { calendar.isDate($0.createdAt, inSameDayAs: today) }
        if todayReceipts.count >= ReceiptLimits.maxUploadsPerDay {
            throw ReceiptServiceError.limitExceeded
        }

        // Count this month's uploads
        let monthReceipts = receipts.filter { $0.createdAt >= monthStart }
        if monthReceipts.count >= ReceiptLimits.maxUploadsPerMonth {
            throw ReceiptServiceError.limitExceeded
        }
    }

    // MARK: - Statistics

    /// Calculates receipt statistics
    private func calculateStatistics() async {
        let verified = receipts.filter { $0.status == .verified }
        let totalCredits = verified.reduce(0) { $0 + $1.creditsEarned }

        var categoryCounts: [ReceiptBillCategory: Int] = [:]
        for receipt in receipts {
            if let category = receipt.category {
                categoryCounts[category, default: 0] += 1
            }
        }

        let totalAmount = receipts.reduce(Decimal(0)) { $0 + $1.amount }
        let avgAmount = receipts.isEmpty ? Decimal(0) : totalAmount / Decimal(receipts.count)

        statistics = ReceiptStatistics(
            totalUploaded: receipts.count,
            totalVerified: verified.count,
            totalCreditsEarned: totalCredits,
            categoryCounts: categoryCounts,
            averageAmount: avgAmount
        )
    }

    // MARK: - Filter Receipts

    /// Filters receipts by status
    func filteredReceipts(by filter: ReceiptFilter) -> [BillReceipt] {
        if filter == .all {
            return receipts
        }
        return receipts.filter { filter.statuses.contains($0.status) }
    }

    /// Gets receipts by category
    func receipts(for category: ReceiptBillCategory) -> [BillReceipt] {
        receipts.filter { $0.category == category }
    }

    // MARK: - Delete Receipt

    /// Deletes a receipt (only pending ones can be deleted)
    func deleteReceipt(_ receiptId: UUID) async throws {
        guard let receipt = receipts.first(where: { $0.id == receiptId }) else {
            return
        }

        // Only allow deleting pending receipts
        guard receipt.status == .pending else {
            return
        }

        try await supabase
            .from("bill_receipts")
            .delete()
            .eq("id", value: receiptId.uuidString)
            .execute()

        // Delete image from storage
        if let fileName = extractFileName(from: receipt.screenshotUrl) {
            _ = try? await supabase.storage
                .from("receipts")
                .remove(paths: [fileName])
        }

        await loadReceipts()
    }

    /// Extracts filename from URL
    private func extractFileName(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let components = url.pathComponents
        guard components.count >= 2 else { return nil }
        return components.suffix(2).joined(separator: "/")
    }

    // MARK: - Reset

    func reset() {
        receipts = []
        statistics = .empty
    }
}

// MARK: - Preview Helpers

extension BillReceiptExchangeService {
    static func mockWithReceipts() -> BillReceiptExchangeService {
        let service = BillReceiptExchangeService.shared
        // Add mock data for previews
        return service
    }
}
