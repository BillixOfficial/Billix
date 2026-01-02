//
//  RewardsViewModel.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  ViewModel for Rewards Hub - manages points, games, marketplace, leaderboard
//

import Foundation
import SwiftUI

@MainActor
class RewardsViewModel: ObservableObject {

    // MARK: - Services

    private let rewardsService: RewardsService
    private let authService: AuthService

    // MARK: - Points & Wallet

    @Published var points: RewardsPoints
    @Published var displayedBalance: Int = 0 // For animated counting

    // Shop unlock logic - Always accessible
    var canAccessRewardShop: Bool {
        true  // Shop is always accessible
    }

    // MARK: - Tier System

    // Current tier based on points balance
    var currentTier: RewardsTier {
        RewardsTier.allCases.last { tier in
            points.balance >= tier.pointsRange.lowerBound
        } ?? .bronze
    }

    // Progress to next tier (0.0 to 1.0)
    var tierProgress: Double {
        guard let nextTier = currentTier.nextTier else { return 1.0 }

        let currentMin = Double(currentTier.pointsRange.lowerBound)
        let nextMin = Double(nextTier.pointsRange.lowerBound)
        let current = Double(points.balance)

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

    // MARK: - Daily Game Cap Tracking

    @Published var dailyGameCap: DailyGameCap = DailyGameCap(
        date: Date(),
        pointsEarnedToday: 0,
        sessionsPlayedToday: 0
    )

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
            Task { @MainActor in
                print("🔄 Refreshing rewards data...")
                await self?.loadRewardsData()
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

            // Fetch user points from Supabase
            let userPointsDTO = try await rewardsService.getUserPoints(userId: userId)

            // Fetch recent transactions
            let transactionsDTO = try await rewardsService.getTransactions(userId: userId, limit: 50)

            // Convert DTOs to domain models
            points = RewardsPoints(
                balance: userPointsDTO.balance,
                lifetimeEarned: userPointsDTO.lifetimeEarned,
                transactions: transactionsDTO.map { dto in
                    PointTransaction(
                        id: dto.id,
                        type: PointTransactionType(rawValue: dto.type) ?? .achievement,
                        amount: dto.amount,
                        description: dto.description,
                        createdAt: dto.createdAt
                    )
                }
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

    func addPoints(_ amount: Int, description: String, type: PointTransactionType = .gameWin, source: String = "game") {
        Task {
            do {
                guard let userId = authService.currentUser?.id else {
                    print("⚠️ No authenticated user - cannot add points")
                    return
                }

                // Add points via Supabase service (atomic transaction)
                let transactionDTO = try await rewardsService.addPoints(
                    userId: userId,
                    amount: amount,
                    type: type.rawValue,
                    description: description,
                    source: source
                )

                // Update local state with server response
                let transaction = PointTransaction(
                    id: transactionDTO.id,
                    type: type,
                    amount: transactionDTO.amount,
                    description: transactionDTO.description,
                    createdAt: transactionDTO.createdAt
                )

                // Fetch updated balance from server
                let userPointsDTO = try await rewardsService.getUserPoints(userId: userId)

                await MainActor.run {
                    points.balance = userPointsDTO.balance
                    points.lifetimeEarned = userPointsDTO.lifetimeEarned
                    points.transactions.insert(transaction, at: 0)

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
                guard let userId = authService.currentUser?.id else {
                    print("⚠️ No authenticated user - cannot redeem reward")
                    return
                }

                // Deduct points via Supabase service (negative amount)
                let transactionDTO = try await rewardsService.addPoints(
                    userId: userId,
                    amount: -reward.pointsCost,
                    type: PointTransactionType.redemption.rawValue,
                    description: "Redeemed \(reward.title)",
                    source: "redemption"
                )

                // Update local state with server response
                let transaction = PointTransaction(
                    id: transactionDTO.id,
                    type: .redemption,
                    amount: transactionDTO.amount,
                    description: transactionDTO.description,
                    createdAt: transactionDTO.createdAt
                )

                // Fetch updated balance from server
                let userPointsDTO = try await rewardsService.getUserPoints(userId: userId)

                await MainActor.run {
                    points.balance = userPointsDTO.balance
                    points.transactions.insert(transaction, at: 0)

                    animateBalanceChange(to: points.balance)
                    showRedeemSheet = false
                }

            } catch {
                print("❌ Failed to redeem reward: \(error)")
            }
        }
    }

    func redeemGiftCard(_ reward: Reward, email: String) {
        guard canAffordReward(reward) else { return }

        let transaction = PointTransaction(
            id: UUID(),
            type: .redemption,
            amount: -reward.pointsCost,
            description: "Redeemed \(reward.title) - Sent to \(email)",
            createdAt: Date()
        )

        points.balance -= reward.pointsCost
        points.transactions.insert(transaction, at: 0)

        animateBalanceChange(to: points.balance)

        // In a real app, this would call an API to send the gift card to the email
        print("Gift card \(reward.title) will be sent to \(email)")
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

        // Reset cap if new day
        if !Calendar.current.isDate(dailyGameCap.date, inSameDayAs: Date()) {
            dailyGameCap = DailyGameCap(
                date: Date(),
                pointsEarnedToday: 0,
                sessionsPlayedToday: 0
            )
        }

        // Add points if earned, with daily cap enforcement
        if result.pointsEarned > 0 {
            let cappedPoints = min(result.pointsEarned, dailyGameCap.remainingPoints)

            if cappedPoints > 0 {
                dailyGameCap.pointsEarnedToday += cappedPoints
                dailyGameCap.sessionsPlayedToday += 1

                addPoints(
                    cappedPoints,
                    description: "Price Guessr Session #\(dailyGameCap.sessionsPlayedToday)",
                    type: .gameWin
                )
            }
        }
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
        amount: DonationAmount,
        donateInMyName: Bool,
        donorName: String?,
        donorEmail: String?
    ) {
        guard points.balance >= amount.pointsCost else { return }

        // Create donation request
        let request = DonationRequest(
            id: UUID(),
            organizationName: organizationName,
            websiteOrLocation: websiteOrLocation,
            amount: amount,
            donateInMyName: donateInMyName,
            donorName: donorName,
            donorEmail: donorEmail,
            pointsUsed: amount.pointsCost,
            status: .pending,
            createdAt: Date(),
            processedAt: nil
        )

        // Deduct points
        let transaction = PointTransaction(
            id: UUID(),
            type: .redemption,
            amount: -amount.pointsCost,
            description: "Donation Request: \(organizationName) (\(amount.displayText))",
            createdAt: Date()
        )

        points.balance -= amount.pointsCost
        points.transactions.insert(transaction, at: 0)
        donationRequests.insert(request, at: 0)

        animateBalanceChange(to: points.balance)

        // In a real app, this would call an API to submit the request for verification
        print("Donation request submitted: \(organizationName), Amount: \(amount.displayText), Location: \(websiteOrLocation)")

        showDonationRequestSheet = false
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
