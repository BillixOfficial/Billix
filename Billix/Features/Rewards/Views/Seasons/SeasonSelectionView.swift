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
    @State private var currentPage = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background
                SeasonThemeBackground(season: nil)

                // Content
                VStack(spacing: 0) {
                    // Header with modern typography
                    VStack(spacing: 8) {
                        Text("PRICE GUESSR")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#1F2937"))

                        Text("Choose your adventure")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color(hex: "#6B7280"))
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 20)

                    // Season cards - Horizontal TabView
                    if viewModel.isLoading && viewModel.seasons.isEmpty {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    } else {
                        VStack(spacing: 12) {
                            TabView {
                                ForEach(viewModel.seasons) { season in
                                    let stats = viewModel.getSeasonCompletionStats(seasonId: season.id)

                                    SeasonCardLarge(
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
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 20)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .frame(height: 400)

                            // Custom page indicator
                            if viewModel.seasons.count > 1 {
                                HStack(spacing: 8) {
                                    ForEach(0..<viewModel.seasons.count, id: \.self) { index in
                                        Circle()
                                            .fill(index == 0 ? Color(hex: "#F97316") : Color(hex: "#D1D5DB"))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .padding(.bottom, 4)
                            }
                        }

                        // Continue Playing section
                        if !viewModel.seasons.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Continue Playing")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(hex: "#1F2937"))
                                    .padding(.horizontal, 24)

                                // Quick resume button
                                if let firstSeason = viewModel.seasons.first(where: { !$0.isLocked }) {
                                    let stats = viewModel.getSeasonCompletionStats(seasonId: firstSeason.id)

                                    if stats.completed > 0 && stats.completed < stats.total {
                                        Button(action: {
                                            Task {
                                                await viewModel.selectSeason(firstSeason)
                                            }
                                        }) {
                                            HStack(spacing: 14) {
                                                // Season icon
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.white.opacity(0.3))
                                                        .frame(width: 48, height: 48)

                                                    Image(systemName: firstSeason.iconName)
                                                        .font(.system(size: 22, weight: .bold))
                                                        .foregroundColor(.white)
                                                }

                                                // Info
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(firstSeason.title)
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(.white)

                                                    Text("\(stats.completed)/\(stats.total) locations")
                                                        .font(.system(size: 13, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.8))
                                                }

                                                Spacer()

                                                // Arrow icon
                                                Image(systemName: "arrow.right.circle.fill")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 16)
                                            .background(
                                                LinearGradient(
                                                    colors: [Color(hex: "#F97316"), Color(hex: "#E11D48")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .shadow(color: Color(hex: "#F97316").opacity(0.3), radius: 12, x: 0, y: 6)
                                            .padding(.horizontal, 24)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.top, 16)
                        }

                        // Error message (dismissible)
                        if let error = viewModel.errorMessage {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
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
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            .transition(.opacity.combined(with: .scale))
                        }

                        Spacer(minLength: 20)
                    }
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
