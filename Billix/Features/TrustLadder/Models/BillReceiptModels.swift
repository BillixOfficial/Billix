//
//  BillReceiptModels.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Models for Bill Receipt Exchange feature
//

import Foundation
import SwiftUI

// MARK: - Receipt Status

enum ReceiptStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case verified = "verified"
    case rejected = "rejected"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .processing: return "Processing"
        case .verified: return "Verified"
        case .rejected: return "Rejected"
        case .expired: return "Expired"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "gearshape.2"
        case .verified: return "checkmark.seal.fill"
        case .rejected: return "xmark.seal.fill"
        case .expired: return "clock.badge.xmark"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .processing: return .blue
        case .verified: return .green
        case .rejected: return .red
        case .expired: return .gray
        }
    }
}

// MARK: - Bill Category for Receipts

enum ReceiptBillCategory: String, Codable, CaseIterable, Identifiable {
    case electricity
    case gas
    case water
    case internet
    case phone
    case rent
    case insurance
    case streaming
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .electricity: return "Electricity"
        case .gas: return "Gas"
        case .water: return "Water"
        case .internet: return "Internet"
        case .phone: return "Phone"
        case .rent: return "Rent"
        case .insurance: return "Insurance"
        case .streaming: return "Streaming"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .electricity: return "bolt.fill"
        case .gas: return "flame.fill"
        case .water: return "drop.fill"
        case .internet: return "wifi"
        case .phone: return "phone.fill"
        case .rent: return "house.fill"
        case .insurance: return "shield.fill"
        case .streaming: return "play.tv.fill"
        case .other: return "doc.fill"
        }
    }

    var color: Color {
        switch self {
        case .electricity: return .yellow
        case .gas: return .orange
        case .water: return .blue
        case .internet: return .purple
        case .phone: return .green
        case .rent: return .brown
        case .insurance: return .teal
        case .streaming: return .pink
        case .other: return .gray
        }
    }

    /// Credits earned for uploading a verified receipt of this category
    var creditsEarned: Int {
        switch self {
        case .rent, .insurance: return 15 // Higher value bills
        case .electricity, .gas, .water: return 10 // Utility bills
        case .internet, .phone: return 10 // Communication
        case .streaming: return 5 // Lower value
        case .other: return 8 // Default
        }
    }
}

// MARK: - Bill Receipt

struct BillReceipt: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let billCategory: String
    let providerName: String?
    let amount: Decimal
    let paidDate: Date
    let screenshotUrl: String
    var ocrVerified: Bool
    var ocrExtractedData: OCRExtractedData?
    var creditsEarned: Int
    var status: ReceiptStatus
    var rejectionReason: String?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case billCategory = "bill_category"
        case providerName = "provider_name"
        case amount
        case paidDate = "paid_date"
        case screenshotUrl = "screenshot_url"
        case ocrVerified = "ocr_verified"
        case ocrExtractedData = "ocr_extracted_data"
        case creditsEarned = "credits_earned"
        case status
        case rejectionReason = "rejection_reason"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var category: ReceiptBillCategory? {
        ReceiptBillCategory(rawValue: billCategory)
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: paidDate)
    }
}

// MARK: - OCR Extracted Data

struct OCRExtractedData: Codable {
    var detectedAmount: Decimal?
    var detectedDate: String?
    var detectedProvider: String?
    var confidence: Double
    var rawText: String?

    var isHighConfidence: Bool {
        confidence >= 0.8
    }
}

// MARK: - Receipt Upload Request

struct ReceiptUploadRequest {
    let category: ReceiptBillCategory
    let providerName: String?
    let amount: Decimal
    let paidDate: Date
    let imageData: Data

    var isValid: Bool {
        amount > 0 && !imageData.isEmpty
    }
}

// MARK: - Receipt Insert

struct BillReceiptInsert: Codable {
    let userId: String
    let billCategory: String
    let providerName: String?
    let amount: Decimal
    let paidDate: String
    let screenshotUrl: String
    let ocrVerified: Bool
    let creditsEarned: Int
    let status: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case billCategory = "bill_category"
        case providerName = "provider_name"
        case amount
        case paidDate = "paid_date"
        case screenshotUrl = "screenshot_url"
        case ocrVerified = "ocr_verified"
        case creditsEarned = "credits_earned"
        case status
    }
}

struct BillReceiptUpdate: Codable {
    let status: String
    let ocrVerified: Bool
    let creditsEarned: Int
    let rejectionReason: String?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case ocrVerified = "ocr_verified"
        case creditsEarned = "credits_earned"
        case rejectionReason = "rejection_reason"
        case updatedAt = "updated_at"
    }
}

// MARK: - Receipt Statistics

struct ReceiptStatistics {
    let totalUploaded: Int
    let totalVerified: Int
    let totalCreditsEarned: Int
    let categoryCounts: [ReceiptBillCategory: Int]
    let averageAmount: Decimal

    var verificationRate: Double {
        guard totalUploaded > 0 else { return 0 }
        return Double(totalVerified) / Double(totalUploaded)
    }

    var formattedVerificationRate: String {
        "\(Int(verificationRate * 100))%"
    }

    static var empty: ReceiptStatistics {
        ReceiptStatistics(
            totalUploaded: 0,
            totalVerified: 0,
            totalCreditsEarned: 0,
            categoryCounts: [:],
            averageAmount: 0
        )
    }
}

// MARK: - Receipt Filter

enum ReceiptFilter: String, CaseIterable {
    case all
    case verified
    case pending
    case rejected

    var displayName: String {
        switch self {
        case .all: return "All"
        case .verified: return "Verified"
        case .pending: return "Pending"
        case .rejected: return "Rejected"
        }
    }

    var statuses: [ReceiptStatus] {
        switch self {
        case .all: return ReceiptStatus.allCases
        case .verified: return [.verified]
        case .pending: return [.pending, .processing]
        case .rejected: return [.rejected, .expired]
        }
    }
}

// MARK: - Receipt Validation

enum ReceiptValidationError: LocalizedError {
    case invalidImage
    case imageTooLarge
    case amountTooLow
    case amountTooHigh
    case dateTooOld
    case dateInFuture
    case duplicateReceipt
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Please select a valid image"
        case .imageTooLarge:
            return "Image must be under 10MB"
        case .amountTooLow:
            return "Amount must be at least $1"
        case .amountTooHigh:
            return "Amount exceeds maximum limit"
        case .dateTooOld:
            return "Receipt must be from the last 90 days"
        case .dateInFuture:
            return "Payment date cannot be in the future"
        case .duplicateReceipt:
            return "This receipt appears to have already been uploaded"
        case .uploadFailed:
            return "Failed to upload receipt. Please try again."
        }
    }
}

// MARK: - Receipt Limits

struct ReceiptLimits {
    static let maxImageSizeBytes = 10 * 1024 * 1024 // 10MB
    static let minAmount: Decimal = 1
    static let maxAmount: Decimal = 10000
    static let maxAgeDays = 90
    static let maxUploadsPerDay = 10
    static let maxUploadsPerMonth = 50
}
