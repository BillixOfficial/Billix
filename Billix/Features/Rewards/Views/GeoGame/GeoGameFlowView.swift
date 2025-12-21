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

    @AppStorage("neverShowGeoGameTutorial") private var neverShowTutorial: Bool = false
    @State private var showTutorial: Bool = true
    @State private var showGame: Bool = false

    var body: some View {
        ZStack {
            if showTutorial && !neverShowTutorial {
                // Show tutorial (unless user chose "Don't Show Again")
                GeoGameHowToPlayView(
                    onStart: {
                        // User completed tutorial - start game
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showTutorial = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showGame = true
                        }
                    },
                    onSkip: {
                        // User skipped for now - will see it next time
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showTutorial = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showGame = true
                        }
                    },
                    onSkipAndDontShowAgain: {
                        // User chose to never see it again - save preference
                        neverShowTutorial = true
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showTutorial = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showGame = true
                        }
                    }
                )
                .transition(.opacity)
            } else if showGame || neverShowTutorial {
                // Show game (either after tutorial or if user disabled it)
                GeoGameContainerView(
                    initialGame: game,
                    onComplete: onComplete,
                    onPlayAgain: onPlayAgain,
                    onDismiss: onDismiss
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            // If user disabled tutorial, go straight to game
            if neverShowTutorial {
                showTutorial = false
                showGame = true
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
