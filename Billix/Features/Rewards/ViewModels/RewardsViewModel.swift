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

    @Published var points: RewardsPoints
    @Published var displayedBalance: Int = 0 // For animated counting

    // Shop unlock logic - Always accessible
    var canAccessRewardShop: Bool {
        true  // Shop is always accessible
    }

    // MARK: - Tier System

    // Current tier based on LIFETIME points earned (not current balance)
    // This ensures users don't lose tier status when redeeming rewards
    var currentTier: RewardsTier {
        RewardsTier.allCases.last { tier in
            points.lifetimeEarned >= tier.pointsRange.lowerBound
        } ?? .bronze
    }

    // Progress to next tier (0.0 to 1.0)
    var tierProgress: Double {
        guard let nextTier = currentTier.nextTier else { return 1.0 }

        let currentMin = Double(currentTier.pointsRange.lowerBound)
        let nextMin = Double(nextTier.pointsRange.lowerBound)
        let current = Double(points.lifetimeEarned)

        let progress = (current - currentMin) / (nextMin - currentMin)
        return max(0.0, min(progress, 1.0))
    }

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

    @Published var topSavers: [LeaderboardEntry] = LeaderboardEntry.previewEntries
    @Published var currentUserRank: LeaderboardEntry = LeaderboardEntry.currentUserEntry

    // MARK: - UI State

    @Published var isLoading: Bool = false
    @Published var showHistory: Bool = false
    @Published var showRedeemSheet: Bool = false
    @Published var showAllRewards: Bool = false
    @Published var errorMessage: String?

    // MARK: - Timer

    private var countdownTimer: Timer?

    // MARK: - Initialization

    init(
        rewardsService: RewardsService = RewardsService(),
        authService: AuthService
    ) {
        self.rewardsService = rewardsService
        self.authService = authService

        // Initialize with empty points data (will load from backend)
        self.points = RewardsPoints(balance: 0, lifetimeEarned: 0, transactions: [])

        setupCountdownTimer()
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        // Listen for points updates from task claims
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PointsUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔔 RewardsViewModel received PointsUpdated notification")
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("🔄 Refreshing rewards data...")
                await self.loadRewardsData()
                print("✅ Rewards data refreshed")
            }
        }
    }

    deinit {
        countdownTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    func loadRewardsData() async {
        isLoading = true

        do {
            // Get current user ID
            guard let userId = authService.currentUser?.id else {
                print("⚠️ No authenticated user - using empty points data")
                isLoading = false
                return
            }

            // Fetch user points from Supabase (simplified - just balance)
            let balance = try await rewardsService.getUserPoints(userId: userId)

            // Simplified points model (no transaction history)
            points = RewardsPoints(
                balance: balance,
                lifetimeEarned: balance, // Use balance as lifetime since we no longer track separately
                transactions: []
            )

            // Filter rewards to only include Target, Kroger, and Walmart gift cards
            let allRewards = Reward.previewRewardsWithCategories
            rewards = allRewards.filter { reward in
                // Only include gift cards with brandGroup: target, kroger, or walmart
                if reward.category == .giftCard {
                    return ["target", "kroger", "walmart"].contains(reward.brandGroup ?? "")
                }
                return false
            }

            topSavers = LeaderboardEntry.previewEntries
            dailyGame = GeoGameDataService.getTodaysGame()

            // Animate balance on load
            animateBalanceChange(to: points.balance)

        } catch {
            print("❌ Failed to load rewards data: \(error)")
            // Initialize with empty data on error
            points = RewardsPoints(balance: 0, lifetimeEarned: 0, transactions: [])
        }

        isLoading = false
    }

    func animateBalanceChange(to newBalance: Int) {
        let startBalance = displayedBalance
        let difference = newBalance - startBalance
        let steps = 20
        let stepDuration: TimeInterval = 0.03

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                let progress = Double(i) / Double(steps)
                let easedProgress = 1 - pow(1 - progress, 3) // Ease out cubic
                self?.displayedBalance = startBalance + Int(Double(difference) * easedProgress)
            }
        }
    }

    func addPoints(_ amount: Int, description: String, type: PointTransactionType = .gameWin) {
        Task {
            do {
                guard let userId = self.authService.currentUser?.id else {
                    print("⚠️ No authenticated user - cannot add points")
                    return
                }

                // Add points via Supabase service
                let newBalance = try await rewardsService.addPoints(
                    userId: userId,
                    amount: amount,
                    type: type.rawValue,
                    description: description
                )

                await MainActor.run {
                    points.balance = newBalance
                    points.lifetimeEarned = newBalance

                    // Animate the balance change
                    animateBalanceChange(to: points.balance)
                }

            } catch {
                print("❌ Failed to add points: \(error)")
            }
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

        Task {
            do {
                guard let userId = self.authService.currentUser?.id else {
                    print("⚠️ No authenticated user - cannot redeem reward")
                    return
                }

                // Deduct points via deductPoints service
                let newBalance = try await rewardsService.deductPoints(
                    userId: userId,
                    amount: reward.pointsCost
                )

                await MainActor.run {
                    points.balance = newBalance

                    animateBalanceChange(to: points.balance)
                    showRedeemSheet = false
                }

            } catch {
                print("❌ Failed to redeem reward: \(error)")
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

            print("✅ Gift card redemption saved to database")
        } catch {
            print("❌ Error redeeming gift card: \(error)")
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

        print("📤 Posted GameCompleted notification - points will be awarded via weekly task claim")
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
            print("✅ Donation request saved to database")
        } catch {
            print("❌ Error submitting donation: \(error)")
            errorMessage = "Failed to submit donation request. Please try again."
        }
    }

    // MARK: - Private Methods

    private func setupCountdownTimer() {
        updateCountdown()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.updateCountdown()
            }
        }
    }

    private func updateCountdown() {
        // No longer using countdown - games are always available
    }
}
