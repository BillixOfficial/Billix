//
//  GeoGameFloatingCard.swift
//  Billix
//
//  Created by Claude Code
//  Floating white card container that switches between game phases
//

import SwiftUI

struct GeoGameFloatingCard: View {

    @ObservedObject var viewModel: GeoGameViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Card content switches based on phase
            Group {
                switch viewModel.gameState.phase {
                case .loading:
                    loadingView

                case .phase1Location:
                    Phase1LocationView(viewModel: viewModel)

                case .transition:
                    Phase1LocationView(viewModel: viewModel)  // Show success state

                case .phase2Price:
                    Phase2PriceView(viewModel: viewModel)

                case .result:
                    GeoGameResultView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(.billixMoneyGreen)

            Text("Loading game...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview("Phase 1") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            GeoGameFloatingCard(
                viewModel: GeoGameViewModel(
                    gameData: GeoGameDataService.mockGames[0]
                )
            )
        }
    }
}

#Preview("Phase 2") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            GeoGameFloatingCard(
                viewModel: {
                    let vm = GeoGameViewModel(gameData: GeoGameDataService.mockGames[0])
                    vm.gameState.phase = .phase2Price
                    vm.gameState.phase1Points = 500
                    return vm
                }()
            )
        }
    }
}
