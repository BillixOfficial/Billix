//
//  PartSelectionView.swift
//  Billix
//
//  Redesigned as "Expedition Ticket" selection screen
//  Clean off-white background with timeline visualization
//

import SwiftUI

struct PartSelectionView: View {
    let seasonId: UUID
    let seasonTitle: String
    @ObservedObject var viewModel: SeasonViewModel
    @StateObject private var tutorialManager = TutorialManager()

    var body: some View {
        ZStack {
            // Off-white background
            Color(hex: "#FAFAFA")
                .ignoresSafeArea()

            // Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text(seasonTitle)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#1F2937"))

                        Text("Start your expedition")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "#6B7280"))
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                    // Part cards with timeline connectors
                    if viewModel.isLoading && viewModel.seasonParts.isEmpty {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.top, 60)
                    } else {
                        ForEach(Array(viewModel.seasonParts.enumerated()), id: \.element.id) { index, part in
                            let stats = viewModel.getCompletionStats(partId: part.id)
                            let isUnlocked = part.unlockRequirement == 0 || stats.completed >= part.unlockRequirement
                            let isLastPart = index == viewModel.seasonParts.count - 1

                            PartCard(
                                part: part,
                                progress: stats,
                                isUnlocked: isUnlocked,
                                onTap: {
                                    Task {
                                        await viewModel.startPartSession(part: part)
                                    }
                                }
                            )
                            .padding(.horizontal, 20)

                            // Timeline connector (if not last part)
                            if !isLastPart {
                                let nextPart = viewModel.seasonParts[index + 1]
                                let nextStats = viewModel.getCompletionStats(partId: nextPart.id)
                                let nextIsUnlocked = nextPart.unlockRequirement == 0 || nextStats.completed >= nextPart.unlockRequirement

                                TimelineConnector(
                                    isUnlocked: nextIsUnlocked,
                                    height: 40
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Error message (dismissable)
                    if let error = viewModel.errorMessage {
                        HStack {
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)

                            Spacer()

                            Button(action: {
                                viewModel.errorMessage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red.opacity(0.6))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Select Part")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showTutorial) {
            GeoGameHowToPlayView(
                onStart: {
                    viewModel.showTutorial = false
                    Task {
                        if let userId = viewModel.currentUserId {
                            do {
                                try await tutorialManager.markTutorialCompleted(userId: userId, pagesViewed: 4)
                            } catch {
                                print("⚠️ Failed to mark tutorial completed: \(error.localizedDescription)")
                            }
                        }
                        viewModel.launchSession()
                    }
                },
                onSkip: {
                    viewModel.showTutorial = false
                    Task {
                        if let userId = viewModel.currentUserId {
                            do {
                                try await tutorialManager.markTutorialSkipped(userId: userId)
                            } catch {
                                print("⚠️ Failed to mark tutorial skipped: \(error.localizedDescription)")
                            }
                        }
                        viewModel.launchSession()
                    }
                },
                onSkipAndDontShowAgain: {
                    viewModel.showTutorial = false
                    Task {
                        if let userId = viewModel.currentUserId {
                            do {
                                try await tutorialManager.markTutorialDismissed(userId: userId)
                            } catch {
                                print("⚠️ Failed to mark tutorial dismissed: \(error.localizedDescription)")
                            }
                        }
                        viewModel.launchSession()
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
        .fullScreenCover(item: $viewModel.currentGameSession) { session in
            SessionGameContainerView(
                session: session,
                partId: viewModel.activePartId ?? UUID(),
                onComplete: { completedSession in
                    Task {
                        await viewModel.saveSessionProgress(session: completedSession)
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissToRewards"))) { _ in
            // Clear current game session when returning to rewards
            viewModel.currentGameSession = nil
        }
        .task {
            // Pre-fetch tutorial settings in background
            if let userId = viewModel.currentUserId {
                await tutorialManager.preFetchSettings(userId: userId)
            }
        }
    }
}

// MARK: - Preview

#Preview("Part Selection") {
    NavigationStack {
        PartSelectionView(
            seasonId: UUID(),
            seasonTitle: "USA Roadtrip",
            viewModel: SeasonViewModel()
        )
    }
}
