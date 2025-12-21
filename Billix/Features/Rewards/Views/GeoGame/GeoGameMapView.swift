//
//  GeoGameMapView.swift
//  Billix
//
//  Created by Claude Code
//  3D interactive map with landmarks and bounded exploration
//

import SwiftUI
import MapKit

struct GeoGameMapView: View {

    @ObservedObject var viewModel: GeoGameViewModel
    @State private var isInteractionEnabled = true

    var body: some View {
        ZStack {
            // Map with drag and rotate only (no zoom)
            Map(position: $viewModel.cameraPosition, interactionModes: isInteractionEnabled ? [.pan, .rotate] : []) {
                // No markers - let users explore landmarks naturally
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all, showsTraffic: false))
            .mapControls {
                // Remove all controls for clean experience
            }
            .allowsHitTesting(isInteractionEnabled)
            .ignoresSafeArea()
            .onChange(of: viewModel.cameraPosition) { _, newPosition in
                // Track camera position for zoom operations
                viewModel.updateCameraTracking(newPosition)
                // Enforce pan boundaries
                viewModel.enforcePanBoundaries()
            }
            .onAppear {
                // Enable exploration mode
                viewModel.enableExplorationMode()
            }

            // Top-Right: Landmark Button
            if viewModel.gameState.phase == .phase1Location || viewModel.gameState.phase == .transition {
                VStack {
                    HStack {
                        Spacer()

                        // Return to Landmark Button
                        returnToLandmarkButton
                            .padding(.trailing, 20)
                    }
                    .padding(.top, 100)  // Below close button and phase indicator

                    Spacer()
                }
            }
        }
    }

    // MARK: - Return to Landmark Button

    private var returnToLandmarkButton: some View {
        Button(action: {
            viewModel.returnToLandmark()
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }) {
            VStack(spacing: 4) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 18))
                Text("Landmark")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 54)
            .background(Color.billixMoneyGreen)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
        }
    }

}

#Preview {
    GeoGameMapView(
        viewModel: GeoGameViewModel(
            gameData: GeoGameDataService.mockGames[0]
        )
    )
}
