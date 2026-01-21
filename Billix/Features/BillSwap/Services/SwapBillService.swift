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

    /// Upload bill to backend for OCR processing
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
        }
    }
}
