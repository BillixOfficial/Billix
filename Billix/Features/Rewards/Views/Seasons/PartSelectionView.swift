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
            // Background
            Color.billixLightGreen
                .ignoresSafeArea()

            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(seasonTitle)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.billixDarkGreen)

                        Text("Choose a chapter")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    // Part cards
                    if viewModel.isLoading && viewModel.seasonParts.isEmpty {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.top, 40)
                    } else {
                        ForEach(viewModel.seasonParts) { part in
                            let stats = viewModel.getCompletionStats(partId: part.id)

                            PartCard(
                                part: part,
                                progress: stats,
                                isUnlocked: part.unlockRequirement == 0 || stats.completed >= part.unlockRequirement,
                                onTap: {
                                    Task {
                                        await viewModel.startPartSession(part: part)
                                    }
                                }
                            )
                            .padding(.horizontal, 20)
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
