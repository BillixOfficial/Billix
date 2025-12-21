//
//  SeasonViewModel.swift
//  Billix
//
//  Created by Claude Code
//  ViewModel for managing season/part/location selection flow
//

import Foundation
import Supabase

// MARK: - Season Completion Stats

struct SeasonCompletionStats {
    let completed: Int          // For session-based: parts passed. For location-based: locations completed
    let total: Int             // Total parts or locations in season
    let attempts: Int          // Total legitimate attempts (session-based only)
    let passedParts: Int       // Number of parts passed (session-based only)
    let isSessionBased: Bool   // True if season uses session-based gameplay
}

// MARK: - Part Completion Stats

struct PartCompletionStats {
    let completed: Int
    let total: Int
    let isSessionBased: Bool
    let attempts: Int?        // For session mode
    let hasPassed: Bool?      // For session mode

    var displayText: String {
        if isSessionBased {
            if let passed = hasPassed, passed {
                return "Passed"
            } else {
                return "\(attempts ?? 0) \(attempts == 1 ? "attempt" : "attempts")"
            }
        } else {
            return "\(completed)/\(total)"
        }
    }

    var progressPercent: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}

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

    // NEW: Cached season-level progress stats for all seasons
    @Published var seasonCompletionStats: [UUID: SeasonCompletionStats] = [:]
    @Published var allUserProgress: [UUID: UserSeasonProgress] = [:]

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
            await loadAllSeasonProgress()  // NEW: Load progress for all seasons
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

    /// Load user progress for all seasons (lightweight cache for display)
    func loadAllSeasonProgress() async {
        guard let userId = currentUserId else {
            print("⚠️ No authenticated user - skipping progress load")
            return
        }

        print("🔄 loadAllSeasonProgress() starting for user: \(userId.uuidString.prefix(8))...")
        // Don't set isLoading = true here, as this is a background operation
        errorMessage = nil

        do {
            // Fetch all user progress for this user
            let allProgress = try await service.fetchAllUserProgress(userId: userId)

            // Group by season and calculate completion stats
            for season in seasons {
                let seasonProgress = allProgress.filter { $0.seasonId == season.id }

                // Separate location-based and session-based progress
                let locationProgress = seasonProgress.filter { $0.locationId != nil }
                let sessionProgress = seasonProgress.filter { $0.locationId == nil }

                // Determine if this is a session-based season
                let isSessionBased = !sessionProgress.isEmpty

                if isSessionBased {
                    // Session-based season (like USA Roadtrip)

                    // Count legitimate session attempts
                    // Only count if: health == 0 OR total questions >= 30
                    let legitimateAttempts = sessionProgress.filter { progress in
                        (progress.finalHealth == 0) || (progress.totalAttempted >= 30)
                    }

                    // Count unique parts that have been passed
                    let passedPartIds = Set(sessionProgress.compactMap { progress in
                        progress.isCompleted ? progress.partId : nil
                    })

                    // Get total number of parts in this season
                    let parts = try? await service.fetchSeasonParts(seasonId: season.id)
                    let totalParts = parts?.count ?? 0

                    seasonCompletionStats[season.id] = SeasonCompletionStats(
                        completed: legitimateAttempts.count,  // Total attempts for display
                        total: totalParts,                     // Total parts in season
                        attempts: legitimateAttempts.count,    // Total legitimate attempts
                        passedParts: passedPartIds.count,      // Number of parts passed
                        isSessionBased: true
                    )
                } else {
                    // Location-based season (like Global)

                    // Count completed locations
                    let completedLocations = Set(locationProgress.compactMap {
                        $0.isCompleted ? $0.locationId : nil
                    })

                    // Calculate total locations for this season
                    let parts = try? await service.fetchSeasonParts(seasonId: season.id)
                    let totalLocations = parts?.reduce(0) { $0 + $1.totalLocations } ?? 0

                    seasonCompletionStats[season.id] = SeasonCompletionStats(
                        completed: completedLocations.count,
                        total: totalLocations,
                        attempts: 0,                           // Not applicable for location-based
                        passedParts: 0,                        // Not applicable for location-based
                        isSessionBased: false
                    )
                }
            }

            // Also cache all progress for quick lookup
            allUserProgress = Dictionary(uniqueKeysWithValues:
                allProgress.compactMap { progress in
                    guard let locationId = progress.locationId else { return nil }
                    return (locationId, progress)
                }
            )

            print("✅ Loaded progress for \(allProgress.count) records across \(seasons.count) seasons")
            // Log detailed stats for each season
            for season in seasons {
                if let stats = seasonCompletionStats[season.id] {
                    print("   📊 \(season.title): \(stats.completed)/\(stats.total) completed")
                }
            }
        } catch {
            print("⚠️ Failed to load season progress: \(error)")
            // Non-blocking: show 0/0 if fails
            errorMessage = nil  // Don't show error for progress load failures
        }
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

    /// Detect if a part uses session-based or location-based gameplay
    func getPartGameMode(partId: UUID) -> Bool {
        // Find the season this part belongs to
        guard let part = seasonParts.first(where: { $0.id == partId }),
              let seasonStats = seasonCompletionStats[part.seasonId] else {
            return false  // Default to location-based if unknown
        }
        return seasonStats.isSessionBased
    }

    /// Get completion stats for a part (NEW: Returns PartCompletionStats)
    func getCompletionStats(partId: UUID) -> PartCompletionStats {
        let completedCount = partCompletionCounts[partId] ?? 0
        let part = seasonParts.first(where: { $0.id == partId })
        let total = part?.totalLocations ?? 0
        let isSessionBased = getPartGameMode(partId: partId)

        if isSessionBased {
            // For session mode: check if this part has been passed
            // Get all progress for this part from allUserProgress
            let partProgress = allUserProgress.values.filter { $0.partId == partId }
            let passed = partProgress.contains { $0.isCompleted }

            // Count ALL attempts (even incomplete) to show engagement
            // This aligns with "Expedition Ticket" UX goal of communicating commitment
            let attemptCount = partProgress.count

            return PartCompletionStats(
                completed: passed ? 1 : 0,
                total: 1,
                isSessionBased: true,
                attempts: attemptCount,
                hasPassed: passed
            )
        } else {
            // For location mode: use existing completion count
            return PartCompletionStats(
                completed: completedCount,
                total: total,
                isSessionBased: false,
                attempts: nil,
                hasPassed: nil
            )
        }
    }

    /// Get completion stats for a season
    func getSeasonCompletionStats(seasonId: UUID) -> SeasonCompletionStats {
        // Use cached stats if available (from loadAllSeasonProgress)
        if let cached = seasonCompletionStats[seasonId] {
            print("   🔍 getSeasonCompletionStats() returning CACHED: \(cached.attempts) attempts, \(cached.passedParts)/\(cached.total) passed")
            return cached
        }

        print("   ⚠️ getSeasonCompletionStats() NO CACHE - returning default")
        // Fallback: return default stats
        return SeasonCompletionStats(
            completed: 0,
            total: 0,
            attempts: 0,
            passedParts: 0,
            isSessionBased: false
        )
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
    func saveGameProgress(location: SeasonLocation, session: GameSession, seasonId: UUID? = nil, partId: UUID? = nil) async {
        guard let userId = currentUserId else {
            errorMessage = "Please log in to save progress"
            print("❌ No user ID - cannot save progress")
            return
        }

        // Use provided IDs or fall back to selected season/part
        guard let finalSeasonId = seasonId ?? selectedSeason?.id,
              let finalPartId = partId ?? selectedPart?.id else {
            errorMessage = "Cannot save progress: missing season or part information"
            print("❌ Missing seasonId or partId - seasonId: \(seasonId?.uuidString ?? "nil"), partId: \(partId?.uuidString ?? "nil"), selectedSeason: \(selectedSeason?.id.uuidString ?? "nil"), selectedPart: \(selectedPart?.id.uuidString ?? "nil")")
            return
        }

        isLoading = true
        print("📝 Saving progress for location: \(location.locationName), userId: \(userId.uuidString), seasonId: \(finalSeasonId.uuidString), partId: \(finalPartId.uuidString)")

        do {
            // Save progress to database
            try await service.saveLocationProgress(
                userId: userId,
                seasonId: finalSeasonId,
                partId: finalPartId,
                locationId: location.id,
                session: session
            )

            print("💾 Progress saved to database successfully")

            // Reload progress to update UI and cache
            let progressArray = try await service.fetchUserProgress(userId: userId, seasonId: finalSeasonId)
            userProgress = Dictionary(uniqueKeysWithValues:
                progressArray.compactMap { progress in
                    guard let locationId = progress.locationId else { return nil }
                    return (locationId, progress)
                }
            )

            print("🔄 Reloaded \(progressArray.count) progress records")

            // Update completion count for this part
            let count = try await service.getPartCompletionCount(userId: userId, partId: finalPartId)
            partCompletionCounts[finalPartId] = count

            // IMPORTANT: Also update the seasonCompletionStats cache for the season card
            await loadAllSeasonProgress()

            print("✅ Progress saved successfully for location: \(location.locationName) - Completion count: \(count)")
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
        guard let userId = currentUserId else {
            errorMessage = "Please log in to save progress"
            print("❌ No user ID - cannot save session progress")
            return
        }

        guard let seasonId = selectedSeason?.id,
              let partId = activePartId else {
            errorMessage = "Cannot save progress: missing season or part information"
            print("❌ Missing seasonId or partId for session - selectedSeason: \(selectedSeason?.id.uuidString ?? "nil"), activePartId: \(activePartId?.uuidString ?? "nil")")
            return
        }

        // Only save if game actually ended (not quit mid-game)
        let isLegitimateCompletion = session.health == 0 || session.currentQuestionIndex >= session.questions.count

        if !isLegitimateCompletion {
            print("⚠️ Game not completed legitimately - not saving progress")
            print("   Health: \(session.health), Questions: \(session.currentQuestionIndex)/\(session.questions.count)")
            return
        }

        isLoading = true
        print("📝 Saving session progress - userId: \(userId.uuidString), seasonId: \(seasonId.uuidString), partId: \(partId.uuidString), correct: \(session.questionsCorrect)/\(session.questions.count)")

        do {
            // Save session progress to database
            try await service.saveSessionProgress(
                userId: userId,
                seasonId: seasonId,
                partId: partId,
                session: session
            )

            print("💾 Session progress saved to database successfully")

            // Reload parts to update unlock status if passed
            seasonParts = try await service.fetchSeasonParts(seasonId: seasonId)

            // Update completion counts
            for part in seasonParts {
                let hasPassed = try await service.hasPassedPart(userId: userId, partId: part.id)
                if hasPassed {
                    partCompletionCounts[part.id] = 1  // Mark as passed
                }
            }

            // IMPORTANT: Also update the seasonCompletionStats cache
            await loadAllSeasonProgress()

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
