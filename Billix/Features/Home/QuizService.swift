//
//  QuizService.swift
//  Billix
//
//  Created by Claude Code
//  Service for managing daily quizzes
//

import Foundation
import Supabase

// MARK: - Models

struct Quiz: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let category: String?
    let activeDate: Date
    let difficulty: String?
    let estimatedTimeSeconds: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case activeDate = "active_date"
        case difficulty
        case estimatedTimeSeconds = "estimated_time_seconds"
        case createdAt = "created_at"
    }
}

struct QuizQuestion: Codable, Identifiable {
    let id: UUID
    let quizId: UUID
    let questionText: String
    let questionOrder: Int
    let optionA: String
    let optionB: String
    let optionC: String
    let optionD: String
    let correctAnswer: String
    let explanation: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case quizId = "quiz_id"
        case questionText = "question_text"
        case questionOrder = "question_order"
        case optionA = "option_a"
        case optionB = "option_b"
        case optionC = "option_c"
        case optionD = "option_d"
        case correctAnswer = "correct_answer"
        case explanation
        case createdAt = "created_at"
    }

    var options: [String] {
        [optionA, optionB, optionC, optionD]
    }
}

struct QuizAttempt: Codable, Identifiable {
    let id: UUID
    let quizId: UUID
    let userId: UUID
    let score: Int
    let totalQuestions: Int
    let isCompleted: Bool
    let answers: [String: String]? // JSON dict of questionId: selectedOption
    let completedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case quizId = "quiz_id"
        case userId = "user_id"
        case score
        case totalQuestions = "total_questions"
        case isCompleted = "is_completed"
        case answers
        case completedAt = "completed_at"
        case createdAt = "created_at"
    }

    var percentage: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(score) / Double(totalQuestions) * 100.0
    }
}

struct QuizWithQuestions {
    let quiz: Quiz
    let questions: [QuizQuestion]
    let attempt: QuizAttempt?

    var isCompleted: Bool {
        attempt?.isCompleted ?? false
    }
}

struct QuizSubmission {
    let quizId: UUID
    let answers: [UUID: String] // questionId: selectedOption ('a', 'b', 'c', or 'd')
}

// MARK: - Protocol

protocol QuizServiceProtocol {
    func getTodaysQuiz() async throws -> Quiz?
    func getQuizWithQuestions() async throws -> QuizWithQuestions?
    func getQuestions(quizId: UUID) async throws -> [QuizQuestion]
    func hasUserCompletedQuiz(quizId: UUID) async throws -> Bool
    func getUserAttempt(quizId: UUID) async throws -> QuizAttempt?
    func submitQuizAnswers(_ submission: QuizSubmission) async throws -> QuizAttempt
}

// MARK: - Service Implementation

@MainActor
class QuizService: QuizServiceProtocol {

    // MARK: - Singleton
    static let shared = QuizService()

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // Cache for today's quiz to reduce DB calls
    private var cachedQuizWithQuestions: QuizWithQuestions?
    private var cacheDate: Date?

    // MARK: - Initialization
    private init() {}

    // MARK: - Public Methods

    /// Get today's quiz
    func getTodaysQuiz() async throws -> Quiz? {
        // Check cache first (valid for same calendar day)
        if let cached = cachedQuizWithQuestions,
           let cacheDate = cacheDate,
           Calendar.current.isDateInToday(cacheDate) {
            return cached.quiz
        }

        // Query for today's quiz
        let todayString = ISO8601DateFormatter().string(from: Date()).prefix(10)

        let response: [Quiz] = try await supabase
            .from("quizzes")
            .select()
            .eq("active_date", value: String(todayString))
            .limit(1)
            .execute()
            .value

        return response.first
    }

    /// Get today's quiz along with its questions and user's attempt (if any)
    func getQuizWithQuestions() async throws -> QuizWithQuestions? {
        // Check cache first
        if let cached = cachedQuizWithQuestions,
           let cacheDate = cacheDate,
           Calendar.current.isDateInToday(cacheDate) {
            return cached
        }

        guard let quiz = try await getTodaysQuiz() else {
            return nil
        }

        let questions = try await getQuestions(quizId: quiz.id)
        let attempt = try await getUserAttempt(quizId: quiz.id)

        let quizWithQuestions = QuizWithQuestions(
            quiz: quiz,
            questions: questions,
            attempt: attempt
        )

        // Cache the result
        cachedQuizWithQuestions = quizWithQuestions
        cacheDate = Date()

        return quizWithQuestions
    }

    /// Get all questions for a specific quiz
    func getQuestions(quizId: UUID) async throws -> [QuizQuestion] {
        let response: [QuizQuestion] = try await supabase
            .from("quiz_questions")
            .select()
            .eq("quiz_id", value: quizId.uuidString)
            .order("question_order")
            .execute()
            .value

        return response
    }

    /// Check if the current user has completed a specific quiz
    func hasUserCompletedQuiz(quizId: UUID) async throws -> Bool {
        guard let attempt = try await getUserAttempt(quizId: quizId) else {
            return false
        }
        return attempt.isCompleted
    }

    /// Get the user's attempt for a specific quiz
    func getUserAttempt(quizId: UUID) async throws -> QuizAttempt? {
        guard let session = try? await supabase.auth.session else {
            return nil // Not authenticated means no attempt
        }

        let response: [QuizAttempt] = try await supabase
            .from("quiz_attempts")
            .select()
            .eq("quiz_id", value: quizId.uuidString)
            .eq("user_id", value: session.user.id.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    /// Submit quiz answers and calculate score
    func submitQuizAnswers(_ submission: QuizSubmission) async throws -> QuizAttempt {
        guard let session = try? await supabase.auth.session else {
            throw QuizError.notAuthenticated
        }

        // Check if user already completed this quiz
        let existingAttempt = try await getUserAttempt(quizId: submission.quizId)
        if existingAttempt?.isCompleted == true {
            throw QuizError.alreadyCompleted
        }

        // Fetch questions to calculate score
        let questions = try await getQuestions(quizId: submission.quizId)

        guard !questions.isEmpty else {
            throw QuizError.quizNotFound
        }

        // Calculate score by comparing answers
        var correctCount = 0
        for question in questions {
            if let userAnswer = submission.answers[question.id],
               userAnswer == question.correctAnswer {
                correctCount += 1
            }
        }

        // Convert answers dict to JSON
        let answersJSON = submission.answers.reduce(into: [String: String]()) { result, pair in
            result[pair.key.uuidString] = pair.value
        }

        // Create attempt record
        struct QuizAttemptInsert: Encodable {
            let quiz_id: String
            let user_id: String
            let score: Int
            let total_questions: Int
            let is_completed: Bool
            let answers: [String: String]
            let completed_at: String
        }

        let attemptData = QuizAttemptInsert(
            quiz_id: submission.quizId.uuidString,
            user_id: session.user.id.uuidString,
            score: correctCount,
            total_questions: questions.count,
            is_completed: true,
            answers: answersJSON,
            completed_at: ISO8601DateFormatter().string(from: Date())
        )

        // Use upsert to handle duplicate attempts
        let response: QuizAttempt = try await supabase
            .from("quiz_attempts")
            .upsert(attemptData)
            .select()
            .single()
            .execute()
            .value

        // Clear cache to force refresh
        clearCache()

        return response
    }

    // MARK: - Helper Methods

    /// Get formatted score for display (e.g., "2/3" or "67%")
    func formattedScore(score: Int, total: Int) -> String {
        return "\(score)/\(total)"
    }

    /// Get formatted percentage for display
    func formattedPercentage(_ percentage: Double) -> String {
        return String(format: "%.0f%%", percentage)
    }

    /// Get emoji based on quiz performance
    func performanceEmoji(percentage: Double) -> String {
        switch percentage {
        case 100:
            return "🏆" // Perfect score
        case 67..<100:
            return "🎉" // Good score
        case 34..<67:
            return "👍" // Passing score
        default:
            return "📚" // Keep learning
        }
    }

    /// Clear the cache (useful for testing or force refresh)
    func clearCache() {
        cachedQuizWithQuestions = nil
        cacheDate = nil
    }
}

// MARK: - Errors

enum QuizError: LocalizedError {
    case notAuthenticated
    case quizNotFound
    case alreadyCompleted
    case submitFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to take quizzes"
        case .quizNotFound:
            return "Quiz not found"
        case .alreadyCompleted:
            return "You've already completed this quiz"
        case .submitFailed(let message):
            return "Failed to submit quiz: \(message)"
        }
    }
}
