//
//  TrustLadderModels.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Data models for the Trust Ladder progressive swapping system
//

import Foundation
import SwiftUI

// MARK: - Verification Status Flags

struct VerificationStatusFlags: Codable, Equatable {
    var email: Bool
    var phone: Bool
    var govIdVerified: Bool

    enum CodingKeys: String, CodingKey {
        case email
        case phone
        case govIdVerified = "gov_id_verified"
    }

    init(email: Bool = false, phone: Bool = false, govIdVerified: Bool = false) {
        self.email = email
        self.phone = phone
        self.govIdVerified = govIdVerified
    }

    func meetsRequirements(for tier: TrustTier) -> Bool {
        switch tier {
        case .streamer:
            return email && phone
        case .utility:
            return email && phone
        case .guardian:
            return email && phone && govIdVerified
        }
    }

    var completedCount: Int {
        [email, phone, govIdVerified].filter { $0 }.count
    }

    var totalCount: Int { 3 }
}

// MARK: - User Trust Status

struct UserTrustStatus: Codable, Equatable, Identifiable {
    let userId: UUID
    var currentTier: Int
    var trustPoints: Int
    var successfulSwapsCurrentTier: Int
    var totalSuccessfulSwaps: Int
    var totalFailedSwaps: Int
    var ghostCount: Int
    var isBanned: Bool
    var banReason: String?
    var bannedAt: Date?
    var deviceIds: [String]
    var verificationStatus: VerificationStatusFlags
    var averageRating: Double
    var totalRatingsReceived: Int
    let createdAt: Date
    var updatedAt: Date

    // Assist-related fields
    var totalAssistsGiven: Int?
    var totalAssistsReceived: Int?
    var assistRatingAsHelper: Double?
    var assistRatingAsRequester: Double?
    var successfulRepayments: Int?
    var failedRepayments: Int?

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case currentTier = "current_tier"
        case trustPoints = "trust_points"
        case successfulSwapsCurrentTier = "successful_swaps_current_tier"
        case totalSuccessfulSwaps = "total_successful_swaps"
        case totalFailedSwaps = "total_failed_swaps"
        case ghostCount = "ghost_count"
        case isBanned = "is_banned"
        case banReason = "ban_reason"
        case bannedAt = "banned_at"
        case deviceIds = "device_ids"
        case verificationStatus = "verification_status"
        case averageRating = "average_rating"
        case totalRatingsReceived = "total_ratings_received"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        // Assist fields
        case totalAssistsGiven = "total_assists_given"
        case totalAssistsReceived = "total_assists_received"
        case assistRatingAsHelper = "assist_rating_as_helper"
        case assistRatingAsRequester = "assist_rating_as_requester"
        case successfulRepayments = "successful_repayments"
        case failedRepayments = "failed_repayments"
    }

    var tier: TrustTier {
        TrustTier(rawValue: currentTier) ?? .streamer
    }

    var swapsToNextTier: Int? {
        guard let required = tier.requiredSwapsToGraduate else { return nil }
        return max(0, required - successfulSwapsCurrentTier)
    }

    var progressToNextTier: Double {
        guard let required = tier.requiredSwapsToGraduate, required > 0 else { return 1.0 }
        return min(1.0, Double(successfulSwapsCurrentTier) / Double(required))
    }

    var canGraduate: Bool {
        guard let nextTier = tier.nextTier else { return false }
        guard let required = tier.requiredSwapsToGraduate else { return false }

        // Check swap count
        guard successfulSwapsCurrentTier >= required else { return false }

        // Check rating for Tier 1 -> 2
        if tier == .streamer, let requiredRating = tier.requiredRating {
            guard averageRating >= requiredRating else { return false }
        }

        // Check verification for next tier
        return verificationStatus.meetsRequirements(for: nextTier)
    }

    var formattedRating: String {
        String(format: "%.1f", averageRating)
    }

    var ratingStars: Int {
        Int(averageRating.rounded())
    }
}

// MARK: - User Bill

struct UserBill: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var billCategory: String
    var providerName: String
    var typicalAmount: Double
    var dueDay: Int
    var paymentUrl: String?
    var accountIdentifier: String?
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case billCategory = "bill_category"
        case providerName = "provider_name"
        case typicalAmount = "typical_amount"
        case dueDay = "due_day"
        case paymentUrl = "payment_url"
        case accountIdentifier = "account_identifier"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var category: SwapBillCategory? {
        SwapBillCategory(rawValue: billCategory)
    }

    var formattedAmount: String {
        String(format: "$%.2f", typicalAmount)
    }

    var formattedDueDay: String {
        let suffix: String
        switch dueDay {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(dueDay)\(suffix)"
    }

    var dueDayDescription: String {
        "Due on the \(formattedDueDay)"
    }
}

// MARK: - Payday Schedule

struct PaydaySchedule: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var paydayType: String
    var paydayDays: [Int]
    var nextPayday: Date?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case paydayType = "payday_type"
        case paydayDays = "payday_days"
        case nextPayday = "next_payday"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Custom decoder to handle type mismatches between Supabase and Swift
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        paydayType = try container.decode(String.self, forKey: .paydayType)

        // Handle payday_days - default to empty array if null
        paydayDays = try container.decodeIfPresent([Int].self, forKey: .paydayDays) ?? []

        // Handle next_payday (PostgreSQL date type returns "YYYY-MM-DD" string)
        if let dateString = try container.decodeIfPresent(String.self, forKey: .nextPayday) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            nextPayday = dateFormatter.date(from: dateString)
        } else {
            nextPayday = nil
        }

        // Handle timestamps - they can be nullable in DB, provide fallback
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt),
           let date = isoFormatter.date(from: createdAtString) {
            createdAt = date
        } else {
            createdAt = Date()
        }

        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt),
           let date = isoFormatter.date(from: updatedAtString) {
            updatedAt = date
        } else {
            updatedAt = Date()
        }
    }

    // Manual initializer for creating instances in code
    init(id: UUID, userId: UUID, paydayType: String, paydayDays: [Int],
         nextPayday: Date?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.paydayType = paydayType
        self.paydayDays = paydayDays
        self.nextPayday = nextPayday
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var type: PaydayType? {
        PaydayType(rawValue: paydayType)
    }

    var paydayDescription: String {
        guard let type = type else { return "Unknown" }

        switch type {
        case .weekly:
            let weekday = Calendar.current.weekdaySymbols[safe: (paydayDays.first ?? 1) - 1] ?? "Unknown"
            return "Every \(weekday)"
        case .biweekly:
            let weekday = Calendar.current.weekdaySymbols[safe: (paydayDays.first ?? 1) - 1] ?? "Unknown"
            return "Every other \(weekday)"
        case .semiMonthly:
            let days = paydayDays.sorted()
            if days.count >= 2 {
                return "\(ordinal(days[0])) & \(ordinal(days[1])) of month"
            }
            return "Twice monthly"
        case .monthly:
            return "\(ordinal(paydayDays.first ?? 1)) of each month"
        }
    }

    private func ordinal(_ day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(day)\(suffix)"
    }
}

// MARK: - Swap

struct Swap: Identifiable, Codable, Equatable {
    let id: UUID
    var status: String
    let tierNumber: Int

    // User A (initiator)
    let userAId: UUID
    let userABillId: UUID
    let userAAmount: Double
    var userAFeePaid: Bool
    var userAFeeTransactionId: String?
    var userACompletedAt: Date?
    var userAScreenshotUrl: String?
    var userAScreenshotVerified: Bool?
    var userAVerificationConfidence: Double?
    var userARatingGiven: Int?

    // User B (matched partner)
    var userBId: UUID?
    var userBBillId: UUID?
    var userBAmount: Double?
    var userBFeePaid: Bool
    var userBFeeTransactionId: String?
    var userBCompletedAt: Date?
    var userBScreenshotUrl: String?
    var userBScreenshotVerified: Bool?
    var userBVerificationConfidence: Double?
    var userBRatingGiven: Int?

    // Match metadata
    var matchScore: Double?
    var matchedAt: Date?
    var executionWindowStart: Date?
    var executionDeadline: Date?

    // Completion
    var completedAt: Date?
    var trustPointsAwarded: Int?

    // Dispute
    var disputeReason: String?
    var disputeReportedBy: UUID?
    var disputeResolvedAt: Date?
    var disputeResolution: String?
    var ghostUserId: UUID?

    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status
        case tierNumber = "tier_number"
        case userAId = "user_a_id"
        case userABillId = "user_a_bill_id"
        case userAAmount = "user_a_amount"
        case userAFeePaid = "user_a_fee_paid"
        case userAFeeTransactionId = "user_a_fee_transaction_id"
        case userACompletedAt = "user_a_completed_at"
        case userAScreenshotUrl = "user_a_screenshot_url"
        case userAScreenshotVerified = "user_a_screenshot_verified"
        case userAVerificationConfidence = "user_a_verification_confidence"
        case userARatingGiven = "user_a_rating_given"
        case userBId = "user_b_id"
        case userBBillId = "user_b_bill_id"
        case userBAmount = "user_b_amount"
        case userBFeePaid = "user_b_fee_paid"
        case userBFeeTransactionId = "user_b_fee_transaction_id"
        case userBCompletedAt = "user_b_completed_at"
        case userBScreenshotUrl = "user_b_screenshot_url"
        case userBScreenshotVerified = "user_b_screenshot_verified"
        case userBVerificationConfidence = "user_b_verification_confidence"
        case userBRatingGiven = "user_b_rating_given"
        case matchScore = "match_score"
        case matchedAt = "matched_at"
        case executionWindowStart = "execution_window_start"
        case executionDeadline = "execution_deadline"
        case completedAt = "completed_at"
        case trustPointsAwarded = "trust_points_awarded"
        case disputeReason = "dispute_reason"
        case disputeReportedBy = "dispute_reported_by"
        case disputeResolvedAt = "dispute_resolved_at"
        case disputeResolution = "dispute_resolution"
        case ghostUserId = "ghost_user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var swapStatus: SwapStatus {
        SwapStatus(rawValue: status) ?? .pending
    }

    var tier: TrustTier {
        TrustTier(rawValue: tierNumber) ?? .streamer
    }

    var bothFeesPaid: Bool {
        userAFeePaid && userBFeePaid
    }

    var isMatched: Bool {
        userBId != nil
    }

    var formattedUserAAmount: String {
        String(format: "$%.2f", userAAmount)
    }

    var formattedUserBAmount: String? {
        guard let amount = userBAmount else { return nil }
        return String(format: "$%.2f", amount)
    }

    var totalSwapValue: Double {
        userAAmount + (userBAmount ?? 0)
    }

    var formattedTotalValue: String {
        String(format: "$%.2f", totalSwapValue)
    }

    var timeRemaining: TimeInterval? {
        guard let deadline = executionDeadline else { return nil }
        return deadline.timeIntervalSinceNow
    }

    var formattedTimeRemaining: String? {
        guard let remaining = timeRemaining, remaining > 0 else { return nil }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var isExpired: Bool {
        guard let deadline = executionDeadline else { return false }
        return Date() > deadline
    }

    func isUserA(_ userId: UUID) -> Bool {
        userAId == userId
    }

    func isUserB(_ userId: UUID) -> Bool {
        userBId == userId
    }

    func partnerUserId(for currentUserId: UUID) -> UUID? {
        if isUserA(currentUserId) { return userBId }
        if isUserB(currentUserId) { return userAId }
        return nil
    }

    // MARK: - Mock for Previews

    static func mock(status: String = "fee_paid") -> Swap {
        Swap(
            id: UUID(),
            status: status,
            tierNumber: 1,
            userAId: UUID(),
            userABillId: UUID(),
            userAAmount: 15.99,
            userAFeePaid: true,
            userAFeeTransactionId: "txn_123",
            userACompletedAt: nil,
            userAScreenshotUrl: nil,
            userAScreenshotVerified: nil,
            userAVerificationConfidence: nil,
            userARatingGiven: nil,
            userBId: UUID(),
            userBBillId: UUID(),
            userBAmount: 14.99,
            userBFeePaid: true,
            userBFeeTransactionId: "txn_456",
            userBCompletedAt: nil,
            userBScreenshotUrl: nil,
            userBScreenshotVerified: nil,
            userBVerificationConfidence: nil,
            userBRatingGiven: nil,
            matchScore: 0.85,
            matchedAt: Date(),
            executionWindowStart: Date(),
            executionDeadline: Date().addingTimeInterval(86400),
            completedAt: nil,
            trustPointsAwarded: nil,
            disputeReason: nil,
            disputeReportedBy: nil,
            disputeResolvedAt: nil,
            disputeResolution: nil,
            ghostUserId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Matched Partner (for UI display)

struct MatchedPartner: Identifiable, Codable {
    let id: UUID
    let partnerId: UUID
    let partnerHandle: String
    let partnerInitials: String
    let partnerTrustScore: Int
    let partnerSuccessfulSwaps: Int
    let partnerRating: Double
    let matchScore: Double
    let partnerBillCategory: String
    let partnerBillProvider: String
    let partnerAmount: Double
    let partnerDueDay: Int
    let executionWindowStart: Date
    let executionWindowEnd: Date

    var partnerCategory: SwapBillCategory? {
        SwapBillCategory(rawValue: partnerBillCategory)
    }

    var formattedMatchScore: String {
        "\(Int(matchScore * 100))%"
    }

    var formattedAmount: String {
        String(format: "$%.2f", partnerAmount)
    }

    var formattedRating: String {
        String(format: "%.1f", partnerRating)
    }
}

// MARK: - Swap Screenshot

struct SwapScreenshot: Identifiable, Codable {
    let id: UUID
    let swapId: UUID
    let userId: UUID
    let imageUrl: String
    var ocrRawText: String?
    var ocrExtractedAmount: Double?
    var ocrExtractedProvider: String?
    var ocrExtractedDate: Date?
    var ocrConfidence: Double?
    var verificationStatus: String
    var verifiedBy: UUID?
    var verifiedAt: Date?
    var rejectionReason: String?
    let uploadedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case swapId = "swap_id"
        case userId = "user_id"
        case imageUrl = "image_url"
        case ocrRawText = "ocr_raw_text"
        case ocrExtractedAmount = "ocr_extracted_amount"
        case ocrExtractedProvider = "ocr_extracted_provider"
        case ocrExtractedDate = "ocr_extracted_date"
        case ocrConfidence = "ocr_confidence"
        case verificationStatus = "verification_status"
        case verifiedBy = "verified_by"
        case verifiedAt = "verified_at"
        case rejectionReason = "rejection_reason"
        case uploadedAt = "uploaded_at"
    }

    var status: ScreenshotVerificationStatus {
        ScreenshotVerificationStatus(rawValue: verificationStatus) ?? .pending
    }

    var formattedExtractedAmount: String? {
        guard let amount = ocrExtractedAmount else { return nil }
        return String(format: "$%.2f", amount)
    }

    var confidencePercentage: Int? {
        guard let confidence = ocrConfidence else { return nil }
        return Int(confidence * 100)
    }
}

// MARK: - Coordination Fee Transaction

struct CoordinationFeeTransaction: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let swapId: UUID
    let storekitTransactionId: String
    let storekitOriginalTransactionId: String?
    let amount: Double
    let currency: String
    var status: String
    var refundReason: String?
    var refundedAt: Date?
    let purchasedAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case swapId = "swap_id"
        case storekitTransactionId = "storekit_transaction_id"
        case storekitOriginalTransactionId = "storekit_original_transaction_id"
        case amount, currency, status
        case refundReason = "refund_reason"
        case refundedAt = "refunded_at"
        case purchasedAt = "purchased_at"
        case createdAt = "created_at"
    }

    var feeStatus: FeeTransactionStatus {
        FeeTransactionStatus(rawValue: status) ?? .pending
    }

    var formattedAmount: String {
        String(format: "$%.2f", amount)
    }
}

// MARK: - Swap Dispute

struct SwapDispute: Identifiable, Codable {
    let id: UUID
    let swapId: UUID
    let reportedBy: UUID
    let reportedUser: UUID
    var reason: String
    var description: String?
    var evidenceUrls: [String]?
    var status: String
    var resolution: String?
    var resolvedBy: UUID?
    var resolvedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case swapId = "swap_id"
        case reportedBy = "reported_by"
        case reportedUser = "reported_user"
        case reason, description
        case evidenceUrls = "evidence_urls"
        case status, resolution
        case resolvedBy = "resolved_by"
        case resolvedAt = "resolved_at"
        case createdAt = "created_at"
    }

    var disputeReason: DisputeReason {
        DisputeReason(rawValue: reason) ?? .other
    }
}

// MARK: - Trust Tier Info (from DB)

struct TrustTierInfo: Identifiable, Codable {
    let id: UUID
    let tierNumber: Int
    let name: String
    let maxSwapAmount: Double
    let requiredSwapsToGraduate: Int?
    let requiredRating: Double?
    let unlockRequirements: [String: Bool]
    let allowedBillCategories: [String]
    let badgeName: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case tierNumber = "tier_number"
        case name
        case maxSwapAmount = "max_swap_amount"
        case requiredSwapsToGraduate = "required_swaps_to_graduate"
        case requiredRating = "required_rating"
        case unlockRequirements = "unlock_requirements"
        case allowedBillCategories = "allowed_bill_categories"
        case badgeName = "badge_name"
        case createdAt = "created_at"
    }
}

// MARK: - Array Safe Subscript Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview Data

extension UserTrustStatus {
    static let preview = UserTrustStatus(
        userId: UUID(),
        currentTier: 1,
        trustPoints: 150,
        successfulSwapsCurrentTier: 2,
        totalSuccessfulSwaps: 2,
        totalFailedSwaps: 0,
        ghostCount: 0,
        isBanned: false,
        banReason: nil,
        bannedAt: nil,
        deviceIds: [],
        verificationStatus: VerificationStatusFlags(email: true, phone: true, govIdVerified: false),
        averageRating: 5.0,
        totalRatingsReceived: 2,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let tier2Preview = UserTrustStatus(
        userId: UUID(),
        currentTier: 2,
        trustPoints: 450,
        successfulSwapsCurrentTier: 3,
        totalSuccessfulSwaps: 8,
        totalFailedSwaps: 0,
        ghostCount: 0,
        isBanned: false,
        banReason: nil,
        bannedAt: nil,
        deviceIds: [],
        verificationStatus: VerificationStatusFlags(email: true, phone: true, govIdVerified: false),
        averageRating: 4.8,
        totalRatingsReceived: 8,
        createdAt: Date(),
        updatedAt: Date()
    )
}

extension UserBill {
    static let preview = UserBill(
        id: UUID(),
        userId: UUID(),
        billCategory: "netflix",
        providerName: "Netflix",
        typicalAmount: 15.99,
        dueDay: 15,
        paymentUrl: "https://netflix.com/payment",
        accountIdentifier: nil,
        isActive: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let previewBills: [UserBill] = [
        UserBill(
            id: UUID(),
            userId: UUID(),
            billCategory: "netflix",
            providerName: "Netflix",
            typicalAmount: 15.99,
            dueDay: 15,
            paymentUrl: nil,
            accountIdentifier: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        UserBill(
            id: UUID(),
            userId: UUID(),
            billCategory: "spotify",
            providerName: "Spotify",
            typicalAmount: 10.99,
            dueDay: 1,
            paymentUrl: nil,
            accountIdentifier: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}

extension PaydaySchedule {
    static let preview = PaydaySchedule(
        id: UUID(),
        userId: UUID(),
        paydayType: "biweekly",
        paydayDays: [5], // Friday
        nextPayday: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
        createdAt: Date(),
        updatedAt: Date()
    )
}

extension MatchedPartner {
    static let preview = MatchedPartner(
        id: UUID(),
        partnerId: UUID(),
        partnerHandle: "sarah_m",
        partnerInitials: "SM",
        partnerTrustScore: 200,
        partnerSuccessfulSwaps: 5,
        partnerRating: 4.8,
        matchScore: 0.92,
        partnerBillCategory: "spotify",
        partnerBillProvider: "Spotify",
        partnerAmount: 10.99,
        partnerDueDay: 1,
        executionWindowStart: Date(),
        executionWindowEnd: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    )

    static let previewMatches: [MatchedPartner] = [
        preview,
        MatchedPartner(
            id: UUID(),
            partnerId: UUID(),
            partnerHandle: "mike_t",
            partnerInitials: "MT",
            partnerTrustScore: 350,
            partnerSuccessfulSwaps: 8,
            partnerRating: 5.0,
            matchScore: 0.85,
            partnerBillCategory: "gym",
            partnerBillProvider: "Planet Fitness",
            partnerAmount: 24.99,
            partnerDueDay: 5,
            executionWindowStart: Date(),
            executionWindowEnd: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        )
    ]
}

extension Swap {
    static let preview = Swap(
        id: UUID(),
        status: "matched",
        tierNumber: 1,
        userAId: UUID(),
        userABillId: UUID(),
        userAAmount: 15.99,
        userAFeePaid: true,
        userAFeeTransactionId: nil,
        userACompletedAt: nil,
        userAScreenshotUrl: nil,
        userAScreenshotVerified: nil,
        userAVerificationConfidence: nil,
        userARatingGiven: nil,
        userBId: UUID(),
        userBBillId: UUID(),
        userBAmount: 10.99,
        userBFeePaid: true,
        userBFeeTransactionId: nil,
        userBCompletedAt: nil,
        userBScreenshotUrl: nil,
        userBScreenshotVerified: nil,
        userBVerificationConfidence: nil,
        userBRatingGiven: nil,
        matchScore: 0.92,
        matchedAt: Date(),
        executionWindowStart: Date(),
        executionDeadline: Calendar.current.date(byAdding: .hour, value: 24, to: Date()),
        completedAt: nil,
        trustPointsAwarded: nil,
        disputeReason: nil,
        disputeReportedBy: nil,
        disputeResolvedAt: nil,
        disputeResolution: nil,
        ghostUserId: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}
