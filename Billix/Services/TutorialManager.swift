//
//  TutorialManager.swift
//  Billix
//
//  Created by Claude Code
//  Centralized tutorial state management service
//

import Foundation
import SwiftUI

@MainActor
class TutorialManager: ObservableObject {

    // MARK: - Published Properties

    @Published var isLoading: Bool = false
    @Published var cachedSettings: UserGameSettings?

    // MARK: - Private Properties

    private let service = SeasonDataService.shared
    private var currentUserId: UUID?

    // MARK: - Initialization

    init() {
        Task {
            await loadCurrentUser()
        }
    }

    // MARK: - User Management

    private func loadCurrentUser() async {
        do {
            let session = try await SupabaseService.shared.client.auth.session
            currentUserId = session.user.id
            print("✅ TutorialManager initialized for user: \(session.user.id.uuidString.prefix(8))...")
        } catch {
            print("⚠️ No authenticated user found in TutorialManager")
        }
    }

    // MARK: - Tutorial State Management

    /// Fetch tutorial settings with retry logic and caching
    func fetchTutorialSettings(userId: UUID, forceFetch: Bool = false) async throws -> UserGameSettings {
        // Use cache if available and not forcing fetch
        if !forceFetch, let cached = cachedSettings, cached.userId == userId {
            print("   📦 Using cached tutorial settings")
            return cached
        }

        isLoading = true
        defer { isLoading = false }

        // Retry up to 3 times with exponential backoff
        var lastError: Error?
        for attempt in 1...3 {
            do {
                let settings = try await service.fetchGameSettings(userId: userId)
                    ?? UserGameSettings(userId: userId)

                // Cache successful fetch
                cachedSettings = settings

                print("   ✅ Fetched tutorial settings (attempt \(attempt))")
                return settings
            } catch {
                lastError = error
                print("   ⚠️ Fetch attempt \(attempt) failed: \(error.localizedDescription)")

                if attempt < 3 {
                    // Exponential backoff: 0.5s, 1s, 2s
                    let delayNanoseconds = UInt64(pow(2.0, Double(attempt - 1)) * 500_000_000)
                    try await Task.sleep(nanoseconds: delayNanoseconds)
                }
            }
        }

        // All retries failed - return default (show tutorial for safety)
        print("   ❌ All retries failed, returning default settings (will show tutorial)")
        let defaultSettings = UserGameSettings(userId: userId)
        cachedSettings = defaultSettings
        return defaultSettings
    }

    /// Check if tutorial should be shown automatically
    func shouldShowTutorial() async -> Bool {
        guard let userId = currentUserId else {
            print("   ⚠️ No user ID - defaulting to show tutorial")
            return true
        }

        do {
            let settings = try await fetchTutorialSettings(userId: userId)

            // Don't show if user completed tutorial OR clicked "Don't Show Again"
            let shouldShow = !settings.hasCompletedTutorial && !settings.hasSeenTutorial

            print("   🔍 shouldShowTutorial() = \(shouldShow) (completed: \(settings.hasCompletedTutorial), seen: \(settings.hasSeenTutorial))")

            return shouldShow
        } catch {
            print("   ❌ Error checking tutorial state: \(error.localizedDescription)")
            // Show tutorial on error (safer default)
            return true
        }
    }

    /// Check if tutorial can be shown manually (always true)
    func shouldShowTutorialManually() -> Bool {
        return true
    }

    /// Mark tutorial as completed (user clicked "LET'S PLAY!")
    func markTutorialCompleted(userId: UUID, pagesViewed: Int) async throws {
        isLoading = true
        defer { isLoading = false }

        print("   📝 Marking tutorial as completed (pages: \(pagesViewed))")

        try await service.markTutorialCompleted(userId: userId, pagesViewed: pagesViewed)

        // Update cache
        if var settings = cachedSettings, settings.userId == userId {
            settings.hasCompletedTutorial = true
            settings.hasSeenTutorial = true
            settings.lastTutorialPageViewed = pagesViewed
            settings.lastTutorialShownAt = Date()
            settings.hasPlayedGeogame = true
            cachedSettings = settings
        }

        print("   ✅ Tutorial marked as completed")
    }

    /// Mark tutorial as skipped (user clicked "Skip for Now")
    func markTutorialSkipped(userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        print("   📝 Marking tutorial as skipped")

        try await service.markTutorialSkipped(userId: userId)

        // Update cache
        if var settings = cachedSettings, settings.userId == userId {
            settings.tutorialSkippedCount += 1
            cachedSettings = settings
        }

        print("   ✅ Tutorial skip count incremented")
    }

    /// Mark tutorial as dismissed (user clicked "Don't Show Again")
    func markTutorialDismissed(userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        print("   📝 Marking tutorial as dismissed (Don't Show Again)")

        try await service.markTutorialSeen(userId: userId)

        // Update cache
        if var settings = cachedSettings, settings.userId == userId {
            settings.hasSeenTutorial = true
            settings.lastTutorialShownAt = Date()
            cachedSettings = settings
        }

        print("   ✅ Tutorial permanently dismissed")
    }

    /// Track page view (for analytics)
    func trackPageView(userId: UUID, pageNumber: Int) async {
        do {
            try await service.trackTutorialPageView(userId: userId, pageNumber: pageNumber)

            // Update cache
            if var settings = cachedSettings, settings.userId == userId {
                settings.lastTutorialPageViewed = max(settings.lastTutorialPageViewed, pageNumber)
                cachedSettings = settings
            }
        } catch {
            print("   ⚠️ Failed to track page view: \(error.localizedDescription)")
            // Non-critical error - don't propagate
        }
    }

    /// Track manual tutorial view (for analytics)
    func trackManualTutorialView() {
        print("   📚 User manually opened tutorial (no state change)")
        // Optional: Track analytics event here
    }

    // MARK: - Migration from @AppStorage

    /// Migrate legacy @AppStorage value to database
    func migrateFromAppStorage(userId: UUID) async throws {
        let appStorageKey = "neverShowGeoGameTutorial"

        // Check if @AppStorage value exists
        if UserDefaults.standard.object(forKey: appStorageKey) != nil {
            let neverShowAgain = UserDefaults.standard.bool(forKey: appStorageKey)

            print("   🔄 Migrating @AppStorage value: \(neverShowAgain)")

            if neverShowAgain {
                // User previously clicked "Don't Show Again"
                try await markTutorialDismissed(userId: userId)
            }

            // Clear @AppStorage value
            UserDefaults.standard.removeObject(forKey: appStorageKey)
            print("   ✅ Migration complete, @AppStorage cleared")
        } else {
            print("   ℹ️  No @AppStorage value to migrate")
        }
    }

    // MARK: - Cache Management

    /// Pre-fetch tutorial settings in background
    func preFetchSettings(userId: UUID) async {
        do {
            _ = try await fetchTutorialSettings(userId: userId, forceFetch: false)
            print("   ✅ Pre-fetched tutorial settings for user: \(userId.uuidString.prefix(8))...")
        } catch {
            print("   ⚠️ Pre-fetch failed: \(error.localizedDescription)")
            // Non-critical - cache will be populated on next fetch
        }
    }

    /// Invalidate cache (force refresh on next fetch)
    func invalidateCache() {
        cachedSettings = nil
        print("   🗑️  Tutorial settings cache invalidated")
    }
}
