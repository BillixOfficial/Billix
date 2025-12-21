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
    // MARK: Legacy scoring (for backward compatibility)

    // Phase 1: Location identification (legacy)
    static func calculatePhase1Points(correct: Bool, isRetry: Bool = false) -> Int {
        if !correct {
            return 0
        }
        // Reduced points if they needed a retry
        return isRetry ? 250 : 500
    }

    // Phase 2: Price accuracy (legacy)
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
            return "Bullseye!"
        } else if percentOff <= 0.15 {
            return "Close!"
        } else if percentOff <= 0.25 {
            return "Safe"
        } else {
            return "Way Off"
        }
    }

    // MARK: Enhanced scoring with difficulty and combo

    /// Calculate combo multiplier based on streak
    static func calculateComboMultiplier(_ streak: Int) -> Double {
        switch streak {
        case 0...1: return 1.0
        case 2...3: return 1.25  // 25% bonus
        case 4...5: return 1.5   // 50% bonus
        default: return 2.0      // 100% bonus (6+)
        }
    }

    /// Calculate final multiplier with 2.0x CAP to prevent exponential growth
    /// CRITICAL for $8/month economy - prevents 4.0x stacking
    static func calculateFinalMultiplier(combo: Int, difficulty: QuestionDifficulty) -> Double {
        let comboMult = calculateComboMultiplier(combo)
        let diffMult: Double
        switch difficulty {
        case .easy: diffMult = 1.0
        case .moderate: diffMult = 1.5
        case .hard: diffMult = 2.0
        }

        // CAP AT 2.0x - critical for economy
        let combined = comboMult * diffMult
        return min(combined, 2.0)
    }

    /// Phase 1 scoring with difficulty and combo multipliers (CAPPED AT 2.0x)
    static func calculatePhase1Points(
        correct: Bool,
        isRetry: Bool,
        difficulty: QuestionDifficulty,
        comboStreak: Int
    ) -> Int {
        guard correct else { return 0 }

        // SIMPLIFIED: All correct answers = 25 pts (no difficulty tiers for base)
        let basePoints: Int = 25

        let retryPenalty = isRetry ? 0.5 : 1.0
        let finalMultiplier = calculateFinalMultiplier(combo: comboStreak, difficulty: difficulty)

        return Int(Double(basePoints) * retryPenalty * finalMultiplier)
    }

    /// Phase 2 scoring with difficulty and combo multipliers (CAPPED AT 2.0x)
    static func calculatePhase2Points(
        guess: Double,
        actual: Double,
        difficulty: QuestionDifficulty,
        comboStreak: Int
    ) -> Int {
        let percentOff = abs(guess - actual) / actual

        let basePoints: Int
        if percentOff <= 0.05 {
            basePoints = 50  // Bullseye (reduced from 500)
        } else if percentOff <= 0.15 {
            basePoints = 25  // Close (reduced from 300)
        } else if percentOff <= 0.25 {
            basePoints = 10  // Safe (reduced from 150)
        } else {
            basePoints = 0   // Way off
        }

        let finalMultiplier = calculateFinalMultiplier(combo: comboStreak, difficulty: difficulty)

        return Int(Double(basePoints) * finalMultiplier)
    }

    /// Determine if health should be lost
    static func shouldLoseHealth(
        phase1Correct: Bool,
        phase1Attempts: Int,
        phase2Accuracy: Double
    ) -> Bool {
        // Lose health if:
        // 1. Location wrong after 2 attempts, OR
        // 2. Price accuracy < 75% (more than 25% off)

        if !phase1Correct && phase1Attempts >= 2 {
            return true
        }

        if phase2Accuracy < 0.75 {
            return true
        }

        return false
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

// MARK: - Multi-Question Game Session

/// Difficulty level for questions
enum QuestionDifficulty: String, Codable {
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
}

/// Individual question combining location and price phases
struct GameQuestion: Identifiable, Codable, Equatable {
    let id: UUID
    let subject: String          // "Gallon of Milk", "1-Bedroom Apartment"
    let location: String         // "Austin, TX"
    let category: GameCategory
    let difficulty: QuestionDifficulty

    // Phase 1: Location identification
    let coordinates: LocationCoordinate
    let mapRegion: MapRegionData
    let landmarkCoordinate: LocationCoordinate
    let decoyLocations: [DecoyLocation]

    // Phase 2: Price estimation
    let actualPrice: Double
    let minGuess: Double
    let maxGuess: Double
    let unit: String             // "gallon", "month"
    let economicContext: String?

    var basePoints: Int {
        switch difficulty {
        case .easy: return 100
        case .moderate: return 200
        case .hard: return 300
        }
    }

    init(id: UUID = UUID(),
         subject: String,
         location: String,
         category: GameCategory,
         difficulty: QuestionDifficulty,
         coordinates: LocationCoordinate,
         mapRegion: MapRegionData,
         landmarkCoordinate: LocationCoordinate,
         decoyLocations: [DecoyLocation],
         actualPrice: Double,
         minGuess: Double,
         maxGuess: Double,
         unit: String,
         economicContext: String? = nil) {
        self.id = id
        self.subject = subject
        self.location = location
        self.category = category
        self.difficulty = difficulty
        self.coordinates = coordinates
        self.mapRegion = mapRegion
        self.landmarkCoordinate = landmarkCoordinate
        self.decoyLocations = decoyLocations
        self.actualPrice = actualPrice
        self.minGuess = minGuess
        self.maxGuess = maxGuess
        self.unit = unit
        self.economicContext = economicContext
    }
}

/// Game session containing multiple questions
struct GameSession: Identifiable {
    let id: UUID
    let questions: [GameQuestion]
    var currentQuestionIndex: Int = 0
    var health: Int = 3              // Hearts/lives
    var totalPoints: Int = 0
    var questionsCorrect: Int = 0    // Total correct (deprecated, use landmarksCorrect + pricesCorrect)
    var comboStreak: Int = 0         // Consecutive correct answers
    let startedAt: Date

    // New: Separate tracking for landmarks vs prices
    var landmarksCorrect: Int = 0    // 0-4
    var landmarksAttempted: Int = 0  // 0-4
    var pricesCorrect: Int = 0       // 0-8 (2 per landmark if all attempted)
    var pricesAttempted: Int = 0     // 0-8

    // Power-ups inventory
    var powerUps: PowerUpInventory = PowerUpInventory()

    var isGameOver: Bool {
        health <= 0 || currentQuestionIndex >= questions.count
    }

    var currentQuestion: GameQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }

    var hasWon: Bool {
        // Win = finished all questions with health remaining
        currentQuestionIndex >= questions.count && health > 0
    }

    var hasLost: Bool {
        // Loss = ran out of health
        health <= 0
    }

    var currentLandmarkIndex: Int {
        // Each landmark has 3 questions (1 location + 2 prices)
        currentQuestionIndex / 3
    }

    init(id: UUID = UUID(),
         questions: [GameQuestion],
         currentQuestionIndex: Int = 0,
         health: Int = 3,
         totalPoints: Int = 0,
         questionsCorrect: Int = 0,
         comboStreak: Int = 0,
         startedAt: Date = Date(),
         landmarksCorrect: Int = 0,
         landmarksAttempted: Int = 0,
         pricesCorrect: Int = 0,
         pricesAttempted: Int = 0,
         powerUps: PowerUpInventory = PowerUpInventory()) {
        self.id = id
        self.questions = questions
        self.currentQuestionIndex = currentQuestionIndex
        self.health = health
        self.totalPoints = totalPoints
        self.questionsCorrect = questionsCorrect
        self.comboStreak = comboStreak
        self.startedAt = startedAt
        self.landmarksCorrect = landmarksCorrect
        self.landmarksAttempted = landmarksAttempted
        self.pricesCorrect = pricesCorrect
        self.pricesAttempted = pricesAttempted
        self.powerUps = powerUps
    }
}

/// Enhanced game phase for question-based flow
enum QuestionPhase: Equatable {
    case loading
    case phase1Location      // Identify location
    case phase1Feedback      // Show correct/wrong feedback
    case phase2Price         // Estimate price
    case phase2Feedback      // Show price accuracy
    case questionComplete    // Brief summary before next
    case gameOver            // Final results
}

/// Result tracking for individual questions
struct QuestionResult {
    let questionId: UUID
    let phase1Correct: Bool
    let phase1Attempts: Int      // 1 or 2
    let phase1Points: Int
    let phase2Guess: Double
    let phase2Accuracy: Double   // 0.0 to 1.0
    let phase2Points: Int
    let comboMultiplier: Double  // 1.0, 1.25, 1.5, 2.0
    let totalPoints: Int
    let healthLost: Int          // 0 or 1
}

/// Heart/life state for UI rendering
enum HeartState {
    case full
    case empty
}

// MARK: - Power-Ups System

/// Available power-up types for Price Guessr game
enum PowerUpType: String, Codable, CaseIterable {
    case extraLife = "Extra Life"
    case skipQuestion = "Skip Question"
    case timeFreeze = "Time Freeze"
    case hintToken = "Hint Token"

    var iconName: String {
        switch self {
        case .extraLife: return "heart.fill"
        case .skipQuestion: return "forward.fill"
        case .timeFreeze: return "clock.fill"
        case .hintToken: return "lightbulb.fill"
        }
    }

    var color: String {
        switch self {
        case .extraLife: return "#FF6B6B"
        case .skipQuestion: return "#95E1D3"
        case .timeFreeze: return "#F38181"
        case .hintToken: return "#FFD93D"
        }
    }

    var description: String {
        switch self {
        case .extraLife: return "Add +1 heart"
        case .skipQuestion: return "Skip this question"
        case .timeFreeze: return "+15 seconds"
        case .hintToken: return "Reveal wrong answer"
        }
    }
}

/// Power-up inventory for a game session
struct PowerUpInventory: Codable, Equatable {
    var extraLife: Int = 0
    var skipQuestion: Int = 0
    var timeFreeze: Int = 0
    var hintToken: Int = 0

    mutating func add(_ type: PowerUpType, count: Int = 1) {
        switch type {
        case .extraLife: extraLife += count
        case .skipQuestion: skipQuestion += count
        case .timeFreeze: timeFreeze += count
        case .hintToken: hintToken += count
        }
    }

    mutating func use(_ type: PowerUpType) -> Bool {
        switch type {
        case .extraLife:
            guard extraLife > 0 else { return false }
            extraLife -= 1
            return true
        case .skipQuestion:
            guard skipQuestion > 0 else { return false }
            skipQuestion -= 1
            return true
        case .timeFreeze:
            guard timeFreeze > 0 else { return false }
            timeFreeze -= 1
            return true
        case .hintToken:
            guard hintToken > 0 else { return false }
            hintToken -= 1
            return true
        }
    }

    func count(for type: PowerUpType) -> Int {
        switch type {
        case .extraLife: return extraLife
        case .skipQuestion: return skipQuestion
        case .timeFreeze: return timeFreeze
        case .hintToken: return hintToken
        }
    }

    func hasAny(_ type: PowerUpType) -> Bool {
        count(for: type) > 0
    }
}
