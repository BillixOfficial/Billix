//
//  SeasonSelectionView.swift
//  Billix
//
//  Created by Claude Code
//  Main view for selecting which season to play
//

import SwiftUI

struct SeasonSelectionView: View {
    @StateObject private var viewModel = SeasonViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background
                SeasonThemeBackground(season: nil)

                // Content
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header with gradient text
                        VStack(spacing: Spacing.sm) {
                            Text("Price Guessr")
                                .font(.seasonLargeTitle)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.billixDarkGreen, .billixMoneyGreen],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Choose your adventure")
                                .font(.seasonSubtitle)
                                .foregroundColor(.billixMediumGreen)
                        }
                        .padding(.top, Spacing.xl)
                        .padding(.bottom, Spacing.md)

                        // Season cards with staggered animation
                        if viewModel.isLoading && viewModel.seasons.isEmpty {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: Spacing.lg) {
                                ForEach(Array(viewModel.seasons.enumerated()), id: \.element.id) { index, season in
                                    let stats = viewModel.getSeasonCompletionStats(seasonId: season.id)

                                    SeasonCard(
                                        season: season,
                                        progress: stats,
                                        isLocked: season.isLocked,
                                        onTap: {
                                            if !season.isLocked {
                                                Task {
                                                    await viewModel.selectSeason(season)
                                                }
                                            }
                                        }
                                    )
                                    .padding(.horizontal, Spacing.xl)
                                    .staggeredAppearance(index: index, appeared: appeared)
                                }
                            }
                        }

                        // Error message (dismissible)
                        if let error = viewModel.errorMessage {
                            HStack(spacing: Spacing.md) {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Error")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.red)

                                    Text(error)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.red.opacity(0.9))
                                }

                                Spacer()

                                Button(action: {
                                    withAnimation {
                                        viewModel.errorMessage = nil
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red.opacity(0.6))
                                }
                            }
                            .padding(Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, Spacing.xl)
                            .transition(.opacity.combined(with: .scale))
                        }

                        Spacer(minLength: 40)
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationDestination(item: $viewModel.selectedSeason) { season in
                PartSelectionView(
                    seasonId: season.id,
                    seasonTitle: season.title,
                    viewModel: viewModel
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.billixMediumGreen.opacity(0.6))
                    }
                }
            }
            .onAppear {
                withAnimation {
                    appeared = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Season Selection") {
    SeasonSelectionView()
}
