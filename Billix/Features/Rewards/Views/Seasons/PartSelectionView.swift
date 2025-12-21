//
//  PartSelectionView.swift
//  Billix
//
//  Created by Claude Code
//  View for selecting which part of a season to play
//

import SwiftUI

struct PartSelectionView: View {
    let seasonId: UUID
    let seasonTitle: String
    @ObservedObject var viewModel: SeasonViewModel

    var body: some View {
        ZStack {
            // Themed background
            SeasonThemeBackground(season: viewModel.selectedSeason)
                .ignoresSafeArea()

            // Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text(seasonTitle)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#1F2937"))

                        Text("Choose a chapter")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color(hex: "#6B7280"))
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                    // Part cards with connecting paths
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
                            .padding(.horizontal, 24)

                            // Progress path connector (if not last part)
                            if !isLastPart {
                                let nextPart = viewModel.seasonParts[index + 1]
                                let nextStats = viewModel.getCompletionStats(partId: nextPart.id)
                                let nextIsUnlocked = nextPart.unlockRequirement == 0 || nextStats.completed >= nextPart.unlockRequirement

                                ProgressPathConnector(
                                    isUnlocked: nextIsUnlocked,
                                    isNextToUnlock: !nextIsUnlocked && isUnlocked,
                                    height: 40
                                )
                                .padding(.horizontal, 24)
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
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Select Chapter")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showTutorial) {
            GeoGameHowToPlayView(
                onStart: {
                    viewModel.showTutorial = false
                    viewModel.launchSession()
                },
                onSkip: {
                    viewModel.showTutorial = false
                    Task {
                        await viewModel.markTutorialSkipped()
                        viewModel.launchSession()
                    }
                },
                onSkipAndDontShowAgain: {
                    viewModel.showTutorial = false
                    Task {
                        await viewModel.markTutorialSeen()
                        viewModel.launchSession()
                    }
                }
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
