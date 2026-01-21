//
//  ReliefRequest.swift
//  Billix
//
//  Data models for relief requests
//

import Foundation

/// Main relief request model
struct ReliefRequest: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID

    // Personal Information
    var fullName: String
    var email: String
    var phone: String?

    // Bill Information
    var billType: ReliefBillType
    var billProvider: String?
    var amountOwed: Decimal
    var description: String?

    // Household Information
    var incomeLevel: ReliefIncomeLevel
    var householdSize: Int
    var employmentStatus: ReliefEmploymentStatus

    // Urgency Information
    var urgencyLevel: ReliefUrgencyLevel
    var utilityShutoffDate: Date?

    // Status Tracking
    var status: ReliefRequestStatus
    var statusNotes: String?

    // Timestamps
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case email
        case phone
        case billType = "bill_type"
        case billProvider = "bill_provider"
        case amountOwed = "amount_owed"
        case description
        case incomeLevel = "income_level"
        case householdSize = "household_size"
        case employmentStatus = "employment_status"
        case urgencyLevel = "urgency_level"
        case utilityShutoffDate = "utility_shutoff_date"
        case status
        case statusNotes = "status_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Formatted amount string
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amountOwed as NSDecimalNumber) ?? "$\(amountOwed)"
    }

    /// Days until shutoff (negative if past)
    var daysUntilShutoff: Int? {
        guard let shutoffDate = utilityShutoffDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: shutoffDate)
        return components.day
    }

    /// Whether shutoff is imminent (within 7 days)
    var isShutoffImminent: Bool {
        guard let days = daysUntilShutoff else { return false }
        return days >= 0 && days <= 7
    }

    /// Formatted date string for display
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
}

/// Insert model for creating new relief requests
struct ReliefRequestInsert: Encodable {
    let userId: UUID
    let fullName: String
    let email: String
    let phone: String?
    let billType: String
    let billProvider: String?
    let amountOwed: Decimal
    let description: String?
    let incomeLevel: String
    let householdSize: Int
    let employmentStatus: String
    let urgencyLevel: String
    let utilityShutoffDate: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case fullName = "full_name"
        case email
        case phone
        case billType = "bill_type"
        case billProvider = "bill_provider"
        case amountOwed = "amount_owed"
        case description
        case incomeLevel = "income_level"
        case householdSize = "household_size"
        case employmentStatus = "employment_status"
        case urgencyLevel = "urgency_level"
        case utilityShutoffDate = "utility_shutoff_date"
    }
}

/// Relief request note model
struct ReliefRequestNote: Identifiable, Codable {
    let id: UUID
    let reliefRequestId: UUID
    let userId: UUID
    let noteText: String
    let isAdminNote: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case reliefRequestId = "relief_request_id"
        case userId = "user_id"
        case noteText = "note_text"
        case isAdminNote = "is_admin_note"
        case createdAt = "created_at"
    }

    /// Formatted date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

/// Relief request document model
struct ReliefRequestDocument: Identifiable, Codable {
    let id: UUID
    let reliefRequestId: UUID
    let userId: UUID
    let documentType: ReliefDocumentType
    let fileUrl: String
    let fileName: String?
    let uploadedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case reliefRequestId = "relief_request_id"
        case userId = "user_id"
        case documentType = "document_type"
        case fileUrl = "file_url"
        case fileName = "file_name"
        case uploadedAt = "uploaded_at"
    }
}
