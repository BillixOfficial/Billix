//
//  RewardsHubView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Main Rewards Hub - Arcade & Shop
//  Zones: A (Wallet Header), B (Game Hero), C (Marketplace), D (Leaderboard)
//

import SwiftUI

struct RewardsHubView: View {

    @StateObject private var viewModel = RewardsViewModel()
    @State private var appeared = false
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.billixLightGreen
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            VStack(spacing: 24) {

                                // ZONE B: Arcade Hero Card (Price Guessr)
                                ArcadeHeroCard(
                                    game: viewModel.dailyGame,
                                    result: viewModel.todaysResult,
                                    hasPlayedToday: viewModel.hasPlayedToday,
                                    timeRemaining: viewModel.timeUntilNextGame,
                                    onPlay: {
                                        viewModel.playDailyGame()
                                    }
                                )
                                .padding(.horizontal, 20)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)

                                // ZONE C: Rewards Marketplace
                                RewardMarketplace(
                                    rewards: viewModel.rewards,
                                    userPoints: viewModel.points.balance,
                                    onRewardTapped: { reward in
                                        viewModel.selectedReward = reward
                                        viewModel.showRedeemSheet = true
                                    },
                                    onViewAll: {
                                        viewModel.showAllRewards = true
                                    }
                                )
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: appeared)

                                // ZONE D: Leaderboard
                                LeaderboardSection(
                                    topSavers: viewModel.topSavers,
                                    currentUser: viewModel.currentUserRank
                                )
                                .padding(.horizontal, 20)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: appeared)

                                Spacer(minLength: 120)
                            }
                            .padding(.top, 16)
                        } header: {
                            // ZONE A: Wallet Header (Sticky)
                            WalletHeaderView(
                                points: viewModel.displayedBalance,
                                cashEquivalent: viewModel.points.cashEquivalent,
                                onHistoryTapped: {
                                    viewModel.showHistory = true
                                }
                            )
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await viewModel.loadRewardsData()
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .sheet(isPresented: $viewModel.showHistory) {
            PointsHistoryView(transactions: viewModel.points.transactions)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showAllRewards) {
            AllRewardsView(
                rewards: viewModel.rewards,
                userPoints: viewModel.points.balance,
                onRewardTapped: { reward in
                    viewModel.selectedReward = reward
                    viewModel.showRedeemSheet = true
                }
            )
        }
        .sheet(item: $viewModel.selectedReward) { reward in
            RewardRedeemSheet(
                reward: reward,
                userPoints: viewModel.points.balance,
                onRedeem: {
                    viewModel.redeemReward(reward)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - All Rewards View (Grid)

struct AllRewardsView: View {
    let rewards: [Reward]
    let userPoints: Int
    let onRewardTapped: (Reward) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(rewards) { reward in
                        RewardCard(
                            reward: reward,
                            userPoints: userPoints,
                            style: .grid,
                            onTap: { onRewardTapped(reward) }
                        )
                    }
                }
                .padding(20)
            }
            .background(Color.billixLightGreen)
            .navigationTitle("All Rewards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.billixMoneyGreen)
                }
            }
        }
    }
}

// MARK: - Reward Redeem Sheet

struct RewardRedeemSheet: View {
    let reward: Reward
    let userPoints: Int
    let onRedeem: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isRedeeming = false

    private var canAfford: Bool {
        userPoints >= reward.pointsCost
    }

    private var pointsNeeded: Int {
        max(reward.pointsCost - userPoints, 0)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Reward Icon
            ZStack {
                Circle()
                    .fill(Color(hex: reward.accentColor).opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: reward.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: reward.accentColor))
            }

            // Reward Info
            VStack(spacing: 8) {
                Text(reward.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Text(reward.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
                    .multilineTextAlignment(.center)

                if let value = reward.formattedValue {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.billixMoneyGreen)
                        .padding(.top, 4)
                }
            }

            // Cost
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.billixArcadeGold)

                Text("\(reward.pointsCost) pts")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.billixArcadeGold.opacity(0.15))
            )

            Spacer()

            // Action Button
            if canAfford {
                Button {
                    isRedeeming = true
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onRedeem()
                        dismiss()
                    }
                } label: {
                    HStack {
                        if isRedeeming {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Redeem Now")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.billixMoneyGreen, .billixMoneyGreen.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.97))
                .disabled(isRedeeming)
            } else {
                VStack(spacing: 8) {
                    Text("You need \(pointsNeeded) more pts")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Button {
                        dismiss()
                    } label: {
                        Text("Keep Playing")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.billixMoneyGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.billixMoneyGreen, lineWidth: 2)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle(scale: 0.97))
                }
            }
        }
        .padding(24)
        .background(Color.white)
    }
}

// MARK: - Preview

#Preview {
    RewardsHubView()
}
