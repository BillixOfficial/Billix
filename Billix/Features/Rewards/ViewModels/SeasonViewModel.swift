//
//  SeasonViewModel.swift
//  Billix
//
//  Created by Claude Code
//  ViewModel for managing season/part/location selection flow
//

import Foundation
import Supabase

@MainActor
class SeasonViewModel: ObservableObject {

    // MARK: - Published Properties

    // Season selection
    @Published var seasons: [Season] = []
    @Published var selectedSeason: Season?

    // Part selection
    @Published var seasonParts: [SeasonPart] = []
    @Published var selectedPart: SeasonPart?

    // Location selection
    @Published var locations: [SeasonLocation] = []
    @Published var selectedLocation: SeasonLocation?

    // Progress tracking
    @Published var userProgress: [UUID: UserSeasonProgress] = [:]
    @Published var partCompletionCounts: [UUID: Int] = [:]

    // UI state
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Session-based gameplay
    @Published var currentGameSession: GameSession?
    @Published var showTutorial = false
    var activePartId: UUID?
    var pendingSessionPart: SeasonPart?

    // MARK: - Private Properties

    private let service = SeasonDataService.shared
    private var currentUserId: UUID?

    // MARK: - Initialization

    init() {
        Task {
            await getCurrentUser()
            await loadSeasons()
        }
    }

    // MARK: - User Management

    private func getCurrentUser() async {
        do {
            let session = try await SupabaseService.shared.client.auth.session
            currentUserId = session.user.id
        } catch {
            print("⚠️ No authenticated user found")
            errorMessage = "Please log in to continue"
        }
    }

    // MARK: - Season Management

    /// Load all available seasons
    func loadSeasons() async {
        isLoading = true
        errorMessage = nil

        do {
            seasons = try await service.fetchSeasons()
            // Don't auto-select - let user choose
        } catch {
            errorMessage = "Failed to load seasons: \(error.localizedDescription)"
            print("❌ Error loading seasons: \(error)")
        }

        isLoading = false
    }

    /// Select a season and load its parts
    func selectSeason(_ season: Season) async {
        guard season.isReleased else {
            errorMessage = "This season is not yet available"
            return
        }

        selectedSeason = season
        isLoading = true
        errorMessage = nil

        do {
            // Load parts for this season
            seasonParts = try await service.fetchSeasonParts(seasonId: season.id)

            // Load user progress for this season (non-blocking - failures won't prevent UI from loading)
            if let userId = currentUserId {
                do {
                    let progressArray = try await service.fetchUserProgress(userId: userId, seasonId: season.id)
                    // Filter out progress records without locationId (session-based progress)
                    userProgress = Dictionary(uniqueKeysWithValues:
                        progressArray.compactMap { progress in
                            guard let locationId = progress.locationId else { return nil }
                            return (locationId, progress)
                        }
                    )

                    // Load completion counts for each part
                    for part in seasonParts {
                        let count = try await service.getPartCompletionCount(userId: userId, partId: part.id)
                        partCompletionCounts[part.id] = count
                    }
                } catch {
                    // Log error but don't block the UI - user can still see parts without progress
                    print("⚠️ Failed to load user progress: \(error.localizedDescription)")
                    // Show progress as 0 for all parts
                    partCompletionCounts = Dictionary(uniqueKeysWithValues: seasonParts.map { ($0.id, 0) })
                }
            }
        } catch {
            // Only show error if critical data (parts) fails to load
            errorMessage = "Unable to load season content. Please try again."
            print("❌ Error loading season parts: \(error)")
        }

        isLoading = false
    }

    /// Select a part and load its locations
    func selectPart(_ part: SeasonPart) async {
        // Check if part is unlocked
        guard await isPartUnlocked(part) else {
            errorMessage = "Complete \(part.unlockRequirement) locations from the previous part to unlock"
            return
        }

        selectedPart = part
        isLoading = true
        errorMessage = nil

        do {
            locations = try await service.fetchSeasonLocations(partId: part.id)
        } catch {
            errorMessage = "Failed to load locations: \(error.localizedDescription)"
            print("❌ Error loading locations: \(error)")
        }

        isLoading = false
    }

    /// Check if a part is unlocked
    func isPartUnlocked(_ part: SeasonPart) async -> Bool {
        guard let userId = currentUserId else { return false }

        do {
            // If unlock requirement is 0, part is unlocked
            guard part.unlockRequirement > 0 else { return true }

            // For Part 2+, check completion count from cache first
            if let completionCount = partCompletionCounts[part.id] {
                return completionCount >= part.unlockRequirement
            }

            // Otherwise query the service
            return try await service.isPartUnlocked(
                userId: userId,
                partId: part.id,
                unlockRequirement: part.unlockRequirement
            )
        } catch {
            print("❌ Error checking unlock status: \(error)")
            return false
        }
    }

    // MARK: - Progress Tracking

    /// Get completion stats for a part
    func getCompletionStats(partId: UUID) -> (completed: Int, total: Int) {
        let completedCount = partCompletionCounts[partId] ?? 0
        let part = seasonParts.first(where: { $0.id == partId })
        let total = part?.totalLocations ?? 0
        return (completed: completedCount, total: total)
    }

    /// Get completion stats for a season
    func getSeasonCompletionStats(seasonId: UUID) -> (completed: Int, total: Int) {
        let parts = seasonParts.filter { part in
            seasonParts.contains(where: { $0.seasonId == seasonId })
        }

        let totalLocations = parts.reduce(0) { $0 + $1.totalLocations }
        let completedLocations = parts.reduce(0) { sum, part in
            sum + (partCompletionCounts[part.id] ?? 0)
        }

        return (completed: completedLocations, total: totalLocations)
    }

    /// Get progress for a specific location
    func getLocationProgress(_ locationId: UUID) -> UserSeasonProgress? {
        return userProgress[locationId]
    }

    /// Get star count for a location (0-3)
    func getLocationStars(_ locationId: UUID) -> Int {
        return userProgress[locationId]?.starsEarned ?? 0
    }

    /// Check if a location is completed
    func isLocationCompleted(_ locationId: UUID) -> Bool {
        return userProgress[locationId]?.isCompleted ?? false
    }

    // MARK: - Game Flow

    /// Start a game for a specific location
    func playLocation(_ location: SeasonLocation) async {
        guard let userId = currentUserId else {
            errorMessage = "Please log in to play"
            return
        }

        guard let _ = selectedSeason?.id,
              let _ = selectedPart?.id else {
            errorMessage = "Invalid season or part"
            return
        }

        // Check tutorial state
        do {
            let settings = try await service.fetchGameSettings(userId: userId)
            if settings?.hasPlayedGeogame == false && settings?.hasSeenTutorial == false {
                // Show tutorial first (handled by UI)
                selectedLocation = location
            } else {
                // Start game directly
                selectedLocation = location
            }
        } catch {
            print("❌ Error checking tutorial state: \(error)")
            selectedLocation = location
        }
    }

    /// Save progress after completing a game
    func saveGameProgress(location: SeasonLocation, session: GameSession) async {
        guard let userId = currentUserId,
              let seasonId = selectedSeason?.id,
              let partId = selectedPart?.id else {
            errorMessage = "Cannot save progress: invalid session"
            return
        }

        isLoading = true

        do {
            // Save progress to database
            try await service.saveLocationProgress(
                userId: userId,
                seasonId: seasonId,
                partId: partId,
                locationId: location.id,
                session: session
            )

            // Reload progress to update UI
            let progressArray = try await service.fetchUserProgress(userId: userId, seasonId: seasonId)
            userProgress = Dictionary(uniqueKeysWithValues:
                progressArray.compactMap { progress in
                    guard let locationId = progress.locationId else { return nil }
                    return (locationId, progress)
                }
            )

            // Update completion count for this part
            let count = try await service.getPartCompletionCount(userId: userId, partId: partId)
            partCompletionCounts[partId] = count

            print("✅ Progress saved successfully for location: \(location.locationName)")
        } catch {
            errorMessage = "Failed to save progress: \(error.localizedDescription)"
            print("❌ Error saving progress: \(error)")
        }

        isLoading = false
    }

    // MARK: - Tutorial Management

    /// Mark tutorial as seen
    func markTutorialSeen() async {
        guard let userId = currentUserId else { return }

        do {
            try await service.markTutorialSeen(userId: userId)
            print("✅ Tutorial marked as seen")
        } catch {
            print("❌ Error marking tutorial as seen: \(error)")
        }
    }

    /// Mark tutorial as skipped
    func markTutorialSkipped() async {
        guard let userId = currentUserId else { return }

        do {
            try await service.markTutorialSkipped(userId: userId)
            print("✅ Tutorial marked as skipped")
        } catch {
            print("❌ Error marking tutorial as skipped: \(error)")
        }
    }

    // MARK: - Session-Based Gameplay

    /// Start a session-based game for a part (10 random locations, 30 questions)
    func startPartSession(part: SeasonPart) async {
        guard let userId = currentUserId else {
            errorMessage = "Please log in to play"
            return
        }

        activePartId = part.id
        pendingSessionPart = part

        do {
            // Check tutorial state
            let settings = try await service.fetchGameSettings(userId: userId)
            if settings?.hasSeenTutorial == false {
                // Show tutorial first
                showTutorial = true
            } else {
                // Start session directly
                try await generateAndStartSession(part: part)
            }
        } catch {
            errorMessage = "Failed to start session: \(error.localizedDescription)"
            print("❌ Error starting session: \(error)")
        }
    }

    /// Launch session after tutorial (or skip)
    func launchSession() {
        guard let part = pendingSessionPart else { return }

        Task {
            try await generateAndStartSession(part: part)
        }
    }

    /// Generate 10 random locations and create a 30-question session
    private func generateAndStartSession(part: SeasonPart) async throws {
        guard selectedSeason != nil else {
            throw SeasonDataError.seasonNotFound
        }

        isLoading = true
        errorMessage = nil

        do {
            // Generate 10 random locations
            let randomLocations = try await service.generateRandomSession(partId: part.id, locationCount: 10)

            // Convert to 30 GameQuestions
            let sessionQuestions = createSessionQuestions(from: randomLocations)

            // Create GameSession
            currentGameSession = GameSession(
                id: UUID(),
                questions: sessionQuestions,
                currentQuestionIndex: 0,
                health: 3,
                totalPoints: 0,
                questionsCorrect: 0,
                comboStreak: 0,
                startedAt: Date(),
                landmarksCorrect: 0,
                landmarksAttempted: 0,
                pricesCorrect: 0,
                pricesAttempted: 0
            )

            print("✅ Generated session with \(randomLocations.count) locations, \(sessionQuestions.count) questions")
        } catch {
            errorMessage = "Failed to generate session: \(error.localizedDescription)"
            print("❌ Error generating session: \(error)")
        }

        isLoading = false
    }

    /// Convert 10 locations into 30 GameQuestions (10 landmarks + 20 prices)
    func createSessionQuestions(from locations: [SeasonLocation]) -> [GameQuestion] {
        var questions: [GameQuestion] = []

        for location in locations {
            // Each location generates 3 questions (1 landmark + 2 prices)
            let locationQuestions = location.toGameQuestions()
            questions.append(contentsOf: locationQuestions)
        }

        return questions
    }

    /// Save session progress after completing a game
    func saveSessionProgress(session: GameSession) async {
        guard let userId = currentUserId,
              let seasonId = selectedSeason?.id,
              let partId = activePartId else {
            errorMessage = "Cannot save progress: invalid session"
            return
        }

        isLoading = true

        do {
            // Save session progress to database
            try await service.saveSessionProgress(
                userId: userId,
                seasonId: seasonId,
                partId: partId,
                session: session
            )

            // Reload parts to update unlock status if passed
            seasonParts = try await service.fetchSeasonParts(seasonId: seasonId)

            // Update completion counts
            for part in seasonParts {
                let hasPassed = try await service.hasPassedPart(userId: userId, partId: part.id)
                if hasPassed {
                    partCompletionCounts[part.id] = 1  // Mark as passed
                }
            }

            let totalCorrect = session.landmarksCorrect + session.pricesCorrect
            let hasPassed = totalCorrect >= 24

            print("✅ Session progress saved: \(totalCorrect)/30 correct, Passed: \(hasPassed)")

            // Clear session state
            currentGameSession = nil
            activePartId = nil
            pendingSessionPart = nil
        } catch {
            errorMessage = "Failed to save session progress: \(error.localizedDescription)"
            print("❌ Error saving session progress: \(error)")
        }

        isLoading = false
    }

    // MARK: - Helper Methods

    /// Clear selection state
    func clearSelection() {
        selectedSeason = nil
        selectedPart = nil
        selectedLocation = nil
        seasonParts = []
        locations = []
        userProgress = [:]
        partCompletionCounts = [:]
    }

    /// Refresh all data
    func refresh() async {
        await getCurrentUser()
        await loadSeasons()
    }
}
