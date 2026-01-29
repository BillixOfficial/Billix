//
//  GeoGameFlowView.swift
//  Billix
//
//  Created by Claude Code
//  Handles the flow from tutorial -> game
//

import SwiftUI

struct GeoGameFlowView: View {

    let game: DailyGame
    let onComplete: (GameResult) -> Void
    let onPlayAgain: () -> Void
    let onDismiss: () -> Void

    @StateObject private var tutorialManager = TutorialManager()
    @State private var showTutorial: Bool = true
    @State private var showGame: Bool = false
    @State private var isLoadingSettings: Bool = true
    @State private var currentUserId: UUID?

    var body: some View {
        ZStack {
            if isLoadingSettings {
                // Loading state - show minimal loading indicator
                Color.black
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            } else if showTutorial {
                // Show tutorial
                GeoGameHowToPlayView(
                    onStart: {
                        // User completed tutorial - start game
                        Task {
                            if let userId = currentUserId {
                                do {
                                    try await tutorialManager.markTutorialCompleted(userId: userId, pagesViewed: 4)
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showTutorial = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showGame = true
                                    }
                                } catch {
                                    // Still proceed to game even on error
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showTutorial = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showGame = true
                                    }
                                }
                            }
                        }
                    },
                    onSkip: {
                        // User skipped for now - will see it next time
                        Task {
                            if let userId = currentUserId {
                                do {
                                    try await tutorialManager.markTutorialSkipped(userId: userId)
                                } catch {
                                }
                            }
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showTutorial = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showGame = true
                            }
                        }
                    },
                    onSkipAndDontShowAgain: {
                        // User chose to never see it again - save preference
                        Task {
                            if let userId = currentUserId {
                                do {
                                    try await tutorialManager.markTutorialDismissed(userId: userId)
                                } catch {
                                }
                            }
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showTutorial = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showGame = true
                            }
                        }
                    },
                    onPageChanged: { pageNumber in
                        // Track page view
                        Task {
                            if let userId = currentUserId {
                                await tutorialManager.trackPageView(userId: userId, pageNumber: pageNumber)
                            }
                        }
                    },
                    isLoading: tutorialManager.isLoading,
                    isManualView: false  // Full tutorial flow with skip options
                )
                .transition(.opacity)
            } else if showGame {
                // Show game
                GeoGameContainerView(
                    initialGame: game,
                    onComplete: onComplete,
                    onPlayAgain: onPlayAgain,
                    onDismiss: onDismiss
                )
                .transition(.opacity)
            }
        }
        .task {
            // Fetch user ID and load tutorial settings
            do {
                let session = try await SupabaseService.shared.client.auth.session
                currentUserId = session.user.id

                // Migrate from @AppStorage if needed
                try await tutorialManager.migrateFromAppStorage(userId: session.user.id)

                // Check if tutorial should be shown
                let shouldShow = await tutorialManager.shouldShowTutorial()

                await MainActor.run {
                    showTutorial = shouldShow
                    showGame = !shouldShow
                    isLoadingSettings = false
                }
            } catch {
                // Default to showing tutorial (safer)
                await MainActor.run {
                    showTutorial = true
                    showGame = false
                    isLoadingSettings = false
                }
            }
        }
    }
}

#Preview {
    GeoGameFlowView(
        game: GeoGameDataService.mockGames[0],
        onComplete: { _ in },
        onPlayAgain: {},
        onDismiss: {}
    )
}
