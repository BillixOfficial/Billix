//
//  RewardsViewModel.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  ViewModel for Rewards Hub - manages points, games, marketplace, leaderboard
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class RewardsViewModel: ObservableObject {

    // MARK: - Services

    private let rewardsService: RewardsService
    private let authService: AuthService
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // MARK: - Points & Wallet

    @Published var points: RewardsPoints {
        didSet {
            // Recalculate cached tier values when points change
            updateCachedTierValues()
        }
    }
    @Published var displayedBalance: Int = 0 // For animated counting
    @Published var displayedLifetime: Int = 0 // For animated counting

    // Shop unlock logic - Always accessible
    var canAccessRewardShop: Bool {
        true  // Shop is always accessible
    }

    // MARK: - Tier System (Cached)

    // Cached tier values - only recalculated when points change
    @Published private(set) var currentTier: RewardsTier = .bronze
    @Published private(set) var tierProgress: Double = 0.0

    private func updateCachedTierValues() {
        // Current tier based on LIFETIME points earned (not current balance)
        // This ensures users don't lose tier status when redeeming rewards
        currentTier = RewardsTier.allCases.last { tier in
            points.lifetimeEarned >= tier.pointsRange.lowerBound
        } ?? .bronze

        // Progress to next tier (0.0 to 1.0)
        guard let nextTier = currentTier.nextTier else {
            tierProgress = 1.0
            return
        }

        let currentMin = Double(currentTier.pointsRange.lowerBound)
        let nextMin = Double(nextTier.pointsRange.lowerBound)
        let current = Double(points.lifetimeEarned)

        let progress = (current - currentMin) / (nextMin - currentMin)
        tierProgress = max(0.0, min(progress, 1.0))
    }

    // MARK: - Milestone Claims

    @Published var claimedMilestones: Set<Int> = []
    @Published var isClaimingMilestone = false
    @Published var lastCoinClaim: Int? = nil

    // MARK: - Daily Game

    @Published var dailyGame: DailyGame? = .preview
    @Published var todaysResult: GameResult?
    @Published var gamesPlayedToday: Int = 0
    @Published var showGeoGame: Bool = false
    @Published var activeGame: DailyGame?
    @Published var showSeasonSelection: Bool = false

    // MARK: - Marketplace

    @Published var rewards: [Reward] = Reward.previewRewardsWithCategories
    @Published var donationRequests: [DonationRequest] = []
    @Published var selectedReward: Reward?
    @Published var selectedBrandGroup: String?
    @Published var showAmountSheet: Bool = false
    @Published var showDonationRequestSheet: Bool = false

    // MARK: - Leaderboard

    @Published var topSavers: [LeaderboardEntry] = []
    @Published var currentUserRank: LeaderboardEntry?
    @Published var showFullLeaderboard: Bool = false

    // MARK: - UI State

    @Published var isLoading: Bool = false
    @Published var showRedeemSheet: Bool = false
    @Published var showAllRewards: Bool = false
    @Published var errorMessage: String?

    // MARK: - Animation & Task Management

    private var animationTask: Task<Void, Never>?
    private var lifetimeAnimationTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    private var pointsTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        rewardsService: RewardsService = RewardsService(),
        authService: AuthService
    ) {
        self.rewardsService = rewardsService
        self.authService = authService

        // Initialize with empty points data (will load from backend)
        self.points = RewardsPoints(balance: 0, lifetimeEarned: 0, transactions: [])

        // Initialize cached tier values
        updateCachedTierValues()

        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        // Listen for points updates from task claims
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PointsUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.loadRewardsData()
            }
        }
    }

    deinit {
        // Cancel all running tasks to prevent memory leaks
        animationTask?.cancel()
        lifetimeAnimationTask?.cancel()
        loadTask?.cancel()
        pointsTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    func loadRewardsData() async {
        isLoading = true

        do {
            // Get current user ID
            guard let userId = authService.currentUser?.id else {
                isLoading = false
                return
            }

            // Fetch user points and lifetime from Supabase
            let balance = try await rewardsService.getUserPoints(userId: userId)
            let lifetime = try await rewardsService.getLifetimePoints(userId: userId)

            points = RewardsPoints(
                balance: balance,
                lifetimeEarned: max(balance, lifetime),
                transactions: []
            )

            // Fetch claimed milestones
            claimedMilestones = try await rewardsService.getClaimedMilestones(userId: userId)

            // Filter rewards to only include Target, Kroger, and Walmart gift cards
            let allRewards = Reward.previewRewardsWithCategories
            rewards = allRewards.filter { reward in
                // Only include gift cards with brandGroup: target, kroger, or walmart
                if reward.category == .giftCard {
                    return ["target", "kroger", "walmart"].contains(reward.brandGroup ?? "")
                }
                return false
            }

            // Fetch real leaderboard data
            let leaderboard = try await rewardsService.fetchLeaderboard(currentUserId: userId)
            topSavers = leaderboard.entries
            currentUserRank = leaderboard.currentUserEntry

            dailyGame = GeoGameDataService.getTodaysGame()

            // Animate both counters on load
            animateBalanceChange(to: points.balance)
            animateLifetimeChange(to: points.lifetimeEarned)

        } catch {
            // Error loading rewards data
            // Initialize with empty data on error
            points = RewardsPoints(balance: 0, lifetimeEarned: 0, transactions: [])
        }

        isLoading = false
    }

    func animateBalanceChange(to newBalance: Int) {
        // Cancel any previous animation to prevent stacking
        animationTask?.cancel()

        let startBalance = displayedBalance
        let difference = newBalance - startBalance

        // If no change, just set directly
        guard difference != 0 else {
            displayedBalance = newBalance
            return
        }

        let steps = 20
        let stepDurationNs: UInt64 = 30_000_000 // 30ms in nanoseconds

        // Create a cancellable Task for animation
        animationTask = Task { [weak self] in
            for i in 0...steps {
                // Check for cancellation
                if Task.isCancelled { return }

                let progress = Double(i) / Double(steps)
                let easedProgress = 1 - pow(1 - progress, 3) // Ease out cubic

                await MainActor.run { [weak self] in
                    self?.displayedBalance = startBalance + Int(Double(difference) * easedProgress)
                }

                // Use Task.sleep instead of Thread.sleep (non-blocking)
                if i < steps {
                    try? await Task.sleep(nanoseconds: stepDurationNs)
                }
            }

            // Ensure final value is exact
            await MainActor.run { [weak self] in
                self?.displayedBalance = newBalance
            }
        }
    }

    func animateLifetimeChange(to newLifetime: Int) {
        lifetimeAnimationTask?.cancel()

        let startLifetime = displayedLifetime
        let difference = newLifetime - startLifetime

        guard difference != 0 else {
            displayedLifetime = newLifetime
            return
        }

        let steps = 20
        let stepDurationNs: UInt64 = 30_000_000 // 30ms

        lifetimeAnimationTask = Task { [weak self] in
            for i in 0...steps {
                if Task.isCancelled { return }

                let progress = Double(i) / Double(steps)
                let easedProgress = 1 - pow(1 - progress, 3) // Ease out cubic

                await MainActor.run { [weak self] in
                    self?.displayedLifetime = startLifetime + Int(Double(difference) * easedProgress)
                }

                if i < steps {
                    try? await Task.sleep(nanoseconds: stepDurationNs)
                }
            }

            await MainActor.run { [weak self] in
                self?.displayedLifetime = newLifetime
            }
        }
    }

    func addPoints(_ amount: Int, description: String, type: PointTransactionType = .gameWin) {
        // Cancel any previous points operation
        pointsTask?.cancel()

        pointsTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                guard let userId = self.authService.currentUser?.id else {
                    return
                }

                // Check for cancellation before network call
                if Task.isCancelled { return }

                // Add points via Supabase service
                let newBalance = try await self.rewardsService.addPoints(
                    userId: userId,
                    amount: amount,
                    type: type.rawValue,
                    description: description
                )

                // Check for cancellation after network call
                if Task.isCancelled { return }

                self.points.balance = newBalance
                self.points.lifetimeEarned = newBalance

                // Animate the balance change
                self.animateBalanceChange(to: self.points.balance)

            } catch {
                if !Task.isCancelled {
                    // Failed to add points
                }
            }
        }
    }

    // MARK: - Milestone Enrichment & Claiming

    func enrichedMilestones(for tier: RewardsTier) -> [GaugeMilestone] {
        let base: [GaugeMilestone]
        switch tier {
        case .bronze: base = SpeedometerGauge.bronzeMilestones()
        case .silver: base = SpeedometerGauge.silverMilestones()
        case .gold: base = SpeedometerGauge.goldMilestones()
        case .platinum: base = SpeedometerGauge.platinumMilestones()
        }

        return base.map { milestone in
            var m = milestone
            if milestone.coinReward > 0 {
                if claimedMilestones.contains(milestone.points) {
                    m.claimState = .claimed
                } else if points.lifetimeEarned >= milestone.points {
                    m.claimState = .claimable
                } else {
                    m.claimState = .notReached
                }
            }
            return m
        }
    }

    func claimMilestone(_ milestone: GaugeMilestone) {
        guard !isClaimingMilestone, milestone.claimState == .claimable else { return }
        isClaimingMilestone = true

        Task { [weak self] in
            guard let self = self else { return }
            guard let userId = self.authService.currentUser?.id else {
                self.isClaimingMilestone = false
                return
            }

            do {
                let tierName: String
                switch self.currentTier {
                case .bronze: tierName = "bronze"
                case .silver: tierName = "silver"
                case .gold: tierName = "gold"
                case .platinum: tierName = "platinum"
                }

                let newBalance = try await self.rewardsService.claimMilestoneReward(
                    userId: userId,
                    milestonePoints: milestone.points,
                    coinReward: milestone.coinReward,
                    tier: tierName
                )

                // Update local state immediately
                self.claimedMilestones.insert(milestone.points)
                self.points.balance = newBalance

                // Trigger floating coin animation
                self.lastCoinClaim = milestone.coinReward

                // Success haptic
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                // Reload all data from server to refresh lifetime, gauge, etc.
                await self.loadRewardsData()

                // Auto-clear coin animation after 2.5s
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                self.lastCoinClaim = nil
            } catch {
                // Failed to claim milestone
            }

            self.isClaimingMilestone = false
        }
    }

    func canAffordReward(_ reward: Reward) -> Bool {
        points.balance >= reward.pointsCost
    }

    func progressTowardReward(_ reward: Reward) -> Double {
        min(Double(points.balance) / Double(reward.pointsCost), 1.0)
    }

    func pointsNeededFor(_ reward: Reward) -> Int {
        max(reward.pointsCost - points.balance, 0)
    }

    func redeemReward(_ reward: Reward) {
        guard canAffordReward(reward) else { return }

        // Cancel any previous points operation
        pointsTask?.cancel()

        pointsTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                guard let userId = self.authService.currentUser?.id else {
                    return
                }

                // Check for cancellation
                if Task.isCancelled { return }

                // Deduct points via deductPoints service
                let newBalance = try await self.rewardsService.deductPoints(
                    userId: userId,
                    amount: reward.pointsCost
                )

                // Check for cancellation
                if Task.isCancelled { return }

                self.points.balance = newBalance
                self.animateBalanceChange(to: self.points.balance)
                self.showRedeemSheet = false

            } catch {
                if !Task.isCancelled {
                    // Failed to redeem reward
                }
            }
        }
    }

    func redeemGiftCard(_ reward: Reward, email: String) async {
        guard canAffordReward(reward) else { return }
        guard let userId = authService.currentUser?.id else { return }

        do {
            // 1. Save redemption to database
            struct GiftCardRedemption: Encodable {
                let user_id: String
                let reward_id: String
                let reward_title: String
                let points_spent: Int
                let delivery_email: String
                let status: String
            }

            let redemption = GiftCardRedemption(
                user_id: userId.uuidString,
                reward_id: reward.id.uuidString,
                reward_title: reward.title,
                points_spent: reward.pointsCost,
                delivery_email: email,
                status: "pending"
            )

            try await supabase
                .from("gift_card_redemptions")
                .insert(redemption)
                .execute()

            // 2. Deduct points via RewardsService
            let newBalance = try await rewardsService.deductPoints(
                userId: userId,
                amount: reward.pointsCost
            )

            // 3. Update local state
            points.balance = newBalance
            animateBalanceChange(to: points.balance)

        } catch {
            // Error redeeming gift card
            errorMessage = "Failed to redeem gift card. Please try again."
        }
    }

    func selectBrandForAmountSheet(brandGroup: String) {
        selectedBrandGroup = brandGroup
        showAmountSheet = true
    }

    func getRewardsForBrand(_ brandGroup: String) -> [Reward] {
        rewards.filter { $0.brandGroup == brandGroup }
    }

    func playDailyGame() {
        // Show season selection view for structured progression
        showSeasonSelection = true
    }

    func handleGameResult(_ result: GameResult) {
        todaysResult = result
        gamesPlayedToday += 1

        // Post GameCompleted notification for task tracking
        // Points will be awarded when user claims the weekly task (Play 7 games = 500 pts)
        NotificationCenter.default.post(
            name: NSNotification.Name("GameCompleted"),
            object: nil,
            userInfo: [
                "sessionId": UUID(), // Generate a session ID for tracking
                "pointsEarned": result.pointsEarned // Preserved for metadata, but not awarded immediately
            ]
        )
    }

    func closeGeoGame() {
        showGeoGame = false
        activeGame = nil
    }

    func playAgain() {
        // Get a new random game
        activeGame = GeoGameDataService.getRandomGame()
    }

    // MARK: - Donation Methods

    func startDonationRequest() {
        showDonationRequestSheet = true
    }

    func submitDonationRequest(
        organizationName: String,
        websiteOrLocation: String,
        amount: DonationAmount
    ) async {
        guard points.balance >= amount.pointsCost else { return }
        guard let userId = authService.currentUser?.id else { return }

        do {
            // 1. Save donation request to database
            struct DonationRequestInsert: Encodable {
                let user_id: String
                let organization_name: String
                let website_or_location: String
                let donation_amount_usd: Int
                let points_spent: Int
                let status: String
            }

            let request = DonationRequestInsert(
                user_id: userId.uuidString,
                organization_name: organizationName,
                website_or_location: websiteOrLocation,
                donation_amount_usd: amount.rawValue,
                points_spent: amount.pointsCost,
                status: "pending"
            )

            try await supabase
                .from("donation_requests")
                .insert(request)
                .execute()

            // 2. Deduct points via RewardsService
            let newBalance = try await rewardsService.deductPoints(
                userId: userId,
                amount: amount.pointsCost
            )

            // 3. Update local state
            points.balance = newBalance
            animateBalanceChange(to: points.balance)

            showDonationRequestSheet = false
        } catch {
            // Error submitting donation
            errorMessage = "Failed to submit donation request. Please try again."
        }
    }

}
