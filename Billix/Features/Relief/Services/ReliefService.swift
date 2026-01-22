//
//  ReliefService.swift
//  Billix
//
//  Service for managing relief requests
//

import Foundation
import UIKit
import Supabase

/// Service for managing relief requests
@MainActor
class ReliefService: ObservableObject {

    // MARK: - Singleton
    static let shared = ReliefService()

    // MARK: - Published Properties
    @Published var myRequests: [ReliefRequest] = []
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

    // MARK: - CRUD Operations

    /// Fetch all relief requests for the current user
    func fetchMyRequests() async throws {
        guard let userId = currentUserId else {
            throw ReliefError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let requests: [ReliefRequest] = try await supabase
            .from("relief_requests")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        self.myRequests = requests
    }

    /// Create a new relief request
    func createRequest(
        fullName: String,
        email: String,
        phone: String?,
        billType: ReliefBillType,
        billProvider: String?,
        amountOwed: Decimal,
        description: String?,
        incomeLevel: ReliefIncomeLevel,
        householdSize: Int,
        employmentStatus: ReliefEmploymentStatus,
        urgencyLevel: ReliefUrgencyLevel,
        utilityShutoffDate: Date?
    ) async throws -> ReliefRequest {
        guard let userId = currentUserId else {
            throw ReliefError.notAuthenticated
        }

        let insertData = ReliefRequestInsert(
            userId: userId,
            fullName: fullName,
            email: email,
            phone: phone,
            billType: billType.rawValue,
            billProvider: billProvider,
            amountOwed: amountOwed,
            description: description,
            incomeLevel: incomeLevel.rawValue,
            householdSize: householdSize,
            employmentStatus: employmentStatus.rawValue,
            urgencyLevel: urgencyLevel.rawValue,
            utilityShutoffDate: utilityShutoffDate
        )

        let request: ReliefRequest = try await supabase
            .from("relief_requests")
            .insert(insertData)
            .select()
            .single()
            .execute()
            .value

        // Update local cache
        myRequests.insert(request, at: 0)

        return request
    }

    /// Cancel a pending relief request
    func cancelRequest(requestId: UUID) async throws {
        try await supabase
            .from("relief_requests")
            .update(["status": "cancelled"])
            .eq("id", value: requestId.uuidString)
            .eq("status", value: "pending") // Can only cancel pending requests
            .execute()

        // Update local cache
        if let index = myRequests.firstIndex(where: { $0.id == requestId }) {
            myRequests[index].status = .cancelled
        }
    }

    // MARK: - Notes Operations

    /// Fetch notes for a relief request
    func fetchNotes(for requestId: UUID) async throws -> [ReliefRequestNote] {
        let notes: [ReliefRequestNote] = try await supabase
            .from("relief_request_notes")
            .select()
            .eq("relief_request_id", value: requestId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return notes
    }

    /// Add a note to a relief request
    func addNote(to requestId: UUID, text: String) async throws -> ReliefRequestNote {
        guard let userId = currentUserId else {
            throw ReliefError.notAuthenticated
        }

        struct NoteInsert: Encodable {
            let reliefRequestId: UUID
            let userId: UUID
            let noteText: String
            let isAdminNote: Bool

            enum CodingKeys: String, CodingKey {
                case reliefRequestId = "relief_request_id"
                case userId = "user_id"
                case noteText = "note_text"
                case isAdminNote = "is_admin_note"
            }
        }

        let noteData = NoteInsert(
            reliefRequestId: requestId,
            userId: userId,
            noteText: text,
            isAdminNote: false
        )

        let note: ReliefRequestNote = try await supabase
            .from("relief_request_notes")
            .insert(noteData)
            .select()
            .single()
            .execute()
            .value

        return note
    }

    // MARK: - Document Operations

    /// Upload a document for a relief request
    func uploadDocument(
        for requestId: UUID,
        image: UIImage,
        type: ReliefDocumentType,
        fileName: String?
    ) async throws -> ReliefRequestDocument {
        guard let userId = currentUserId else {
            throw ReliefError.notAuthenticated
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ReliefError.imageConversionFailed
        }

        let path = "\(userId.uuidString)/\(requestId.uuidString)/\(UUID().uuidString).jpg"

        try await supabase.storage
            .from("relief-documents")
            .upload(
                path: path,
                file: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        let publicUrl = try supabase.storage
            .from("relief-documents")
            .getPublicURL(path: path)

        struct DocumentInsert: Encodable {
            let reliefRequestId: UUID
            let userId: UUID
            let documentType: String
            let fileUrl: String
            let fileName: String?

            enum CodingKeys: String, CodingKey {
                case reliefRequestId = "relief_request_id"
                case userId = "user_id"
                case documentType = "document_type"
                case fileUrl = "file_url"
                case fileName = "file_name"
            }
        }

        let docData = DocumentInsert(
            reliefRequestId: requestId,
            userId: userId,
            documentType: type.rawValue,
            fileUrl: publicUrl.absoluteString,
            fileName: fileName ?? "document.jpg"
        )

        let document: ReliefRequestDocument = try await supabase
            .from("relief_request_documents")
            .insert(docData)
            .select()
            .single()
            .execute()
            .value

        return document
    }

    /// Fetch documents for a relief request
    func fetchDocuments(for requestId: UUID) async throws -> [ReliefRequestDocument] {
        let documents: [ReliefRequestDocument] = try await supabase
            .from("relief_request_documents")
            .select()
            .eq("relief_request_id", value: requestId.uuidString)
            .order("uploaded_at", ascending: false)
            .execute()
            .value

        return documents
    }
}

// MARK: - Errors

enum ReliefError: LocalizedError {
    case notAuthenticated
    case imageConversionFailed
    case uploadFailed
    case requestNotFound
    case cannotModify

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to submit a relief request"
        case .imageConversionFailed:
            return "Failed to process the image"
        case .uploadFailed:
            return "Failed to upload the document"
        case .requestNotFound:
            return "Relief request not found"
        case .cannotModify:
            return "This request cannot be modified"
        }
    }
}
