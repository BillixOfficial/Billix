//
//  AssistRequestService.swift
//  Billix
//
//  Created by Claude Code on 12/31/24.
//  Service for managing Bill Assist peer-to-peer assistance requests
//

import Foundation
import Supabase

// MARK: - Errors

enum AssistError: LocalizedError {
    case notAuthenticated
    case requestNotFound
    case offerNotFound
    case notYourRequest
    case notInvolved
    case invalidStatus
    case feesNotPaid
    case screenshotRequired
    case verificationFailed
    case requestExpired
    case alreadyCompleted
    case notEligible(String)
    case maxRequestsReached
    case cannotOfferOwnRequest
    case offerAlreadyExists
    case termsNotAgreed
    case repaymentFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .requestNotFound:
            return "Assist request not found"
        case .offerNotFound:
            return "Offer not found"
        case .notYourRequest:
            return "You are not the requester"
        case .notInvolved:
            return "You are not part of this assist request"
        case .invalidStatus:
            return "Invalid status for this action"
        case .feesNotPaid:
            return "Both parties must pay the connection fee first"
        case .screenshotRequired:
            return "Please upload a payment screenshot"
        case .verificationFailed:
            return "Screenshot verification failed"
        case .requestExpired:
            return "This request has expired"
        case .alreadyCompleted:
            return "This request is already completed"
        case .notEligible(let reason):
            return reason
        case .maxRequestsReached:
            return "You can only have 2 active requests at a time"
        case .cannotOfferOwnRequest:
            return "You cannot offer help on your own request"
        case .offerAlreadyExists:
            return "You already have a pending offer on this request"
        case .termsNotAgreed:
            return "Both parties must agree to terms first"
        case .repaymentFailed:
            return "Failed to record repayment"
        }
    }
}

// MARK: - Update Structs

private struct CreateRequestPayload: Codable {
    let requesterId: UUID
    let status: String
    let billId: UUID?
    let billCategory: String
    let billProvider: String
    let billAmount: Double
    let billDueDate: String
    let billScreenshotUrl: String?
    let amountRequested: Double
    let urgency: String
    let description: String?
    let preferredTerms: RepaymentTerms?
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case requesterId = "requester_id"
        case status
        case billId = "bill_id"
        case billCategory = "bill_category"
        case billProvider = "bill_provider"
        case billAmount = "bill_amount"
        case billDueDate = "bill_due_date"
        case billScreenshotUrl = "bill_screenshot_url"
        case amountRequested = "amount_requested"
        case urgency
        case description
        case preferredTerms = "preferred_terms"
        case expiresAt = "expires_at"
    }
}

private struct StatusUpdate: Codable {
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case updatedAt = "updated_at"
    }
}

private struct MatchUpdate: Codable {
    let helperId: UUID
    let status: String
    let matchedAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case helperId = "helper_id"
        case status
        case matchedAt = "matched_at"
        case updatedAt = "updated_at"
    }
}

private struct FeeUpdate: Codable {
    let requesterFeePaid: Bool?
    let helperFeePaid: Bool?
    let requesterFeeTransactionId: String?
    let helperFeeTransactionId: String?
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case requesterFeePaid = "requester_fee_paid"
        case helperFeePaid = "helper_fee_paid"
        case requesterFeeTransactionId = "requester_fee_transaction_id"
        case helperFeeTransactionId = "helper_fee_transaction_id"
        case status
        case updatedAt = "updated_at"
    }
}

private struct TermsUpdate: Codable {
    let agreedTerms: RepaymentTerms
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case agreedTerms = "agreed_terms"
        case status
        case updatedAt = "updated_at"
    }
}

private struct PaymentProofUpdate: Codable {
    let paymentScreenshotUrl: String
    let paymentVerified: Bool
    let paymentVerifiedAt: String?
    let status: String
    let updatedAt: String
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case paymentScreenshotUrl = "payment_screenshot_url"
        case paymentVerified = "payment_verified"
        case paymentVerifiedAt = "payment_verified_at"
        case status
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
    }
}

private struct HelperRatingUpdate: Codable {
    let helperRating: Int
    let helperReview: String?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case helperRating = "helper_rating"
        case helperReview = "helper_review"
        case updatedAt = "updated_at"
    }
}

private struct RequesterRatingUpdate: Codable {
    let requesterRating: Int
    let requesterReview: String?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case requesterRating = "requester_rating"
        case requesterReview = "requester_review"
        case updatedAt = "updated_at"
    }
}

private struct CreateOfferPayload: Codable {
    let assistRequestId: UUID
    let offererId: UUID
    let proposedTerms: RepaymentTerms
    let message: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case assistRequestId = "assist_request_id"
        case offererId = "offerer_id"
        case proposedTerms = "proposed_terms"
        case message
        case status
    }
}

private struct CreateRepaymentPayload: Codable {
    let assistRequestId: UUID
    let payerId: UUID
    let amount: Double
    let paymentMethod: String?
    let screenshotUrl: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case assistRequestId = "assist_request_id"
        case payerId = "payer_id"
        case amount
        case paymentMethod = "payment_method"
        case screenshotUrl = "screenshot_url"
        case notes
    }
}

private struct FeeTransactionPayload: Codable {
    let userId: String
    let assistRequestId: String
    let role: String
    let productId: String
    let transactionId: String
    let amount: Double
    let status: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case assistRequestId = "assist_request_id"
        case role
        case productId = "product_id"
        case transactionId = "transaction_id"
        case amount
        case status
    }
}

private struct MessagePayload: Codable {
    let assistRequestId: String
    let senderId: String
    let messageType: String
    let content: String?
    let termsData: RepaymentTerms?

    enum CodingKeys: String, CodingKey {
        case assistRequestId = "assist_request_id"
        case senderId = "sender_id"
        case messageType = "message_type"
        case content
        case termsData = "terms_data"
    }
}

private struct DisputePayload: Codable {
    let assistRequestId: String
    let reportedBy: String
    let reason: String
    let description: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case assistRequestId = "assist_request_id"
        case reportedBy = "reported_by"
        case reason
        case description
        case status
    }
}

private struct RequesterFeeUpdate: Codable {
    let requesterFeePaid: Bool
    let requesterFeeTransactionId: String
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case requesterFeePaid = "requester_fee_paid"
        case requesterFeeTransactionId = "requester_fee_transaction_id"
        case status
        case updatedAt = "updated_at"
    }
}

private struct HelperFeeUpdate: Codable {
    let helperFeePaid: Bool
    let helperFeeTransactionId: String
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case helperFeePaid = "helper_fee_paid"
        case helperFeeTransactionId = "helper_fee_transaction_id"
        case status
        case updatedAt = "updated_at"
    }
}

private struct PaymentVerifiedUpdate: Codable {
    let paymentVerified: Bool
    let paymentVerifiedAt: String
    let status: String
    let updatedAt: String
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case paymentVerified = "payment_verified"
        case paymentVerifiedAt = "payment_verified_at"
        case status
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
    }
}

private struct GhostCountUpdate: Codable {
    let ghostCount: Int

    enum CodingKeys: String, CodingKey {
        case ghostCount = "ghost_count"
    }
}

private struct GhostBanUpdate: Codable {
    let ghostCount: Int
    let isBanned: Bool
    let banReason: String
    let bannedAt: String

    enum CodingKeys: String, CodingKey {
        case ghostCount = "ghost_count"
        case isBanned = "is_banned"
        case banReason = "ban_reason"
        case bannedAt = "banned_at"
    }
}

private struct RepaidStatusUpdate: Codable {
    let status: String
    let updatedAt: String
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
    }
}

// MARK: - AssistRequestService

@MainActor
class AssistRequestService: ObservableObject {

    // MARK: - Singleton
    static let shared = AssistRequestService()

    // MARK: - Published Properties
    @Published var myRequests: [AssistRequest] = []
    @Published var availableRequests: [AssistRequest] = []
    @Published var activeAssists: [AssistRequest] = []  // Where I'm the helper
    @Published var isLoading = false
    @Published var lastError: String?

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private init() {}

    // MARK: - Eligibility Check

    /// Check if the current user can request/offer assist
    func checkEligibility() async throws -> AssistEligibility {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        // Get user trust status
        let trustStatus: UserTrustStatus = try await supabase
            .from("user_trust_status")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        var reasons: [String] = []
        var canRequest = true
        var canOffer = true

        // Check banned
        if trustStatus.isBanned {
            reasons.append("Account is banned")
            return .ineligible(reasons: reasons)
        }

        // Check verification
        if !trustStatus.verificationStatus.email {
            reasons.append("Email not verified")
            canRequest = false
            canOffer = false
        }

        if !trustStatus.verificationStatus.phone {
            reasons.append("Phone not verified")
            canRequest = false
            canOffer = false
        }

        // Check minimum swaps (2 required)
        if trustStatus.totalSuccessfulSwaps < 2 {
            let needed = 2 - trustStatus.totalSuccessfulSwaps
            reasons.append("Need \(needed) more successful swap\(needed == 1 ? "" : "s")")
            canRequest = false
            canOffer = false
        }

        // Check trust points for offering (minimum 300)
        if trustStatus.trustPoints < 300 {
            let needed = 300 - trustStatus.trustPoints
            reasons.append("Need \(needed) more trust points to offer help")
            canOffer = false
        }

        // Check active request limit
        let activeCount = try await countActiveRequests(for: userId)
        if activeCount >= 2 {
            reasons.append("Maximum 2 active requests")
            canRequest = false
        }

        return AssistEligibility(canRequest: canRequest, canOffer: canOffer, reasons: reasons)
    }

    private func countActiveRequests(for userId: UUID) async throws -> Int {
        let activeStatuses = ["active", "matched", "fee_pending", "fee_paid", "negotiating", "terms_accepted", "payment_pending", "payment_sent"]

        let requests: [AssistRequest] = try await supabase
            .from("assist_requests")
            .select()
            .eq("requester_id", value: userId.uuidString)
            .in("status", values: activeStatuses)
            .execute()
            .value

        return requests.count
    }

    // MARK: - Create Request

    /// Create a new assist request
    func createRequest(
        billId: UUID? = nil,
        billCategory: String,
        billProvider: String,
        billAmount: Double,
        billDueDate: Date,
        billScreenshotUrl: String?,
        amountRequested: Double,
        urgency: AssistUrgency? = nil,
        description: String?,
        preferredTerms: RepaymentTerms?
    ) async throws -> AssistRequest {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        // Check eligibility
        let eligibility = try await checkEligibility()
        if !eligibility.canRequest {
            throw AssistError.notEligible(eligibility.reasons.first ?? "Not eligible")
        }

        // Use provided urgency or calculate from due date
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: billDueDate).day ?? 0
        let finalUrgency = urgency ?? AssistUrgency.fromDaysUntilDue(daysUntilDue)

        // Expires in 7 days
        let expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

        let payload = CreateRequestPayload(
            requesterId: userId,
            status: "active",
            billId: billId,
            billCategory: billCategory,
            billProvider: billProvider,
            billAmount: billAmount,
            billDueDate: dateFormatter.string(from: billDueDate),
            billScreenshotUrl: billScreenshotUrl,
            amountRequested: amountRequested,
            urgency: finalUrgency.rawValue,
            description: description,
            preferredTerms: preferredTerms,
            expiresAt: dateFormatter.string(from: expiresAt)
        )

        let request: AssistRequest = try await supabase
            .from("assist_requests")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        // Refresh my requests
        await fetchMyRequests()

        return request
    }

    // MARK: - Fetch Requests

    /// Fetch user's own requests
    func fetchMyRequests() async {
        guard let userId = SupabaseService.shared.currentUserId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            myRequests = try await supabase
                .from("assist_requests")
                .select()
                .eq("requester_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            lastError = error.localizedDescription
            print("❌ Failed to fetch my requests: \(error)")
        }
    }

    /// Fetch requests where user is the helper
    func fetchMyActiveAssists() async {
        guard let userId = SupabaseService.shared.currentUserId else { return }

        do {
            let activeStatuses = ["matched", "fee_pending", "fee_paid", "negotiating", "terms_accepted", "payment_pending", "payment_sent", "repaying"]

            activeAssists = try await supabase
                .from("assist_requests")
                .select()
                .eq("helper_id", value: userId.uuidString)
                .in("status", values: activeStatuses)
                .order("matched_at", ascending: false)
                .execute()
                .value
        } catch {
            lastError = error.localizedDescription
            print("❌ Failed to fetch active assists: \(error)")
        }
    }

    /// Fetch available requests to help with
    func fetchAvailableRequests(
        urgency: AssistUrgency? = nil,
        maxAmount: Double? = nil,
        category: String? = nil
    ) async {
        guard let userId = SupabaseService.shared.currentUserId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            var query = supabase
                .from("assist_requests")
                .select()
                .eq("status", value: "active")
                .neq("requester_id", value: userId.uuidString)  // Exclude own requests

            if let urgency = urgency {
                query = query.eq("urgency", value: urgency.rawValue)
            }

            if let maxAmount = maxAmount {
                query = query.lte("amount_requested", value: maxAmount)
            }

            if let category = category {
                query = query.eq("bill_category", value: category)
            }

            availableRequests = try await query
                .order("urgency", ascending: false)  // Critical first
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
        } catch {
            lastError = error.localizedDescription
            print("❌ Failed to fetch available requests: \(error)")
        }
    }

    /// Get a single request by ID
    func getRequest(id: UUID) async throws -> AssistRequest {
        let request: AssistRequest = try await supabase
            .from("assist_requests")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return request
    }

    // MARK: - Offers

    /// Make an offer on a request
    func makeOffer(
        requestId: UUID,
        proposedTerms: RepaymentTerms,
        message: String?
    ) async throws -> AssistOffer {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        // Check eligibility
        let eligibility = try await checkEligibility()
        if !eligibility.canOffer {
            throw AssistError.notEligible(eligibility.reasons.first ?? "Not eligible to offer help")
        }

        // Get the request
        let request = try await getRequest(id: requestId)

        // Can't offer on own request
        if request.requesterId == userId {
            throw AssistError.cannotOfferOwnRequest
        }

        // Request must be active
        if request.status != .active {
            throw AssistError.invalidStatus
        }

        let payload = CreateOfferPayload(
            assistRequestId: requestId,
            offererId: userId,
            proposedTerms: proposedTerms,
            message: message,
            status: "pending"
        )

        let offer: AssistOffer = try await supabase
            .from("assist_offers")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        return offer
    }

    /// Fetch offers on a request
    func fetchOffers(for requestId: UUID) async throws -> [AssistOffer] {
        let offers: [AssistOffer] = try await supabase
            .from("assist_offers")
            .select()
            .eq("assist_request_id", value: requestId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return offers
    }

    /// Accept an offer
    func acceptOffer(offerId: UUID) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        // Get the offer
        let offer: AssistOffer = try await supabase
            .from("assist_offers")
            .select()
            .eq("id", value: offerId.uuidString)
            .single()
            .execute()
            .value

        // Get the request
        let request = try await getRequest(id: offer.assistRequestId)

        // Only requester can accept
        if request.requesterId != userId {
            throw AssistError.notYourRequest
        }

        // Request must be active
        if request.status != .active {
            throw AssistError.invalidStatus
        }

        let now = dateFormatter.string(from: Date())

        // Update the offer to accepted
        try await supabase
            .from("assist_offers")
            .update(["status": "accepted", "updated_at": now])
            .eq("id", value: offerId.uuidString)
            .execute()

        // Reject all other offers
        try await supabase
            .from("assist_offers")
            .update(["status": "rejected", "updated_at": now])
            .eq("assist_request_id", value: offer.assistRequestId.uuidString)
            .neq("id", value: offerId.uuidString)
            .execute()

        // Update request with helper and status
        let matchUpdate = MatchUpdate(
            helperId: offer.offererId,
            status: "fee_pending",
            matchedAt: now,
            updatedAt: now
        )

        try await supabase
            .from("assist_requests")
            .update(matchUpdate)
            .eq("id", value: offer.assistRequestId.uuidString)
            .execute()

        await fetchMyRequests()
    }

    /// Reject an offer
    func rejectOffer(offerId: UUID) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        // Get the offer
        let offer: AssistOffer = try await supabase
            .from("assist_offers")
            .select()
            .eq("id", value: offerId.uuidString)
            .single()
            .execute()
            .value

        // Get the request
        let request = try await getRequest(id: offer.assistRequestId)

        // Only requester can reject
        if request.requesterId != userId {
            throw AssistError.notYourRequest
        }

        let now = dateFormatter.string(from: Date())

        try await supabase
            .from("assist_offers")
            .update(["status": "rejected", "updated_at": now])
            .eq("id", value: offerId.uuidString)
            .execute()
    }

    // MARK: - Fee Payment

    /// Record fee payment
    func recordFeePaid(
        requestId: UUID,
        transactionId: String,
        isRequester: Bool
    ) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        let request = try await getRequest(id: requestId)

        // Verify user is involved
        let isReq = request.requesterId == userId
        let isHelper = request.helperId == userId

        if !isReq && !isHelper {
            throw AssistError.notInvolved
        }

        // Determine new status
        let otherPaid = isRequester ? request.helperFeePaid : request.requesterFeePaid
        let newStatus = otherPaid ? "fee_paid" : "fee_pending"

        let now = dateFormatter.string(from: Date())

        // Build update based on role
        if isRequester {
            let update = RequesterFeeUpdate(
                requesterFeePaid: true,
                requesterFeeTransactionId: transactionId,
                status: newStatus,
                updatedAt: now
            )
            try await supabase
                .from("assist_requests")
                .update(update)
                .eq("id", value: requestId.uuidString)
                .execute()
        } else {
            let update = HelperFeeUpdate(
                helperFeePaid: true,
                helperFeeTransactionId: transactionId,
                status: newStatus,
                updatedAt: now
            )
            try await supabase
                .from("assist_requests")
                .update(update)
                .eq("id", value: requestId.uuidString)
                .execute()
        }

        // Record fee transaction
        let feeTier = AssistConnectionFeeTier.tier(for: request.amountRequested)
        let feePayload = FeeTransactionPayload(
            userId: userId.uuidString,
            assistRequestId: requestId.uuidString,
            role: isRequester ? "requester" : "helper",
            productId: feeTier.productId,
            transactionId: transactionId,
            amount: feeTier.fee,
            status: "completed"
        )

        try await supabase
            .from("assist_fee_transactions")
            .insert(feePayload)
            .execute()

        await fetchMyRequests()
        await fetchMyActiveAssists()
    }

    // MARK: - Terms Negotiation

    /// Propose new terms
    func proposeTerms(requestId: UUID, terms: RepaymentTerms) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        let request = try await getRequest(id: requestId)

        // Must be involved
        if request.requesterId != userId && request.helperId != userId {
            throw AssistError.notInvolved
        }

        // Must have paid fees
        if !request.bothFeesPaid {
            throw AssistError.feesNotPaid
        }

        let now = dateFormatter.string(from: Date())

        // Update status to negotiating if not already
        if request.status == .feePaid {
            let statusUpdate = StatusUpdate(status: "negotiating", updatedAt: now)
            try await supabase
                .from("assist_requests")
                .update(statusUpdate)
                .eq("id", value: requestId.uuidString)
                .execute()
        }

        // Send terms proposal message
        let messagePayload = MessagePayload(
            assistRequestId: requestId.uuidString,
            senderId: userId.uuidString,
            messageType: "terms_proposal",
            content: nil,
            termsData: terms
        )

        try await supabase
            .from("assist_messages")
            .insert(messagePayload)
            .execute()
    }

    /// Accept proposed terms
    func acceptTerms(requestId: UUID, terms: RepaymentTerms) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        let request = try await getRequest(id: requestId)

        // Must be involved
        if request.requesterId != userId && request.helperId != userId {
            throw AssistError.notInvolved
        }

        let now = dateFormatter.string(from: Date())

        let update = TermsUpdate(
            agreedTerms: terms,
            status: "terms_accepted",
            updatedAt: now
        )

        try await supabase
            .from("assist_requests")
            .update(update)
            .eq("id", value: requestId.uuidString)
            .execute()

        // Send acceptance message
        let messagePayload = MessagePayload(
            assistRequestId: requestId.uuidString,
            senderId: userId.uuidString,
            messageType: "terms_accepted",
            content: nil,
            termsData: terms
        )

        try await supabase
            .from("assist_messages")
            .insert(messagePayload)
            .execute()

        await fetchMyRequests()
        await fetchMyActiveAssists()
    }

    // MARK: - Payment Proof

    /// Submit payment proof (helper pays the bill)
    func submitPaymentProof(
        requestId: UUID,
        screenshotUrl: String,
        verified: Bool = false,
        confidence: Double = 0
    ) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        let request = try await getRequest(id: requestId)

        // Only helper can submit payment proof
        if request.helperId != userId {
            throw AssistError.notInvolved
        }

        // Must have agreed terms
        if request.agreedTerms == nil {
            throw AssistError.termsNotAgreed
        }

        let now = dateFormatter.string(from: Date())

        // Determine status based on verification
        let newStatus: String
        let completedAt: String?

        if verified && confidence >= 0.7 {
            // Auto-verified
            newStatus = request.agreedTerms?.assistType == .loan ? "repaying" : "completed"
            completedAt = now
        } else {
            // Needs manual verification
            newStatus = "payment_sent"
            completedAt = nil
        }

        let update = PaymentProofUpdate(
            paymentScreenshotUrl: screenshotUrl,
            paymentVerified: verified,
            paymentVerifiedAt: verified ? now : nil,
            status: newStatus,
            updatedAt: now,
            completedAt: completedAt
        )

        try await supabase
            .from("assist_requests")
            .update(update)
            .eq("id", value: requestId.uuidString)
            .execute()

        // Send message
        let messagePayload = MessagePayload(
            assistRequestId: requestId.uuidString,
            senderId: userId.uuidString,
            messageType: "payment_sent",
            content: "I've paid your bill. Screenshot attached for verification.",
            termsData: nil
        )

        try await supabase
            .from("assist_messages")
            .insert(messagePayload)
            .execute()

        await fetchMyActiveAssists()
    }

    /// Verify payment (requester confirms)
    func verifyPayment(requestId: UUID) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        let request = try await getRequest(id: requestId)

        // Only requester can verify
        if request.requesterId != userId {
            throw AssistError.notYourRequest
        }

        let now = dateFormatter.string(from: Date())

        // Determine final status
        let newStatus = request.agreedTerms?.assistType == .loan ? "repaying" : "completed"

        let update = PaymentVerifiedUpdate(
            paymentVerified: true,
            paymentVerifiedAt: now,
            status: newStatus,
            updatedAt: now,
            completedAt: now
        )

        try await supabase
            .from("assist_requests")
            .update(update)
            .eq("id", value: requestId.uuidString)
            .execute()

        // Update trust stats
        await updateTrustStatsOnCompletion(request: request)

        await fetchMyRequests()
    }

    // MARK: - Repayments

    /// Record a loan repayment
    func recordRepayment(
        requestId: UUID,
        amount: Double,
        paymentMethod: String?,
        screenshotUrl: String?,
        notes: String?
    ) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        let request = try await getRequest(id: requestId)

        // Only requester can make repayments
        if request.requesterId != userId {
            throw AssistError.notYourRequest
        }

        // Must be in repaying status
        if request.status != .repaying {
            throw AssistError.invalidStatus
        }

        let payload = CreateRepaymentPayload(
            assistRequestId: requestId,
            payerId: userId,
            amount: amount,
            paymentMethod: paymentMethod,
            screenshotUrl: screenshotUrl,
            notes: notes
        )

        try await supabase
            .from("assist_repayments")
            .insert(payload)
            .execute()

        // Check if fully repaid
        let updatedRequest = try await getRequest(id: requestId)
        if updatedRequest.remainingRepayment <= 0 {
            let now = dateFormatter.string(from: Date())
            let repaidUpdate = RepaidStatusUpdate(
                status: "repaid",
                updatedAt: now,
                completedAt: now
            )
            try await supabase
                .from("assist_requests")
                .update(repaidUpdate)
                .eq("id", value: requestId.uuidString)
                .execute()

            // Update trust stats for successful repayment
            await updateRepaymentStats(userId: userId, success: true)
        }

        // Send message
        let messagePayload = MessagePayload(
            assistRequestId: requestId.uuidString,
            senderId: userId.uuidString,
            messageType: "repayment_received",
            content: "Repayment of $\(String(format: "%.2f", amount)) sent.",
            termsData: nil
        )

        try await supabase
            .from("assist_messages")
            .insert(messagePayload)
            .execute()

        await fetchMyRequests()
    }

    /// Fetch repayments for a request
    func fetchRepayments(for requestId: UUID) async throws -> [AssistRepayment] {
        let repayments: [AssistRepayment] = try await supabase
            .from("assist_repayments")
            .select()
            .eq("assist_request_id", value: requestId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return repayments
    }

    // MARK: - Ratings

    /// Rate partner after completion
    func ratePartner(
        requestId: UUID,
        rating: Int,
        review: String?,
        isRatingHelper: Bool
    ) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        let request = try await getRequest(id: requestId)

        // Must be involved
        if request.requesterId != userId && request.helperId != userId {
            throw AssistError.notInvolved
        }

        // Determine who is rating whom
        let isRequester = request.requesterId == userId

        // Requester rates helper, helper rates requester
        if isRequester != isRatingHelper {
            throw AssistError.invalidStatus
        }

        let now = dateFormatter.string(from: Date())

        if isRatingHelper {
            let update = HelperRatingUpdate(
                helperRating: rating,
                helperReview: review,
                updatedAt: now
            )
            try await supabase
                .from("assist_requests")
                .update(update)
                .eq("id", value: requestId.uuidString)
                .execute()
        } else {
            let update = RequesterRatingUpdate(
                requesterRating: rating,
                requesterReview: review,
                updatedAt: now
            )
            try await supabase
                .from("assist_requests")
                .update(update)
                .eq("id", value: requestId.uuidString)
                .execute()
        }

        // Update partner's trust rating
        let partnerId = isRatingHelper ? request.helperId : request.requesterId
        if let partnerId = partnerId {
            await updatePartnerRating(partnerId: partnerId, rating: rating, asHelper: isRatingHelper)
        }

        await fetchMyRequests()
    }

    // MARK: - Cancel/Dispute

    /// Cancel a request (only before matched)
    func cancelRequest(requestId: UUID) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        let request = try await getRequest(id: requestId)

        // Only requester can cancel
        if request.requesterId != userId {
            throw AssistError.notYourRequest
        }

        // Can only cancel active requests
        if request.status != .active {
            throw AssistError.invalidStatus
        }

        let now = dateFormatter.string(from: Date())

        try await supabase
            .from("assist_requests")
            .update(["status": "cancelled", "updated_at": now])
            .eq("id", value: requestId.uuidString)
            .execute()

        await fetchMyRequests()
    }

    /// Report a dispute
    func reportDispute(
        requestId: UUID,
        reason: AssistDisputeReason,
        description: String?
    ) async throws {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw AssistError.notAuthenticated
        }

        let request = try await getRequest(id: requestId)

        // Must be involved
        if request.requesterId != userId && request.helperId != userId {
            throw AssistError.notInvolved
        }

        // Create dispute
        let disputePayload = DisputePayload(
            assistRequestId: requestId.uuidString,
            reportedBy: userId.uuidString,
            reason: reason.rawValue,
            description: description ?? "",
            status: "open"
        )

        try await supabase
            .from("assist_disputes")
            .insert(disputePayload)
            .execute()

        // Update request status
        let now = dateFormatter.string(from: Date())
        let statusUpdate = StatusUpdate(status: "disputed", updatedAt: now)
        try await supabase
            .from("assist_requests")
            .update(statusUpdate)
            .eq("id", value: requestId.uuidString)
            .execute()

        // If ghost report, update ghost count
        if reason == .ghost {
            let ghostedUserId = request.requesterId == userId ? request.helperId : request.requesterId
            if let ghostedUserId = ghostedUserId {
                await incrementGhostCount(userId: ghostedUserId)
            }
        }

        await fetchMyRequests()
        await fetchMyActiveAssists()
    }

    // MARK: - Private Helpers

    private func updateTrustStatsOnCompletion(request: AssistRequest) async {
        guard let helperId = request.helperId else { return }

        // Update helper stats
        do {
            try await supabase.rpc("increment_assist_given", params: ["user_uuid": helperId.uuidString])
        } catch {
            print("❌ Failed to update helper stats: \(error)")
        }

        // Update requester stats
        do {
            try await supabase.rpc("increment_assist_received", params: ["user_uuid": request.requesterId.uuidString])
        } catch {
            print("❌ Failed to update requester stats: \(error)")
        }
    }

    private func updateRepaymentStats(userId: UUID, success: Bool) async {
        let column = success ? "successful_repayments" : "failed_repayments"
        do {
            try await supabase.rpc("increment_\(column)", params: ["user_uuid": userId.uuidString])
        } catch {
            print("❌ Failed to update repayment stats: \(error)")
        }
    }

    private func updatePartnerRating(partnerId: UUID, rating: Int, asHelper: Bool) async {
        // This would calculate and update the average rating
        // Simplified for now - in production would use a proper averaging function
        let column = asHelper ? "assist_rating_as_helper" : "assist_rating_as_requester"
        do {
            try await supabase
                .from("user_trust_status")
                .update([column: Double(rating)])
                .eq("user_id", value: partnerId.uuidString)
                .execute()
        } catch {
            print("❌ Failed to update partner rating: \(error)")
        }
    }

    private func incrementGhostCount(userId: UUID) async {
        do {
            // Get current ghost count
            let status: UserTrustStatus = try await supabase
                .from("user_trust_status")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            let newGhostCount = status.ghostCount + 1
            let shouldBan = newGhostCount >= 3

            if shouldBan {
                let update = GhostBanUpdate(
                    ghostCount: newGhostCount,
                    isBanned: true,
                    banReason: "Exceeded ghost limit (3 strikes)",
                    bannedAt: dateFormatter.string(from: Date())
                )
                try await supabase
                    .from("user_trust_status")
                    .update(update)
                    .eq("user_id", value: userId.uuidString)
                    .execute()
            } else {
                let update = GhostCountUpdate(ghostCount: newGhostCount)
                try await supabase
                    .from("user_trust_status")
                    .update(update)
                    .eq("user_id", value: userId.uuidString)
                    .execute()
            }
        } catch {
            print("❌ Failed to increment ghost count: \(error)")
        }
    }
}
