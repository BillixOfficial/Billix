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
