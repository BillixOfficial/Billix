//
//  RewardsViewModel.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  ViewModel for Rewards Hub - manages points, games, marketplace, leaderboard
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RewardsViewModel: ObservableObject {

    // MARK: - Points & Wallet

    @Published var points: RewardsPoints = .preview
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
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupCountdownTimer()
    }

    deinit {
        countdownTimer?.invalidate()
    }

    // MARK: - Public Methods

    func loadRewardsData() async {
        isLoading = true

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        // In real implementation, fetch from API
        // For now, using preview/mock data
        points = .preview

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
        let transaction = PointTransaction(
            id: UUID(),
            type: type,
            amount: amount,
            description: description,
            createdAt: Date()
        )

        points.balance += amount
        points.lifetimeEarned += amount
        points.transactions.insert(transaction, at: 0)

        // Animate the balance change
        animateBalanceChange(to: points.balance)
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

        let transaction = PointTransaction(
            id: UUID(),
            type: .redemption,
            amount: -reward.pointsCost,
            description: "Redeemed \(reward.title)",
            createdAt: Date()
        )

        points.balance -= reward.pointsCost
        points.transactions.insert(transaction, at: 0)

        animateBalanceChange(to: points.balance)
        showRedeemSheet = false
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

        // Add points if earned
        if result.pointsEarned > 0 {
            addPoints(
                result.pointsEarned,
                description: "Geo Game #\(gamesPlayedToday)",
                type: .gameWin
            )
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
