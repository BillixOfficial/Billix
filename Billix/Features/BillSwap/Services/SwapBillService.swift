//
//  SwapBillService.swift
//  Billix
//
//  Service for managing bills in the swap marketplace
//

import Foundation
import UIKit
import Supabase

/// Service for bill upload, fetching, and OCR operations
@MainActor
class SwapBillService: ObservableObject {

    // MARK: - Singleton
    static let shared = SwapBillService()

    // MARK: - Published Properties
    @Published var myBills: [SwapBill] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentUserId: UUID? {
        AuthService.shared.currentUser?.id
    }

    private init() {}

    // MARK: - Tier Validation

    /// Get the current user's swap tier (1-4)
    func getUserTier() async throws -> Int {
        guard let userId = currentUserId else {
            throw SwapBillError.notAuthenticated
        }

        struct TierResult: Decodable {
            let tier: Int?
        }

        do {
            let result: TierResult = try await supabase
                .from("swap_trust")
                .select("tier")
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            return result.tier ?? 1
        } catch {
            // If no record exists, user is Tier 1
            return 1
        }
    }

    /// Validate that the bill amount is within the user's tier limit
    func validateTierLimit(amount: Decimal) async throws {
        let tier = try await getUserTier()
        let maxAllowed = SwapTheme.Tiers.maxAmount(for: tier)

        guard amount <= maxAllowed else {
            throw SwapBillError.amountExceedsTierLimit(
                amount: amount,
                limit: maxAllowed,
                tier: tier
            )
        }
    }

    // MARK: - Bill CRUD Operations

    /// Fetch all bills for the current user
    func fetchMyBills() async throws {
        guard let userId = currentUserId else {
            throw SwapBillError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let bills: [SwapBill] = try await supabase
            .from("swap_bills")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        self.myBills = bills
    }

    /// Create a new bill
    /// - Important: Validates bill amount against user's tier limit BEFORE creating
    func createBill(
        amount: Decimal,
        dueDate: Date?,
        providerName: String?,
        category: SwapBillCategory?,
        zipCode: String?,
        accountNumber: String?,
        guestPayLink: String?,
        imageUrl: String? = nil
    ) async throws -> SwapBill {
        guard let userId = currentUserId else {
            throw SwapBillError.notAuthenticated
        }

        // TIER VALIDATION - Prevent bills above user's tier limit
        try await validateTierLimit(amount: amount)

        let newBill = SwapBillInsert(
            userId: userId,
            amount: amount,
            dueDate: dueDate,
            providerName: providerName,
            category: category?.rawValue,
            zipCode: zipCode,
            accountNumber: accountNumber,
            guestPayLink: guestPayLink,
            imageUrl: imageUrl
        )

        let bill: SwapBill = try await supabase
            .from("swap_bills")
            .insert(newBill)
            .select()
            .single()
            .execute()
            .value

        // Update local cache
        myBills.insert(bill, at: 0)

        return bill
    }

    /// Update bill status
    func updateBillStatus(billId: UUID, status: SwapBillStatus) async throws {
        try await supabase
            .from("swap_bills")
            .update(["status": status.rawValue])
            .eq("id", value: billId.uuidString)
            .execute()

        // Update local cache
        if let index = myBills.firstIndex(where: { $0.id == billId }) {
            myBills[index].status = status
        }
    }

    /// Delete a bill
    func deleteBill(billId: UUID) async throws {
        try await supabase
            .from("swap_bills")
            .delete()
            .eq("id", value: billId.uuidString)
            .execute()

        // Update local cache
        myBills.removeAll { $0.id == billId }
    }

    /// Get a specific bill by ID
    func getBill(id: UUID) async throws -> SwapBill {
        let bill: SwapBill = try await supabase
            .from("swap_bills")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return bill
    }

    // MARK: - Image Upload

    /// Upload bill image to Supabase Storage
    func uploadBillImage(_ image: UIImage) async throws -> String {
        guard let userId = currentUserId else {
            throw SwapBillError.notAuthenticated
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SwapBillError.imageConversionFailed
        }

        let fileName = "\(userId.uuidString)/\(UUID().uuidString).jpg"

        try await supabase.storage
            .from("swap-bill-images")
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        // Get public URL
        let publicUrl = try supabase.storage
            .from("swap-bill-images")
            .getPublicURL(path: fileName)

        return publicUrl.absoluteString
    }

    // MARK: - OCR Upload (Backend API)

    /// Upload bill to backend for OCR processing (basic result)
    func uploadBillForOCR(image: UIImage) async throws -> BillOCRResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SwapBillError.imageConversionFailed
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: Config.billUploadEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"bill.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SwapBillError.ocrFailed
        }

        let result = try JSONDecoder().decode(BillOCRResult.self, from: data)
        return result
    }

    /// Upload bill for full OCR analysis using BillUploadService
    /// Returns complete BillAnalysis with verification status
    func uploadBillForFullAnalysis(image: UIImage) async throws -> BillAnalysis {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SwapBillError.imageConversionFailed
        }

        let uploadService = BillUploadServiceFactory.create()
        let analysis = try await uploadService.uploadAndAnalyzeBill(
            fileData: imageData,
            fileName: "swap_\(UUID().uuidString).jpg",
            source: .camera
        )

        return analysis
    }

    /// Create a verified bill with full analysis data
    /// - Important: Validates bill amount against user's tier limit BEFORE creating
    func createVerifiedBill(
        amount: Decimal,
        dueDate: Date?,
        providerName: String?,
        category: SwapBillCategory?,
        zipCode: String?,
        accountNumber: String?,
        guestPayLink: String?,
        imageUrl: String?,
        billAnalysis: BillAnalysis
    ) async throws -> SwapBill {
        guard let userId = currentUserId else {
            throw SwapBillError.notAuthenticated
        }

        // TIER VALIDATION - Prevent bills above user's tier limit
        try await validateTierLimit(amount: amount)

        // Create BillAnalysisData from full analysis
        let analysisData = BillAnalysisData(from: billAnalysis)

        let newBill = SwapBillInsertVerified(
            userId: userId,
            amount: amount,
            dueDate: dueDate,
            providerName: providerName,
            category: category?.rawValue,
            zipCode: zipCode,
            accountNumber: accountNumber,
            guestPayLink: guestPayLink,
            imageUrl: imageUrl,
            billAnalysis: analysisData,
            isVerified: true,
            verifiedAt: Date()
        )

        let bill: SwapBill = try await supabase
            .from("swap_bills")
            .insert(newBill)
            .select()
            .single()
            .execute()
            .value

        // Update local cache
        myBills.insert(bill, at: 0)

        return bill
    }
}

// MARK: - Insert Model for Verified Bills

/// Insert model for creating verified bills with OCR analysis
private struct SwapBillInsertVerified: Encodable {
    let userId: UUID
    let amount: Decimal
    let dueDate: Date?
    let providerName: String?
    let category: String?
    let zipCode: String?
    let accountNumber: String?
    let guestPayLink: String?
    let imageUrl: String?
    let billAnalysis: BillAnalysisData?
    let isVerified: Bool
    let verifiedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case amount
        case dueDate = "due_date"
        case providerName = "provider_name"
        case category
        case zipCode = "zip_code"
        case accountNumber = "account_number"
        case guestPayLink = "guest_pay_link"
        case imageUrl = "image_url"
        case billAnalysis = "bill_analysis"
        case isVerified = "is_verified"
        case verifiedAt = "verified_at"
    }
}

// MARK: - Supporting Types

/// Insert model for creating new bills
private struct SwapBillInsert: Encodable {
    let userId: UUID
    let amount: Decimal
    let dueDate: Date?
    let providerName: String?
    let category: String?
    let zipCode: String?
    let accountNumber: String?
    let guestPayLink: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case amount
        case dueDate = "due_date"
        case providerName = "provider_name"
        case category
        case zipCode = "zip_code"
        case accountNumber = "account_number"
        case guestPayLink = "guest_pay_link"
        case imageUrl = "image_url"
    }
}

/// OCR extraction result from backend
struct BillOCRResult: Codable {
    let amount: Decimal?
    let dueDate: Date?
    let providerName: String?
    let accountNumber: String?
    let confidence: Double?

    enum CodingKeys: String, CodingKey {
        case amount
        case dueDate = "due_date"
        case providerName = "provider_name"
        case accountNumber = "account_number"
        case confidence
    }
}

/// Errors for SwapBillService
enum SwapBillError: LocalizedError {
    case notAuthenticated
    case imageConversionFailed
    case ocrFailed
    case uploadFailed
    case amountExceedsTierLimit(amount: Decimal, limit: Decimal, tier: Int)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .imageConversionFailed:
            return "Failed to process the image"
        case .ocrFailed:
            return "Failed to extract bill information"
        case .uploadFailed:
            return "Failed to upload the bill"
        case .amountExceedsTierLimit(let amount, let limit, let tier):
            let tierName = SwapTheme.Tiers.tierName(tier)
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            let amountStr = formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
            let limitStr = formatter.string(from: limit as NSDecimalNumber) ?? "$\(limit)"
            return "Your bill amount (\(amountStr)) exceeds your \(tierName) tier limit of \(limitStr). Complete more swaps to increase your limit."
        }
    }
}
