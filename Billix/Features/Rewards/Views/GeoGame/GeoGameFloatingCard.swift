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
            // Progress header
            if viewModel.gameState.phase != .loading {
                HStack {
                    Text(viewModel.locationProgressText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    Spacer()

                    // Timer badge (for active phases)
                    if viewModel.isTimerActive {
                        CompactTimerBadge(
                            timeRemaining: viewModel.timeRemaining,
                            color: viewModel.timerColor,
                            shouldPulse: viewModel.shouldPulseTimer
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))
            }

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

            // Life bar display (100 HP max)
            if viewModel.gameState.phase != .loading {
                lifeBarView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
            }
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Life Bar View

    private var lifeBarView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red)

                Text("\(viewModel.session.health) HP")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(viewModel.session.health)%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Life bar (100 HP max)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    // HP fill with color gradient
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: viewModel.session.health > 50 ? [.green, .green] :
                                    viewModel.session.health > 20 ? [.orange, .orange] : [.red, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(0, geometry.size.width * CGFloat(viewModel.session.health) / 100.0))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.session.health)
                }
            }
            .frame(height: 10)
        }
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

struct GeoGameFloatingCard_Phase_1_Previews: PreviewProvider {
    static var previews: some View {
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
}

struct GeoGameFloatingCard_Phase_2_Previews: PreviewProvider {
    static var previews: some View {
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
}
