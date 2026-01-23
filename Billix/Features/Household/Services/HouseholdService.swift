//
//  HouseholdService.swift
//  Billix
//
//  Service for household CRUD operations, member management,
//  and household-related queries.
//

import Foundation
import Supabase

@MainActor
class HouseholdService: ObservableObject {
    static let shared = HouseholdService()

    private let supabase = SupabaseService.shared.client

    @Published var currentHousehold: Household?
    @Published var members: [HouseholdMemberModel] = []
    @Published var householdBills: [HouseholdBill] = []
    @Published var isLoading = false
    @Published var error: String?

    private init() {}

    // MARK: - Household CRUD

    /// Create a new household and make current user the head
    func createHousehold(name: String, fairnessMode: FairnessMode = .equal) async throws -> Household {
        guard let userId = supabase.auth.currentUser?.id else {
            throw HouseholdError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Create household
        let request = CreateHouseholdRequest(name: name, fairnessMode: fairnessMode.rawValue)

        let household: Household = try await supabase
            .from("households")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        // Add creator as head of household
        let memberInsert: [String: AnyEncodable] = [
            "household_id": AnyEncodable(household.id),
            "user_id": AnyEncodable(userId),
            "role": AnyEncodable("head"),
            "is_active": AnyEncodable(true)
        ]

        try await supabase
            .from("household_members")
            .insert(memberInsert)
            .execute()

        // Update household with head_of_household_id
        try await supabase
            .from("households")
            .update(["head_of_household_id": userId.uuidString])
            .eq("id", value: household.id.uuidString)
            .execute()

        var updatedHousehold = household
        updatedHousehold.headOfHouseholdId = userId

        currentHousehold = updatedHousehold
        await fetchMembers()

        return updatedHousehold
    }

    /// Fetch the current user's household
    func fetchCurrentHousehold() async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw HouseholdError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // First get the user's household membership
        let membership: HouseholdMemberModel? = try await supabase
            .from("household_members")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_active", value: true)
            .is("left_at", value: nil)
            .single()
            .execute()
            .value

        guard let membership = membership else {
            currentHousehold = nil
            members = []
            return
        }

        // Fetch the household
        let household: Household = try await supabase
            .from("households")
            .select()
            .eq("id", value: membership.householdId.uuidString)
            .single()
            .execute()
            .value

        currentHousehold = household
        await fetchMembers()
    }

    /// Join a household using invite code
    func joinHousehold(inviteCode: String, displayName: String? = nil) async throws -> Household {
        guard let userId = supabase.auth.currentUser?.id else {
            throw HouseholdError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Find household by invite code
        let household: Household = try await supabase
            .from("households")
            .select()
            .eq("invite_code", value: inviteCode.uppercased())
            .eq("is_active", value: true)
            .single()
            .execute()
            .value

        // Check if already a member
        let existingMembership: [HouseholdMemberModel] = try await supabase
            .from("household_members")
            .select()
            .eq("household_id", value: household.id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        if let existing = existingMembership.first {
            if existing.isActive && existing.leftAt == nil {
                throw HouseholdError.alreadyMember
            }
            // Rejoin - update existing membership
            let rejoinUpdates: [String: AnyEncodable] = [
                "is_active": AnyEncodable(true),
                "left_at": AnyEncodable(nil as String?),
                "joined_at": AnyEncodable(ISO8601DateFormatter().string(from: Date())),
                "display_name": AnyEncodable(displayName)
            ]

            try await supabase
                .from("household_members")
                .update(rejoinUpdates)
                .eq("id", value: existing.id.uuidString)
                .execute()
        } else {
            // Check member limit
            let memberCount: Int = try await supabase
                .from("household_members")
                .select("*", head: true, count: .exact)
                .eq("household_id", value: household.id.uuidString)
                .eq("is_active", value: true)
                .execute()
                .count ?? 0

            if memberCount >= household.maxMembers {
                throw HouseholdError.householdFull
            }

            // Add as new member
            let memberInsert: [String: AnyEncodable] = [
                "household_id": AnyEncodable(household.id),
                "user_id": AnyEncodable(userId),
                "role": AnyEncodable("member"),
                "display_name": AnyEncodable(displayName),
                "is_active": AnyEncodable(true)
            ]

            try await supabase
                .from("household_members")
                .insert(memberInsert)
                .execute()
        }

        currentHousehold = household
        await fetchMembers()

        return household
    }

    /// Leave current household
    func leaveHousehold() async throws {
        guard let userId = supabase.auth.currentUser?.id,
              let household = currentHousehold else {
            throw HouseholdError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Soft delete - set left_at timestamp
        let leaveUpdates: [String: AnyEncodable] = [
            "is_active": AnyEncodable(false),
            "left_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]

        try await supabase
            .from("household_members")
            .update(leaveUpdates)
            .eq("household_id", value: household.id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()

        currentHousehold = nil
        members = []
    }

    /// Update household settings
    func updateHousehold(name: String? = nil, fairnessMode: FairnessMode? = nil, autoPilotEnabled: Bool? = nil) async throws {
        guard let household = currentHousehold else {
            throw HouseholdError.noHousehold
        }

        var updates: [String: AnyEncodable] = [:]
        if let name = name { updates["name"] = AnyEncodable(name) }
        if let mode = fairnessMode { updates["fairness_mode"] = AnyEncodable(mode.rawValue) }
        if let autoPilot = autoPilotEnabled { updates["auto_pilot_enabled"] = AnyEncodable(autoPilot) }

        guard !updates.isEmpty else { return }

        let updated: Household = try await supabase
            .from("households")
            .update(updates)
            .eq("id", value: household.id.uuidString)
            .select()
            .single()
            .execute()
            .value

        currentHousehold = updated
    }

    // MARK: - Member Management

    /// Fetch all active members of current household
    func fetchMembers() async {
        guard let household = currentHousehold else {
            members = []
            return
        }

        do {
            let fetchedMembers: [HouseholdMemberModel] = try await supabase
                .from("household_members")
                .select("*, profiles:user_id(id, display_name, avatar_url)")
                .eq("household_id", value: household.id.uuidString)
                .eq("is_active", value: true)
                .is("left_at", value: nil)
                .order("karma_score", ascending: false)
                .execute()
                .value

            members = fetchedMembers
        } catch {
            print("Failed to fetch members: \(error)")
            self.error = error.localizedDescription
        }
    }

    /// Update member's display name or equity percentage
    func updateMember(memberId: UUID, displayName: String? = nil, equityPercentage: Double? = nil) async throws {
        var updates: [String: AnyEncodable] = [:]
        if let name = displayName { updates["display_name"] = AnyEncodable(name) }
        if let equity = equityPercentage { updates["equity_percentage"] = AnyEncodable(equity) }

        guard !updates.isEmpty else { return }

        try await supabase
            .from("household_members")
            .update(updates)
            .eq("id", value: memberId.uuidString)
            .execute()

        await fetchMembers()
    }

    /// Change member's role (admin only)
    func updateMemberRole(memberId: UUID, newRole: MemberRole) async throws {
        guard canManageMembers() else {
            throw HouseholdError.insufficientPermissions
        }

        try await supabase
            .from("household_members")
            .update(["role": newRole.rawValue])
            .eq("id", value: memberId.uuidString)
            .execute()

        await fetchMembers()
    }

    /// Remove member from household (admin only)
    func removeMember(memberId: UUID) async throws {
        guard canManageMembers() else {
            throw HouseholdError.insufficientPermissions
        }

        let removeUpdates: [String: AnyEncodable] = [
            "is_active": AnyEncodable(false),
            "left_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]

        try await supabase
            .from("household_members")
            .update(removeUpdates)
            .eq("id", value: memberId.uuidString)
            .execute()

        await fetchMembers()
    }

    // MARK: - Household Bills

    /// Fetch bills shared with the household
    func fetchHouseholdBills() async throws {
        guard let household = currentHousehold else {
            throw HouseholdError.noHousehold
        }

        let bills: [HouseholdBill] = try await supabase
            .from("household_bills")
            .select("*, swap_bills(id, provider_name, bill_type, amount, status)")
            .eq("household_id", value: household.id.uuidString)
            .neq("visibility", value: "personal")
            .order("created_at", ascending: false)
            .execute()
            .value

        householdBills = bills
    }

    /// Add a bill to the household
    func addBillToHousehold(swapBillId: UUID, visibility: BillVisibility = .household, autoPilotEnabled: Bool = false) async throws {
        guard let household = currentHousehold,
              let userId = supabase.auth.currentUser?.id else {
            throw HouseholdError.noHousehold
        }

        let request = AddBillToHouseholdRequest(
            householdId: household.id,
            swapBillId: swapBillId,
            visibility: visibility.rawValue,
            autoPilotEnabled: autoPilotEnabled
        )

        var insertData: [String: AnyEncodable] = [
            "household_id": AnyEncodable(household.id),
            "swap_bill_id": AnyEncodable(swapBillId),
            "owner_id": AnyEncodable(userId),
            "visibility": AnyEncodable(visibility.rawValue),
            "auto_pilot_enabled": AnyEncodable(autoPilotEnabled)
        ]

        if autoPilotEnabled {
            insertData["escalation_started_at"] = AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        }

        try await supabase
            .from("household_bills")
            .insert(insertData)
            .execute()

        try await fetchHouseholdBills()
    }

    /// Update bill visibility
    func updateBillVisibility(billId: UUID, visibility: BillVisibility) async throws {
        try await supabase
            .from("household_bills")
            .update(["visibility": visibility.rawValue])
            .eq("id", value: billId.uuidString)
            .execute()

        try await fetchHouseholdBills()
    }

    // MARK: - Helpers

    /// Check if current user can manage members (is head or admin)
    func canManageMembers() -> Bool {
        guard let userId = supabase.auth.currentUser?.id else { return false }
        return members.first { $0.userId == userId }?.role.canManageMembers ?? false
    }

    /// Check if current user can edit settings
    func canEditSettings() -> Bool {
        guard let userId = supabase.auth.currentUser?.id else { return false }
        return members.first { $0.userId == userId }?.role.canEditSettings ?? false
    }

    /// Get current user's membership
    func getCurrentMembership() -> HouseholdMemberModel? {
        guard let userId = supabase.auth.currentUser?.id else { return nil }
        return members.first { $0.userId == userId }
    }

    /// Generate a share message for the household invite code
    func generateInviteMessage() -> String? {
        guard let household = currentHousehold else { return nil }
        return "Join my household \"\(household.name)\" on Billix! Use code: \(household.inviteCode)"
    }
}

// MARK: - Errors

enum HouseholdError: LocalizedError {
    case notAuthenticated
    case noHousehold
    case alreadyMember
    case householdFull
    case insufficientPermissions
    case invalidInviteCode

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .noHousehold:
            return "You're not part of a household"
        case .alreadyMember:
            return "You're already a member of this household"
        case .householdFull:
            return "This household has reached its member limit"
        case .insufficientPermissions:
            return "You don't have permission to perform this action"
        case .invalidInviteCode:
            return "Invalid invite code"
        }
    }
}

// MARK: - AnyEncodable Helper

struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
