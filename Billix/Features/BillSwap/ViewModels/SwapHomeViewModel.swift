//
//  SwapHomeViewModel.swift
//  Billix
//
//  ViewModel for the BillSwap home feed
//

import Foundation
import Combine
import Supabase

// MARK: - Bill With User Model

/// Combines a swap bill with its owner's profile information
struct SwapBillWithUser: Identifiable, Equatable {
    let bill: SwapBill
    let userHandle: String
    let userDisplayName: String?
    let userAvatarUrl: String?

    var id: UUID { bill.id }

    var userInitials: String {
        if let name = userDisplayName, !name.isEmpty {
            let components = name.split(separator: " ")
            if components.count >= 2 {
                return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
            }
            return String(name.prefix(2)).uppercased()
        }
        return String(userHandle.prefix(2)).uppercased()
    }

    static func == (lhs: SwapBillWithUser, rhs: SwapBillWithUser) -> Bool {
        lhs.bill == rhs.bill
    }
}

/// ViewModel for the main BillSwap feed
@MainActor
class SwapHomeViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var myBills: [SwapBill] = []
    @Published var myBillsWithUsers: [SwapBillWithUser] = []
    @Published var potentialMatches: [SwapBill] = []
    @Published var matchesWithUsers: [SwapBillWithUser] = []
    @Published var activeSwaps: [BillSwapTransaction] = []
    @Published var completedSwaps: [BillSwapTransaction] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false

    // Tier tracking
    @Published var currentTier: Int = 1
    @Published var completedSwapsCount: Int = 0

    // MARK: - Services
    private let billService = SwapBillService.shared
    private let swapService = SwapService.shared
    private var supabase: SupabaseClient { SupabaseService.shared.client }

    // MARK: - User Profile Cache
    private var userProfileCache: [UUID: (handle: String, displayName: String?, avatarUrl: String?)] = [:]

    // MARK: - Computed Properties

    var hasUnmatchedBills: Bool {
        myBills.contains { $0.status == .unmatched }
    }

    var unmatchedBills: [SwapBill] {
        myBills.filter { $0.status == .unmatched }
    }

    var matchedBills: [SwapBill] {
        myBills.filter { $0.status == .matched }
    }

    var hasActiveSwaps: Bool {
        !activeSwaps.isEmpty
    }

    var hasPotentialMatches: Bool {
        !potentialMatches.isEmpty
    }

    // MARK: - Initialization

    init() {
        // Observe service updates
        setupObservers()
    }

    private func setupObservers() {
        // Observe bill service
        billService.$myBills
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bills in
                self?.myBills = bills
                Task { await self?.enrichBillsWithUsers() }
            }
            .store(in: &cancellables)

        billService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        // Observe swap service
        swapService.$potentialMatches
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matches in
                self?.potentialMatches = matches
                Task { await self?.enrichBillsWithUsers() }
            }
            .store(in: &cancellables)

        swapService.$activeSwaps
            .receive(on: DispatchQueue.main)
            .assign(to: &$activeSwaps)

        swapService.$completedSwaps
            .receive(on: DispatchQueue.main)
            .assign(to: &$completedSwaps)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Data Loading

    /// Load all data for the home feed
    func loadData() async {
        isLoading = true
        error = nil

        do {
            // Load in parallel
            async let bills: () = billService.fetchMyBills()
            async let swaps: () = swapService.fetchMySwaps()
            async let matches: () = swapService.findAllMatches()
            async let tierInfo: () = fetchTierInfo()

            _ = try await (bills, swaps, matches, tierInfo)

            // Enrich bills with user data
            await enrichBillsWithUsers()
        } catch {
            self.error = error
            self.showError = true
        }

        isLoading = false
    }

    // MARK: - Tier Info

    /// Fetch current user's tier information
    func fetchTierInfo() async {
        guard let userId = AuthService.shared.currentUser?.id else { return }

        do {
            // Fetch from swap_trust table
            struct SwapTrust: Decodable {
                let tier: Int
                let successful_swaps: Int
            }

            let trustRecords: [SwapTrust] = try await supabase
                .from("swap_trust")
                .select("tier, successful_swaps")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            if let trust = trustRecords.first {
                self.currentTier = trust.tier
                self.completedSwapsCount = trust.successful_swaps
            } else {
                // Default for new users
                self.currentTier = 1
                self.completedSwapsCount = 0
            }
        } catch {
            // Default to Tier 1 on error
            print("Failed to fetch tier info: \(error)")
            self.currentTier = 1
            self.completedSwapsCount = 0
        }
    }

    // MARK: - User Profile Fetching

    /// Fetch user profile info for a user ID
    private func fetchUserProfile(userId: UUID) async -> (handle: String, displayName: String?, avatarUrl: String?)? {
        // Check cache first
        if let cached = userProfileCache[userId] {
            return cached
        }

        do {
            // Fetch from profiles table
            let profiles: [BillixProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            if let profile = profiles.first {
                let result = (handle: profile.handle, displayName: profile.displayName, avatarUrl: nil as String?)
                userProfileCache[userId] = result
                return result
            }
        } catch {
            print("Failed to fetch profile for user \(userId): \(error)")
        }

        // Return default if profile not found
        let defaultResult = (handle: "user", displayName: nil as String?, avatarUrl: nil as String?)
        userProfileCache[userId] = defaultResult
        return defaultResult
    }

    /// Enrich all bills with user profile information
    private func enrichBillsWithUsers() async {
        // Enrich my bills
        var enrichedMyBills: [SwapBillWithUser] = []
        for bill in myBills {
            if let profile = await fetchUserProfile(userId: bill.userId) {
                enrichedMyBills.append(SwapBillWithUser(
                    bill: bill,
                    userHandle: profile.handle,
                    userDisplayName: profile.displayName,
                    userAvatarUrl: profile.avatarUrl
                ))
            }
        }
        self.myBillsWithUsers = enrichedMyBills

        // Enrich potential matches
        var enrichedMatches: [SwapBillWithUser] = []
        for bill in potentialMatches {
            if let profile = await fetchUserProfile(userId: bill.userId) {
                enrichedMatches.append(SwapBillWithUser(
                    bill: bill,
                    userHandle: profile.handle,
                    userDisplayName: profile.displayName,
                    userAvatarUrl: profile.avatarUrl
                ))
            }
        }
        self.matchesWithUsers = enrichedMatches
    }

    /// Refresh data
    func refresh() async {
        await loadData()
    }

    // MARK: - Bill Actions

    /// Delete a bill
    func deleteBill(_ bill: SwapBill) async {
        do {
            try await billService.deleteBill(billId: bill.id)
            // Refresh matches after deletion
            try await swapService.findAllMatches()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Swap Actions

    /// Create a swap with a matched bill
    func createSwap(myBill: SwapBill, partnerBill: SwapBill) async {
        do {
            _ = try await swapService.createSwap(
                myBillId: myBill.id,
                partnerBillId: partnerBill.id,
                partnerUserId: partnerBill.userId
            )
        } catch {
            self.error = error
            self.showError = true
        }
    }
}
