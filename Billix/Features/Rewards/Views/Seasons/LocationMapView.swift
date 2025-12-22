//
//  LocationMapView.swift
//  Billix
//
//  Created by Claude Code
//  View displaying list of locations for a specific part
//

import SwiftUI
import Supabase

struct LocationMapView: View {
    let partId: UUID
    let partTitle: String
    @ObservedObject var viewModel: SeasonViewModel
    @StateObject private var tutorialManager = TutorialManager()

    @State private var showTutorial = false
    @State private var selectedLocation: SeasonLocation?
    @State private var pendingLocation: SeasonLocation? // Location waiting for tutorial completion

    var body: some View {
        ZStack {
            // Background
            Color.billixLightGreen
                .ignoresSafeArea()

            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text(partTitle)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.billixDarkGreen)

                        let stats = viewModel.getCompletionStats(partId: partId)
                        Text("\(stats.completed)/\(stats.total) Locations")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    // Location rows
                    if viewModel.isLoading && viewModel.locations.isEmpty {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.top, 40)
                    } else {
                        ForEach(viewModel.locations) { location in
                            LocationRow(
                                location: location,
                                progress: viewModel.getLocationProgress(location.id),
                                onTap: {
                                    handleLocationTap(location)
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                    }

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                            )
                            .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTutorial, onDismiss: {
            // After tutorial dismisses, start the game
            if let location = pendingLocation {
                selectedLocation = location
                pendingLocation = nil
            }
        }) {
            GeoGameHowToPlayView(
                onStart: {
                    showTutorial = false
                    Task {
                        if let userId = viewModel.currentUserId {
                            do {
                                try await tutorialManager.markTutorialCompleted(userId: userId, pagesViewed: 4)
                            } catch {
                                print("⚠️ Failed to mark tutorial completed: \(error.localizedDescription)")
                            }
                        }
                    }
                },
                onSkip: {
                    showTutorial = false
                    Task {
                        if let userId = viewModel.currentUserId {
                            do {
                                try await tutorialManager.markTutorialSkipped(userId: userId)
                            } catch {
                                print("⚠️ Failed to mark tutorial skipped: \(error.localizedDescription)")
                            }
                        }
                    }
                },
                onSkipAndDontShowAgain: {
                    showTutorial = false
                    Task {
                        if let userId = viewModel.currentUserId {
                            do {
                                try await tutorialManager.markTutorialDismissed(userId: userId)
                            } catch {
                                print("⚠️ Failed to mark tutorial dismissed: \(error.localizedDescription)")
                            }
                        }
                    }
                },
                onPageChanged: { pageNumber in
                    Task {
                        if let userId = viewModel.currentUserId {
                            await tutorialManager.trackPageView(userId: userId, pageNumber: pageNumber)
                        }
                    }
                },
                isLoading: tutorialManager.isLoading,
                isManualView: false  // Full tutorial flow with skip options
            )
        }
        .fullScreenCover(item: $selectedLocation) { location in
            SeasonGameContainerView(
                location: location,
                onComplete: { session in
                    Task {
                        await viewModel.saveGameProgress(location: location, session: session)
                        selectedLocation = nil
                    }
                }
            )
        }
        .task {
            // Pre-fetch tutorial settings in background
            if let userId = viewModel.currentUserId {
                await tutorialManager.preFetchSettings(userId: userId)
            }
        }
    }

    // MARK: - Private Methods

    private func handleLocationTap(_ location: SeasonLocation) {
        // Use cached settings to avoid network delay
        Task {
            guard let userId = viewModel.currentUserId else { return }

            do {
                let settings = try await tutorialManager.fetchTutorialSettings(userId: userId, forceFetch: false)

                // Show tutorial unless user completed it or chose "Don't Show Again"
                if settings.hasCompletedTutorial || settings.hasSeenTutorial {
                    // Skip tutorial
                    await MainActor.run {
                        selectedLocation = location
                    }
                } else {
                    // Show tutorial
                    await MainActor.run {
                        pendingLocation = location
                        showTutorial = true
                    }
                }
            } catch {
                print("⚠️ Failed to fetch tutorial settings: \(error.localizedDescription)")
                // Default to showing tutorial (safer)
                await MainActor.run {
                    pendingLocation = location
                    showTutorial = true
                }
            }
        }
    }

}

// MARK: - Preview

#Preview("Location Map") {
    NavigationStack {
        LocationMapView(
            partId: UUID(),
            partTitle: "Coast to Coast",
            viewModel: SeasonViewModel()
        )
    }
}
