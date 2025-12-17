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

    @State private var showTutorial = false
    @State private var selectedLocation: SeasonLocation?
    @State private var pendingLocation: SeasonLocation? // Location waiting for tutorial completion
    @State private var hasCheckedTutorial = false

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
                    // Don't mark as seen - let it show again next time
                    showTutorial = false
                },
                onSkip: {
                    // Don't mark as seen - let it show again next time
                    showTutorial = false
                },
                onSkipAndDontShowAgain: {
                    // ONLY this option marks it as permanently seen
                    Task {
                        await viewModel.markTutorialSeen()
                    }
                    showTutorial = false
                }
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
            if !hasCheckedTutorial {
                await checkTutorialStatus()
                hasCheckedTutorial = true
            }
        }
    }

    // MARK: - Private Methods

    private func handleLocationTap(_ location: SeasonLocation) {
        // Check if user has seen tutorial
        Task {
            let userId = try? await SupabaseService.shared.client.auth.session.user.id
            guard let userId = userId else { return }

            let settings = try? await SeasonDataService.shared.fetchGameSettings(userId: userId)

            // Show tutorial unless user selected "Don't Show Again"
            if settings?.hasSeenTutorial == true {
                // User chose "Don't Show Again" - skip tutorial
                await MainActor.run {
                    selectedLocation = location
                }
            } else {
                // Show tutorial (first time or they haven't disabled it)
                await MainActor.run {
                    pendingLocation = location
                    showTutorial = true
                }
            }
        }
    }

    private func checkTutorialStatus() async {
        let userId = try? await SupabaseService.shared.client.auth.session.user.id
        guard let userId = userId else { return }

        // Pre-fetch settings to avoid delay on first tap
        _ = try? await SeasonDataService.shared.fetchGameSettings(userId: userId)
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
