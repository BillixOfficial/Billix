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
            // Map with pinch-to-zoom enabled
            Map(position: $viewModel.cameraPosition, interactionModes: isInteractionEnabled ? [.pan, .rotate, .zoom] : []) {
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

    // MARK: - Zoom Controls

    private var zoomControls: some View {
        VStack(spacing: 0) {
            // Zoom In Button
            Button(action: {
                viewModel.zoomIn()
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.7))
            }

            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 1)

            // Zoom Out Button
            Button(action: {
                viewModel.zoomOut()
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.7))
            }
        }
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.4), radius: 8, y: 2)
    }
}

#Preview {
    GeoGameMapView(
        viewModel: GeoGameViewModel(
            gameData: GeoGameDataService.mockGames[0]
        )
    )
}
