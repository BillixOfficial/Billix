//
//  RewardsModels.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Models for the Rewards Hub - Points, Marketplace, Games, Leaderboard
//

import Foundation
import SwiftUI

// MARK: - Rewards Points (Separate from BillixCredits)

struct RewardsPoints: Codable, Equatable {
    var balance: Int
    var lifetimeEarned: Int
    var transactions: [PointTransaction]

    var cashEquivalent: Double {
        Double(balance) / 100.0 // 100 points = $1
    }

    var recentTransactions: [PointTransaction] {
        Array(transactions.prefix(10))
    }
}

struct PointTransaction: Identifiable, Codable, Equatable {
    let id: UUID
    let type: PointTransactionType
    let amount: Int
    let description: String
    let createdAt: Date

    var amountString: String {
        let sign = amount >= 0 ? "+" : ""
        return "\(sign)\(amount)"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: createdAt)
    }
}

enum PointTransactionType: String, Codable {
    case gameWin = "Game Win"
    case dailyBonus = "Daily Bonus"
    case redemption = "Redemption"
    case referral = "Referral"
    case achievement = "Achievement"
}

// MARK: - Marketplace Rewards

struct Reward: Identifiable, Codable, Equatable {
    let id: UUID
    let type: RewardType
    let title: String
    let description: String
    let pointsCost: Int
    let brand: String?
    let dollarValue: Double?
    let iconName: String
    let accentColor: String // Hex color for brand theming

    var formattedCost: String {
        "\(pointsCost) pts"
    }

    var formattedValue: String? {
        guard let value = dollarValue else { return nil }
        return String(format: "$%.0f", value)
    }
}

enum RewardType: String, Codable, CaseIterable {
    case billCredit = "Bill Credit"
    case giftCard = "Gift Card"
    case digitalGood = "Digital Good"

    var icon: String {
        switch self {
        case .billCredit: return "dollarsign.circle.fill"
        case .giftCard: return "giftcard.fill"
        case .digitalGood: return "sparkles"
        }
    }
}

// MARK: - Daily Game (Price Guessr)

struct DailyGame: Identifiable, Codable, Equatable {
    let id: UUID
    let subject: String          // "Milk" or "1-Bedroom Apartment"
    let location: String         // "Manhattan, NY"
    let locationCode: String     // "10001"
    let category: GameCategory
    let actualPrice: Double
    let minGuess: Double
    let maxGuess: Double
    let unit: String             // "gallon", "month", etc.
    let expiresAt: Date

    var formattedSubject: String {
        "\(subject) in \(location)"
    }

    var priceRange: ClosedRange<Double> {
        minGuess...maxGuess
    }
}

enum GameCategory: String, Codable, CaseIterable {
    case grocery = "Grocery"
    case rent = "Rent"
    case utility = "Utility"
    case subscription = "Subscription"
    case gas = "Gas"

    var icon: String {
        switch self {
        case .grocery: return "cart.fill"
        case .rent: return "house.fill"
        case .utility: return "bolt.fill"
        case .subscription: return "tv.fill"
        case .gas: return "fuelpump.fill"
        }
    }

    var color: Color {
        switch self {
        case .grocery: return .green
        case .rent: return .blue
        case .utility: return .orange
        case .subscription: return .purple
        case .gas: return .red
        }
    }
}

struct GameResult: Identifiable, Codable, Equatable {
    let id: UUID
    let gameId: UUID
    let userGuess: Double
    let actualPrice: Double
    let pointsEarned: Int
    let accuracy: Double         // 0.0 to 1.0 (1.0 = perfect)
    let playedAt: Date

    var accuracyPercentage: Int {
        Int(accuracy * 100)
    }

    var resultType: GameResultType {
        if accuracy >= 0.95 { return .perfect }
        else if accuracy >= 0.85 { return .close }
        else { return .miss }
    }

    var formattedGuess: String {
        String(format: "$%.2f", userGuess)
    }

    var formattedActual: String {
        String(format: "$%.2f", actualPrice)
    }
}

enum GameResultType {
    case perfect  // Within 5%
    case close    // Within 15%
    case miss     // More than 15% off

    var title: String {
        switch self {
        case .perfect: return "Amazing!"
        case .close: return "So close!"
        case .miss: return "Good try!"
        }
    }

    var color: Color {
        switch self {
        case .perfect: return .billixArcadeGold
        case .close: return .billixMoneyGreen
        case .miss: return .billixMediumGreen
        }
    }
}

// MARK: - Leaderboard

struct LeaderboardEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let rank: Int
    let displayName: String
    let avatarInitials: String
    let pointsThisWeek: Int
    let isCurrentUser: Bool

    var formattedPoints: String {
        "\(pointsThisWeek) pts"
    }

    var rankBadgeColor: Color {
        switch rank {
        case 1: return .billixLeaderGold
        case 2: return .billixLeaderSilver
        case 3: return .billixLeaderBronze
        default: return .billixMediumGreen
        }
    }
}

// MARK: - Preview Data

extension RewardsPoints {
    static let preview = RewardsPoints(
        balance: 1450,
        lifetimeEarned: 3200,
        transactions: [
            PointTransaction(
                id: UUID(),
                type: .gameWin,
                amount: 100,
                description: "Daily Price Guessr - Perfect!",
                createdAt: Date()
            ),
            PointTransaction(
                id: UUID(),
                type: .dailyBonus,
                amount: 25,
                description: "Daily login bonus",
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            PointTransaction(
                id: UUID(),
                type: .redemption,
                amount: -500,
                description: "Redeemed $5 Amazon Gift Card",
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            PointTransaction(
                id: UUID(),
                type: .gameWin,
                amount: 50,
                description: "Daily Price Guessr - Close!",
                createdAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date()
            ),
            PointTransaction(
                id: UUID(),
                type: .referral,
                amount: 200,
                description: "Friend joined and played",
                createdAt: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            )
        ]
    )
}

extension Reward {
    static let previewRewards: [Reward] = [
        Reward(
            id: UUID(),
            type: .billCredit,
            title: "$5 Bill Credit",
            description: "$5 off your next Billix Bill Pay",
            pointsCost: 500,
            brand: "Billix",
            dollarValue: 5,
            iconName: "dollarsign.circle.fill",
            accentColor: "#5b8a6b"
        ),
        Reward(
            id: UUID(),
            type: .giftCard,
            title: "Amazon Gift Card",
            description: "Redeemable on Amazon.com",
            pointsCost: 500,
            brand: "Amazon",
            dollarValue: 5,
            iconName: "gift.fill",
            accentColor: "#FF9900"
        ),
        Reward(
            id: UUID(),
            type: .giftCard,
            title: "Starbucks Gift Card",
            description: "Use at any Starbucks location",
            pointsCost: 500,
            brand: "Starbucks",
            dollarValue: 5,
            iconName: "cup.and.saucer.fill",
            accentColor: "#00704A"
        ),
        Reward(
            id: UUID(),
            type: .giftCard,
            title: "Target Gift Card",
            description: "Shop at Target stores or online",
            pointsCost: 1000,
            brand: "Target",
            dollarValue: 10,
            iconName: "target",
            accentColor: "#CC0000"
        ),
        Reward(
            id: UUID(),
            type: .digitalGood,
            title: "Premium Market Data",
            description: "Unlock 30 days of premium insights",
            pointsCost: 750,
            brand: nil,
            dollarValue: nil,
            iconName: "chart.line.uptrend.xyaxis",
            accentColor: "#52b8df"
        )
    ]
}

extension DailyGame {
    static let preview = DailyGame(
        id: UUID(),
        subject: "Milk",
        location: "Manhattan, NY",
        locationCode: "10001",
        category: .grocery,
        actualPrice: 4.89,
        minGuess: 2.00,
        maxGuess: 8.00,
        unit: "gallon",
        expiresAt: Calendar.current.date(byAdding: .hour, value: 14, to: Date()) ?? Date()
    )
}

extension GameResult {
    static let preview = GameResult(
        id: UUID(),
        gameId: UUID(),
        userGuess: 4.75,
        actualPrice: 4.89,
        pointsEarned: 80,
        accuracy: 0.97,
        playedAt: Date()
    )
}

extension LeaderboardEntry {
    static let previewEntries: [LeaderboardEntry] = [
        LeaderboardEntry(
            id: UUID(),
            rank: 1,
            displayName: "Sarah M.",
            avatarInitials: "SM",
            pointsThisWeek: 850,
            isCurrentUser: false
        ),
        LeaderboardEntry(
            id: UUID(),
            rank: 2,
            displayName: "Mike T.",
            avatarInitials: "MT",
            pointsThisWeek: 720,
            isCurrentUser: false
        ),
        LeaderboardEntry(
            id: UUID(),
            rank: 3,
            displayName: "Jessica L.",
            avatarInitials: "JL",
            pointsThisWeek: 680,
            isCurrentUser: false
        )
    ]

    static let currentUserEntry = LeaderboardEntry(
        id: UUID(),
        rank: 42,
        displayName: "You",
        avatarInitials: "DK",
        pointsThisWeek: 150,
        isCurrentUser: true
    )
}
