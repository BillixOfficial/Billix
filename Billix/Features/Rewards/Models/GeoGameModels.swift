//
//  GeoGameModels.swift
//  Billix
//
//  Created by Claude Code
//  Additional game-specific models for geo-economic game
//  (LocationCoordinate, MapRegionData, DecoyLocation defined in RewardsModels.swift)
//

import Foundation

// MARK: - Game State

enum GamePhase: Equatable {
    case loading
    case phase1Location
    case transition
    case phase2Price
    case result
}

struct GameState {
    var phase: GamePhase = .loading
    var selectedLocation: String? = nil
    var isLocationCorrect: Bool = false
    var priceGuess: Double? = nil
    var phase1Points: Int = 0
    var phase2Points: Int = 0

    // Phase 1 retry support
    var isRetryAttempt: Bool = false
    var incorrectChoice: String? = nil

    var totalPoints: Int {
        phase1Points + phase2Points
    }
}

// MARK: - Scoring

struct GeoGameScoring {
    // Phase 1: Location identification
    static func calculatePhase1Points(correct: Bool, isRetry: Bool = false) -> Int {
        if !correct {
            return 0
        }
        // Reduced points if they needed a retry
        return isRetry ? 250 : 500
    }

    // Phase 2: Price accuracy
    static func calculatePhase2Points(guess: Double, actual: Double) -> Int {
        let percentOff = abs(guess - actual) / actual

        if percentOff <= 0.05 {
            return 1000  // Bullseye (within 5%)
        } else if percentOff <= 0.15 {
            return 500   // Close (within 15%)
        } else if percentOff <= 0.25 {
            return 100   // Safe (within 25%)
        } else {
            return 0     // Way off
        }
    }

    static func accuracyTier(guess: Double, actual: Double) -> String {
        let percentOff = abs(guess - actual) / actual

        if percentOff <= 0.05 {
            return "Bullseye! 🎯"
        } else if percentOff <= 0.15 {
            return "Close! 👍"
        } else if percentOff <= 0.25 {
            return "Safe 👌"
        } else {
            return "Way Off 😅"
        }
    }
}

// MARK: - Game Result

struct GeoGameResult {
    let pointsEarned: Int
    let locationCorrect: Bool
    let priceGuess: Double?
    let actualPrice: Double
    let accuracyTier: String?
}
