//
//  HouseholdModels.swift
//  Billix
//
//  Household feature models for roommate bill sharing,
//  karma tracking, and collaborative bill management.
//

import Foundation

// MARK: - Household

struct Household: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var inviteCode: String
    var headOfHouseholdId: UUID?
    var collectiveTrustScore: Int
    var maxMembers: Int
    var autoPilotEnabled: Bool
    var fairnessMode: FairnessMode
    var createdAt: Date
    var isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name
        case inviteCode = "invite_code"
        case headOfHouseholdId = "head_of_household_id"
        case collectiveTrustScore = "collective_trust_score"
        case maxMembers = "max_members"
        case autoPilotEnabled = "auto_pilot_enabled"
        case fairnessMode = "fairness_mode"
        case createdAt = "created_at"
        case isActive = "is_active"
    }

    init(id: UUID = UUID(), name: String, inviteCode: String = "", headOfHouseholdId: UUID? = nil, collectiveTrustScore: Int = 0, maxMembers: Int = 10, autoPilotEnabled: Bool = false, fairnessMode: FairnessMode = .equal, createdAt: Date = Date(), isActive: Bool = true) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.headOfHouseholdId = headOfHouseholdId
        self.collectiveTrustScore = collectiveTrustScore
        self.maxMembers = maxMembers
        self.autoPilotEnabled = autoPilotEnabled
        self.fairnessMode = fairnessMode
        self.createdAt = createdAt
        self.isActive = isActive
    }
}

// MARK: - Fairness Mode

enum FairnessMode: String, Codable, CaseIterable {
    case equal = "equal"
    case custom = "custom"
    case incomeBased = "income_based"

    var displayName: String {
        switch self {
        case .equal: return "Split Equally"
        case .custom: return "Custom Percentages"
        case .incomeBased: return "Income Based"
        }
    }

    var description: String {
        switch self {
        case .equal: return "Each member pays an equal share"
        case .custom: return "Set custom percentages for each member"
        case .incomeBased: return "Split based on relative contributions"
        }
    }

    var icon: String {
        switch self {
        case .equal: return "equal.circle.fill"
        case .custom: return "slider.horizontal.3"
        case .incomeBased: return "chart.pie.fill"
        }
    }
}

// MARK: - Household Member Model

struct HouseholdMemberModel: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    let userId: UUID
    var role: MemberRole
    var displayName: String?
    var karmaScore: Int
    var monthlyKarma: Int
    var equityPercentage: Double?
    var joinedAt: Date
    var leftAt: Date?
    var isActive: Bool

    // Populated from join query
    var userProfile: MemberProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case userId = "user_id"
        case role
        case displayName = "display_name"
        case karmaScore = "karma_score"
        case monthlyKarma = "monthly_karma"
        case equityPercentage = "equity_percentage"
        case joinedAt = "joined_at"
        case leftAt = "left_at"
        case isActive = "is_active"
        case userProfile = "profiles"
    }

    var effectiveDisplayName: String {
        displayName ?? userProfile?.displayName ?? "Member"
    }

    var avatarUrl: String? {
        userProfile?.avatarUrl
    }
}

struct MemberProfile: Codable, Equatable {
    let id: UUID?
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

enum MemberRole: String, Codable, CaseIterable {
    case head = "head"
    case admin = "admin"
    case member = "member"

    var displayName: String {
        switch self {
        case .head: return "Head of Household"
        case .admin: return "Admin"
        case .member: return "Member"
        }
    }

    var icon: String {
        switch self {
        case .head: return "crown.fill"
        case .admin: return "person.badge.key.fill"
        case .member: return "person.fill"
        }
    }

    var canManageMembers: Bool {
        self == .head || self == .admin
    }

    var canEditSettings: Bool {
        self == .head || self == .admin
    }
}

// MARK: - Household Bill

struct HouseholdBill: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    let swapBillId: UUID?
    let ownerId: UUID
    var visibility: BillVisibility
    var isShared: Bool
    var escalationStage: Int
    var escalationStartedAt: Date?
    var autoPilotEnabled: Bool
    var createdAt: Date

    // From join with swap_bills
    var swapBill: SwapBillSummary?

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case swapBillId = "swap_bill_id"
        case ownerId = "owner_id"
        case visibility
        case isShared = "is_shared"
        case escalationStage = "escalation_stage"
        case escalationStartedAt = "escalation_started_at"
        case autoPilotEnabled = "auto_pilot_enabled"
        case createdAt = "created_at"
        case swapBill = "swap_bills"
    }

    var escalationStatus: EscalationStatus {
        EscalationStatus(rawValue: escalationStage) ?? .internal
    }
}

struct SwapBillSummary: Codable, Equatable {
    let id: UUID
    let providerName: String
    let billType: String
    let amount: Double
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case providerName = "provider_name"
        case billType = "bill_type"
        case amount
        case status
    }
}

enum BillVisibility: String, Codable, CaseIterable {
    case personal = "personal"
    case household = "household"
    case `public` = "public"

    var displayName: String {
        switch self {
        case .personal: return "Personal Only"
        case .household: return "Household"
        case .public: return "Public Marketplace"
        }
    }

    var description: String {
        switch self {
        case .personal: return "Only you can see this bill"
        case .household: return "Visible to household members"
        case .public: return "Available for Bill Connection"
        }
    }

    var icon: String {
        switch self {
        case .personal: return "lock.fill"
        case .household: return "house.fill"
        case .public: return "globe"
        }
    }
}

enum EscalationStatus: Int, Codable {
    case `internal` = 0  // Day 1-2: Household only
    case alerted = 1     // Day 3: Owner notified
    case `public` = 2    // Day 4+: Public marketplace

    var displayName: String {
        switch self {
        case .internal: return "Household Only"
        case .alerted: return "Escalation Alert"
        case .public: return "Public Marketplace"
        }
    }

    var icon: String {
        switch self {
        case .internal: return "house.fill"
        case .alerted: return "exclamationmark.triangle.fill"
        case .public: return "globe"
        }
    }
}

// MARK: - Karma Event

struct KarmaEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    let userId: UUID
    let eventType: KarmaEventType
    let karmaChange: Int
    var description: String?
    var relatedBillId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case userId = "user_id"
        case eventType = "event_type"
        case karmaChange = "karma_change"
        case description
        case relatedBillId = "related_bill_id"
        case createdAt = "created_at"
    }
}

enum KarmaEventType: String, Codable, CaseIterable {
    case internalSwapCompleted = "internal_swap_completed"
    case billPaidOnTime = "bill_paid_on_time"
    case helpedRoommate = "helped_roommate"
    case uploadedSharedBill = "uploaded_shared_bill"
    case nudgeResponded = "nudge_responded"
    case autoPilotSave = "auto_pilot_save"

    var displayName: String {
        switch self {
        case .internalSwapCompleted: return "Swap Completed"
        case .billPaidOnTime: return "Paid On Time"
        case .helpedRoommate: return "Helped Roommate"
        case .uploadedSharedBill: return "Uploaded Bill"
        case .nudgeResponded: return "Responded to Nudge"
        case .autoPilotSave: return "Auto-Pilot Save"
        }
    }

    var icon: String {
        switch self {
        case .internalSwapCompleted: return "arrow.left.arrow.right.circle.fill"
        case .billPaidOnTime: return "checkmark.circle.fill"
        case .helpedRoommate: return "hand.raised.fill"
        case .uploadedSharedBill: return "doc.badge.plus"
        case .nudgeResponded: return "hand.tap.fill"
        case .autoPilotSave: return "airplane"
        }
    }

    var karmaPoints: Int {
        switch self {
        case .internalSwapCompleted: return 50
        case .billPaidOnTime: return 20
        case .helpedRoommate: return 30
        case .uploadedSharedBill: return 15
        case .nudgeResponded: return 10
        case .autoPilotSave: return 25
        }
    }
}

// MARK: - Vault Document

struct VaultDocument: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    let uploaderId: UUID
    var title: String
    var documentType: DocumentType
    var fileUrl: String
    var accessLevel: DocumentAccessLevel
    let createdAt: Date

    // From join
    var uploader: MemberProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case uploaderId = "uploader_id"
        case title
        case documentType = "document_type"
        case fileUrl = "file_url"
        case accessLevel = "access_level"
        case createdAt = "created_at"
        case uploader = "profiles"
    }
}

enum DocumentType: String, Codable, CaseIterable {
    case lease = "lease"
    case utilityBill = "utility_bill"
    case insurance = "insurance"
    case other = "other"

    var displayName: String {
        switch self {
        case .lease: return "Lease Agreement"
        case .utilityBill: return "Utility Bill"
        case .insurance: return "Insurance"
        case .other: return "Other Document"
        }
    }

    var icon: String {
        switch self {
        case .lease: return "doc.text.fill"
        case .utilityBill: return "bolt.fill"
        case .insurance: return "shield.fill"
        case .other: return "doc.fill"
        }
    }
}

enum DocumentAccessLevel: String, Codable, CaseIterable {
    case all = "all"
    case adminOnly = "admin_only"
    case ownerOnly = "owner_only"

    var displayName: String {
        switch self {
        case .all: return "All Members"
        case .adminOnly: return "Admins Only"
        case .ownerOnly: return "Owner Only"
        }
    }
}

// MARK: - Nudge Reminder

struct NudgeReminder: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    let fromUserId: UUID
    let toUserId: UUID
    var billId: UUID?
    var message: String?
    var isRead: Bool
    var respondedAt: Date?
    let createdAt: Date

    // From joins
    var fromUser: MemberProfile?
    var toUser: MemberProfile?
    var bill: HouseholdBill?

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case billId = "bill_id"
        case message
        case isRead = "is_read"
        case respondedAt = "responded_at"
        case createdAt = "created_at"
        case fromUser = "from_profiles"
        case toUser = "to_profiles"
        case bill = "household_bills"
    }
}

// MARK: - Karma Leaderboard Entry

struct KarmaLeaderboardEntry: Identifiable, Equatable {
    var id: UUID { member.id }
    let member: HouseholdMemberModel
    let rank: Int
    let isCurrentUser: Bool
    let previousRank: Int?

    var rankChange: Int? {
        guard let prev = previousRank else { return nil }
        return prev - rank // Positive = moved up
    }

    var rankChangeIcon: String? {
        guard let change = rankChange else { return nil }
        if change > 0 { return "arrow.up" }
        if change < 0 { return "arrow.down" }
        return "minus"
    }
}

// MARK: - Household Hero (Monthly Winner)

struct HouseholdHero: Identifiable, Equatable {
    var id: UUID { member.id }
    let member: HouseholdMemberModel
    let month: String
    let totalKarma: Int
    let topAchievement: KarmaEventType?
}

// MARK: - Bill Split

struct BillSplit: Identifiable, Equatable {
    let id = UUID()
    let member: HouseholdMemberModel
    var amount: Double
    var percentage: Double
    var isPaid: Bool
}

// MARK: - Create/Update DTOs

struct CreateHouseholdRequest: Codable {
    let name: String
    let fairnessMode: String

    enum CodingKeys: String, CodingKey {
        case name
        case fairnessMode = "fairness_mode"
    }
}

struct JoinHouseholdRequest: Codable {
    let inviteCode: String
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case inviteCode = "invite_code"
        case displayName = "display_name"
    }
}

struct UpdateMemberRequest: Codable {
    let displayName: String?
    let equityPercentage: Double?
    let role: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case equityPercentage = "equity_percentage"
        case role
    }
}

struct CreateNudgeRequest: Codable {
    let householdId: UUID
    let toUserId: UUID
    let billId: UUID?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case householdId = "household_id"
        case toUserId = "to_user_id"
        case billId = "bill_id"
        case message
    }
}

struct AddBillToHouseholdRequest: Codable {
    let householdId: UUID
    let swapBillId: UUID
    let visibility: String
    let autoPilotEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case householdId = "household_id"
        case swapBillId = "swap_bill_id"
        case visibility
        case autoPilotEnabled = "auto_pilot_enabled"
    }
}
