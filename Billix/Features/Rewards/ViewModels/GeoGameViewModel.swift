//
//  GeoGameViewModel.swift
//  Billix
//
//  Created by Claude Code
//  Game state machine for geo-economic guessing game
//

import Foundation
import SwiftUI
import MapKit

enum MapViewType {
    case landmark  // Zoomed in on famous landmark
    case region    // Broader city/region view
}

@MainActor
class GeoGameViewModel: ObservableObject {

    // MARK: - Game Data

    let gameData: DailyGame

    // MARK: - Published State

    @Published var gameState: GameState
    @Published var locationChoices: [DecoyLocation]
    @Published var selectedChoice: String?
    @Published var sliderValue: Double = 0.5  // 0.0 to 1.0
    @Published var cameraPosition: MapCameraPosition
    @Published var isOrbiting: Bool = false
    @Published var currentHeading: Double = 0
    @Published var showResult: Bool = false
    @Published var currentMapView: MapViewType = .landmark
    @Published var zoomLevel: Double = 2000  // Camera distance in meters (default zoom)
    @Published var currentCameraCoordinate: CLLocationCoordinate2D?

    // Landmark coordinate for "return to landmark" feature
    private var landmarkCoordinate: CLLocationCoordinate2D?
    private var regionCoordinate: CLLocationCoordinate2D?

    // Pan boundaries (1 mile radius = ~0.015 degrees = ~1600m)
    private var panBoundaryRadius: Double = 0.015  // ~1 mile from landmark

    // Zoom constraints (1 mile radius restriction)
    private let minZoom: Double = 500   // Closest zoom
    private let maxZoom: Double = 5000  // Farthest zoom (~1 mile radius view)

    // MARK: - Computed Properties

    var currentGuess: Double {
        let range = gameData.maxGuess - gameData.minGuess
        return gameData.minGuess + (sliderValue * range)
    }

    var formattedGuess: String {
        if gameData.category == .rent {
            return String(format: "$%.0f", currentGuess)
        } else {
            return String(format: "$%.2f", currentGuess)
        }
    }

    var correctLocationName: String {
        gameData.location
    }

    var accuracyDescription: String? {
        guard gameState.phase == .result,
              let guess = gameState.priceGuess else { return nil }
        return GeoGameScoring.accuracyTier(guess: guess, actual: gameData.actualPrice)
    }

    // MARK: - Callbacks

    var onGameComplete: ((GameResult) -> Void)?
    var onPlayAgain: (() -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - Initialization

    init(gameData: DailyGame, onComplete: ((GameResult) -> Void)? = nil) {
        self.gameData = gameData
        self.onGameComplete = onComplete

        // Initialize location choices (shuffled)
        self.locationChoices = gameData.decoyLocations ?? []

        // Initialize game state
        self.gameState = GameState()

        // Store landmark and region coordinates for boundaries and navigation
        if let landmark = gameData.landmarkCoordinate {
            self.landmarkCoordinate = CLLocationCoordinate2D(
                latitude: landmark.latitude,
                longitude: landmark.longitude
            )
        }
        if let region = gameData.mapRegion {
            self.regionCoordinate = CLLocationCoordinate2D(
                latitude: region.centerLatitude,
                longitude: region.centerLongitude
            )
        }

        // Initialize camera position for exploration
        if let landmark = gameData.landmarkCoordinate {
            // Center on famous landmark for best initial view
            let coord = CLLocationCoordinate2D(
                latitude: landmark.latitude,
                longitude: landmark.longitude
            )
            let landmarkCamera = MapCamera(
                centerCoordinate: coord,
                distance: 2000,  // More zoomed in for better landmark detail
                heading: 0,
                pitch: 60        // 3D perspective
            )
            self.cameraPosition = .camera(landmarkCamera)
            self.currentCameraCoordinate = coord
        } else if let mapRegion = gameData.mapRegion {
            // Fallback to general map region
            let coord = CLLocationCoordinate2D(
                latitude: mapRegion.centerLatitude,
                longitude: mapRegion.centerLongitude
            )
            let explorationCamera = mapRegion.updatedCamera(
                heading: 0,
                distance: 2000,
                pitch: 60
            )
            self.cameraPosition = .camera(explorationCamera)
            self.currentCameraCoordinate = coord
        } else {
            // Final fallback
            self.cameraPosition = .automatic
        }

        // Start the game
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.gameState.phase = .phase1Location
        }
    }

    // MARK: - Phase 1: Location Selection

    func selectLocation(_ label: String) {
        selectedChoice = label
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func submitLocationGuess() {
        guard let selected = selectedChoice else { return }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Find the correct answer
        let correctChoice = locationChoices.first { $0.name == gameData.location }
        let isCorrect = correctChoice?.displayLabel == selected

        gameState.isLocationCorrect = isCorrect
        gameState.selectedLocation = selected

        if isCorrect {
            // Award Phase 1 points (reduced if retry)
            gameState.phase1Points = GeoGameScoring.calculatePhase1Points(
                correct: true,
                isRetry: gameState.isRetryAttempt
            )

            // Transition to Phase 2
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                gameState.phase = .transition
            }

            // Wait for transition animation, then show Phase 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.transitionToPhase2()
            }
        } else {
            // Wrong answer
            if gameState.isRetryAttempt {
                // Second wrong answer - show game over state with Play Again button
                gameState.phase1Points = 0
                gameState.phase2Points = 0
                // Stay in phase1Location to show the INCORRECT message and Play Again button
                // User will click Play Again to start a new game
            } else {
                // First wrong answer - allow retry
                gameState.isRetryAttempt = true
                gameState.incorrectChoice = selected
                selectedChoice = nil  // Clear selection for retry

                // Brief pause to show the incorrect state, then allow retry
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    // Stay in phase1Location, user can try again
                }
            }
        }
    }

    // MARK: - Phase Transition

    private func transitionToPhase2() {
        // Zoom out map
        if let mapRegion = gameData.mapRegion {
            let zoomedCamera = mapRegion.updatedCamera(
                heading: currentHeading,
                distance: 8000,  // Phase 2 altitude (zoomed out)
                pitch: 60
            )

            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                cameraPosition = .camera(zoomedCamera)
            }
        }

        // Update phase
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            gameState.phase = .phase2Price
        }
    }

    // MARK: - Phase 2: Price Estimation

    func submitPriceGuess() {
        let guess = currentGuess
        gameState.priceGuess = guess

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Calculate Phase 2 points
        gameState.phase2Points = GeoGameScoring.calculatePhase2Points(
            guess: guess,
            actual: gameData.actualPrice
        )

        // Show result
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            gameState.phase = .result
            showResult = true
        }
    }

    // MARK: - Game Completion

    func completeGame() {
        let result = GameResult(
            id: UUID(),
            gameId: gameData.id,
            userGuess: gameState.priceGuess ?? 0,
            actualPrice: gameData.actualPrice,
            pointsEarned: gameState.totalPoints,
            accuracy: calculateAccuracy(),
            playedAt: Date()
        )

        onGameComplete?(result)
        onDismiss?()  // Close the game modal
    }

    func resetWithNewGame(_ newGame: DailyGame) {
        // Reset game state
        gameState = GameState()
        locationChoices = newGame.decoyLocations ?? []
        selectedChoice = nil
        sliderValue = 0.5
        showResult = false
        currentHeading = 0
        isOrbiting = false

        // Update camera position for exploration (prioritize landmark)
        if let landmark = newGame.landmarkCoordinate {
            let landmarkCamera = MapCamera(
                centerCoordinate: CLLocationCoordinate2D(
                    latitude: landmark.latitude,
                    longitude: landmark.longitude
                ),
                distance: 2000,
                heading: 0,
                pitch: 60
            )
            cameraPosition = .camera(landmarkCamera)
        } else if let mapRegion = newGame.mapRegion {
            let explorationCamera = mapRegion.updatedCamera(
                heading: 0,
                distance: 2000,
                pitch: 60
            )
            cameraPosition = .camera(explorationCamera)
        }

        // Start the new game
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.gameState.phase = .phase1Location
        }
    }

    private func endGame() {
        let result = GameResult(
            id: UUID(),
            gameId: gameData.id,
            userGuess: 0,
            actualPrice: gameData.actualPrice,
            pointsEarned: 0,
            accuracy: 0,
            playedAt: Date()
        )

        onGameComplete?(result)
    }

    private func calculateAccuracy() -> Double {
        guard let guess = gameState.priceGuess else { return 0 }
        let percentOff = abs(guess - gameData.actualPrice) / gameData.actualPrice
        return max(0, 1.0 - percentOff)
    }

    // MARK: - Map Exploration

    func enableExplorationMode() {
        // Disable orbit, allow user to pan/rotate
        isOrbiting = false

        // Set initial camera position with realistic elevation
        if let mapRegion = gameData.mapRegion {
            let explorationCamera = mapRegion.updatedCamera(
                heading: 0,
                distance: 2000,  // More zoomed in for better landmark detail
                pitch: 60        // Angled for 3D perspective
            )
            cameraPosition = .camera(explorationCamera)
        }
    }

    func enforcePanBoundaries() {
        // Note: We rely on currentCameraCoordinate being updated externally
        // This function just enforces boundaries, tracking is done elsewhere
        guard let landmark = landmarkCoordinate,
              let currentCoord = currentCameraCoordinate else { return }

        // Calculate distance from landmark
        let latDiff: Double = currentCoord.latitude - landmark.latitude
        let lonDiff: Double = currentCoord.longitude - landmark.longitude
        let distanceSquared: Double = latDiff * latDiff + lonDiff * lonDiff
        let distance: Double = sqrt(distanceSquared)

        // If outside boundary, clamp to boundary
        if distance > panBoundaryRadius {
            let ratio: Double = panBoundaryRadius / distance
            let clampedLat: Double = landmark.latitude + (latDiff * ratio)
            let clampedLon: Double = landmark.longitude + (lonDiff * ratio)

            let clampedCoord = CLLocationCoordinate2D(
                latitude: clampedLat,
                longitude: clampedLon
            )

            // Update camera position to clamped coordinate
            let clampedCamera = MapCamera(
                centerCoordinate: clampedCoord,
                distance: zoomLevel,
                heading: currentHeading,
                pitch: 60
            )

            cameraPosition = .camera(clampedCamera)
            currentCameraCoordinate = clampedCoord
        }
    }

    func updateCameraTracking(_ position: MapCameraPosition) {
        // Note: Pattern matching on MapCameraPosition causes compiler errors
        // We track coordinates manually in zoom/pan functions instead
    }

    // MARK: - Map View Controls

    func returnToLandmark() {
        guard let landmark = landmarkCoordinate else { return }

        currentCameraCoordinate = landmark
        zoomLevel = 2000

        let camera = MapCamera(
            centerCoordinate: landmark,
            distance: zoomLevel,
            heading: currentHeading,
            pitch: 60
        )

        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .camera(camera)
        }
    }

    func zoomIn() {
        guard let coordinate = currentCameraCoordinate else { return }

        zoomLevel = max(minZoom, zoomLevel - 500)

        let camera = MapCamera(
            centerCoordinate: coordinate,
            distance: zoomLevel,
            heading: currentHeading,
            pitch: 60
        )

        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .camera(camera)
        }
    }

    func zoomOut() {
        guard let coordinate = currentCameraCoordinate else { return }

        zoomLevel = min(maxZoom, zoomLevel + 500)

        let camera = MapCamera(
            centerCoordinate: coordinate,
            distance: zoomLevel,
            heading: currentHeading,
            pitch: 60
        )

        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .camera(camera)
        }
    }

    func updateCameraHeading(_ heading: Double) {
        currentHeading = heading

        guard isOrbiting, let mapRegion = gameData.mapRegion else { return }

        let distance: Double = gameState.phase == .phase1Location ? 3000 : 8000
        let pitch: Double = gameState.phase == .phase1Location ? 60 : 60

        let updatedCamera = mapRegion.updatedCamera(
            heading: heading,
            distance: distance,
            pitch: pitch
        )

        cameraPosition = .camera(updatedCamera)
    }
}
