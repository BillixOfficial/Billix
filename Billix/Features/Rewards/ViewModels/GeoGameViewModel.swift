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

    // MARK: - Game Session Data

    @Published var session: GameSession

    // MARK: - Published State

    @Published var gameState: GameState
    @Published var locationChoices: [DecoyLocation]
    @Published var selectedChoice: String?
    @Published var sliderValue: Double = 0.5  // 0.0 to 1.0
    @Published var isDraggingSlider: Bool = false  // Track slider dragging for scale animation
    @Published var cameraPosition: MapCameraPosition
    @Published var isOrbiting: Bool = false
    @Published var currentHeading: Double = 0
    @Published var showResult: Bool = false
    @Published var currentMapView: MapViewType = .landmark
    @Published var zoomLevel: Double = 2000  // Camera distance in meters (default zoom)
    @Published var currentCameraCoordinate: CLLocationCoordinate2D?

    // Question tracking for current question
    @Published var questionPhase: QuestionPhase = .loading

    // Heart loss animation
    @Published var showHeartLostAnimation: Bool = false

    // MARK: - Power-Ups System

    @Published var revealedWrongChoices: Set<String> = []  // For hint token
    @Published var showPowerUpFeedback: PowerUpType? = nil  // Show activation feedback

    // MARK: - Timer System

    @Published var timeRemaining: Double = 0
    @Published var displayTimeRemaining: Int = 0  // Stable integer for display (prevents flickering)
    @Published var isTimerCritical: Bool = false  // True when <= 5 seconds (for pulse animation)
    @Published var isTimerActive: Bool = false
    private var timer: Timer?
    private var timerEndDate: Date?

    // Timer configuration (in seconds)
    private let phase1TimeLimit: Double = 35  // Location identification
    private let phase2TimeLimit: Double = 18  // Price estimation

    // Landmark coordinate for "return to landmark" feature
    private var landmarkCoordinate: CLLocationCoordinate2D?
    private var regionCoordinate: CLLocationCoordinate2D?

    // Pan boundaries (1 mile radius = ~0.015 degrees = ~1600m)
    private var panBoundaryRadius: Double = 0.015  // ~1 mile from landmark

    // MARK: - Computed Properties

    var currentQuestion: GameQuestion? {
        session.currentQuestion
    }

    var isLocationQuestion: Bool {
        guard let question = currentQuestion else { return false }
        return GeoGameDataService.isLocationQuestion(question)
    }

    var isPriceQuestion: Bool {
        guard let question = currentQuestion else { return false }
        return GeoGameDataService.isPriceQuestion(question)
    }

    var currentGuess: Double {
        guard let question = currentQuestion else { return 0 }
        let range = question.maxGuess - question.minGuess
        return question.minGuess + (sliderValue * range)
    }

    var formattedGuess: String {
        guard let question = currentQuestion else { return "$0.00" }
        if question.category == .rent || question.category == .utility {
            return String(format: "$%.0f", currentGuess)
        } else {
            return String(format: "$%.2f", currentGuess)
        }
    }

    var correctLocationName: String {
        currentQuestion?.location ?? ""
    }

    var accuracyDescription: String? {
        guard gameState.phase == .result,
              let guess = gameState.priceGuess,
              let question = currentQuestion else { return nil }
        return GeoGameScoring.accuracyTier(guess: guess, actual: question.actualPrice)
    }

    var progressText: String {
        "Question \(session.currentQuestionIndex + 1) of \(session.questions.count)"
    }

    /// Current location number (1-4) based on question groups of 3
    var currentLocationNumber: Int {
        guard session.currentQuestionIndex < session.questions.count else {
            return 4  // Default to last location if out of bounds
        }
        // Use session's currentLandmarkIndex for consistency
        return min(session.currentLandmarkIndex + 1, 4)  // 1-based, capped at 4
    }

    /// Progress text showing location instead of question number
    var locationProgressText: String {
        "Location \(currentLocationNumber) of 4"
    }

    /// Check if user lost health on the price question (for styling)
    var didLoseHealthOnPrice: Bool {
        guard let guess = gameState.priceGuess,
              let question = currentQuestion else { return false }
        let percentOff = abs(guess - question.actualPrice) / question.actualPrice
        return percentOff > 0.25
    }

    var healthText: String {
        String(repeating: "❤️", count: session.health) + String(repeating: "🖤", count: max(0, 3 - session.health))
    }

    // MARK: - Timer Computed Properties

    var timerProgress: Double {
        guard isTimerActive else { return 1.0 }
        let totalTime = questionPhase == .phase1Location ? phase1TimeLimit : phase2TimeLimit
        return timeRemaining / totalTime
    }

    var timerColor: Color {
        if timeRemaining > 10 {
            return .billixMoneyGreen
        } else if timeRemaining > 5 {
            return .orange
        } else {
            return .red
        }
    }

    var shouldPulseTimer: Bool {
        timeRemaining <= 5
    }

    var formattedTimeRemaining: String {
        let seconds = Int(ceil(timeRemaining))
        return "\(seconds)s"
    }

    // MARK: - Callbacks

    var onGameComplete: ((GameResult) -> Void)?
    var onPlayAgain: (() -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - Initialization

    init(session: GameSession = GeoGameDataService.generateGameSession(), onComplete: ((GameResult) -> Void)? = nil) {
        self.session = session
        self.onGameComplete = onComplete

        // Initialize game state
        self.gameState = GameState()

        // Initialize for first question
        if let firstQuestion = session.currentQuestion {
            self.locationChoices = firstQuestion.decoyLocations

            // Store landmark and region coordinates for boundaries and navigation
            self.landmarkCoordinate = CLLocationCoordinate2D(
                latitude: firstQuestion.landmarkCoordinate.latitude,
                longitude: firstQuestion.landmarkCoordinate.longitude
            )
            self.regionCoordinate = CLLocationCoordinate2D(
                latitude: firstQuestion.mapRegion.centerLatitude,
                longitude: firstQuestion.mapRegion.centerLongitude
            )

            // Initialize camera position for exploration
            let coord = CLLocationCoordinate2D(
                latitude: firstQuestion.landmarkCoordinate.latitude,
                longitude: firstQuestion.landmarkCoordinate.longitude
            )
            let landmarkCamera = MapCamera(
                centerCoordinate: coord,
                distance: 2000,
                heading: 0,
                pitch: 60
            )
            self.cameraPosition = .camera(landmarkCamera)
            self.currentCameraCoordinate = coord
        } else {
            self.locationChoices = []
            self.cameraPosition = .automatic
        }

        // Start the game
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startCurrentQuestion()
        }
    }

    // Legacy init for backward compatibility with old DailyGame structure
    convenience init(gameData: DailyGame, onComplete: ((GameResult) -> Void)? = nil) {
        // Create a single-question session from the old DailyGame
        // Provide defaults for optional geo-game fields
        let coords = gameData.coordinates ?? LocationCoordinate(latitude: 0, longitude: 0)
        let region = gameData.mapRegion ?? MapRegionData(centerLatitude: 0, centerLongitude: 0, pitch: 0, heading: 0)
        let landmark = gameData.landmarkCoordinate ?? coords

        let question = GameQuestion(
            subject: gameData.subject,
            location: gameData.location,
            category: gameData.category,
            difficulty: .moderate,
            coordinates: coords,
            mapRegion: region,
            landmarkCoordinate: landmark,
            decoyLocations: gameData.decoyLocations ?? [],
            actualPrice: gameData.actualPrice,
            minGuess: gameData.minGuess,
            maxGuess: gameData.maxGuess,
            unit: gameData.unit,
            economicContext: gameData.economicContext
        )

        let session = GameSession(
            questions: [question],
            health: 3,
            totalPoints: 0,
            questionsCorrect: 0
        )

        self.init(session: session, onComplete: onComplete)
    }

    // MARK: - Timer Methods

    func startTimer(for phase: QuestionPhase) {
        // Stop any existing timer
        stopTimer()

        // Determine time limit based on phase
        let timeLimit = phase == .phase1Location ? phase1TimeLimit : phase2TimeLimit

        // Set timer properties using Date-based calculation for accuracy
        timeRemaining = timeLimit
        displayTimeRemaining = Int(ceil(timeLimit))
        isTimerCritical = false  // Initialize as not critical
        timerEndDate = Date().addingTimeInterval(timeLimit)
        isTimerActive = true

        // Create timer that fires every 0.1 seconds for smooth animation
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.updateTimer()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerEndDate = nil
        isTimerActive = false
    }

    private func updateTimer() {
        guard let endDate = timerEndDate else {
            stopTimer()
            return
        }

        // Calculate remaining time using Date for accuracy (prevents jitter)
        let remaining = endDate.timeIntervalSinceNow

        if remaining <= 0 {
            // Time's up!
            stopTimer()
            timeRemaining = 0
            displayTimeRemaining = 0
            isTimerCritical = false
            autoSubmitDueToTimeout()
        } else {
            timeRemaining = remaining

            // Update display time only when integer value changes (prevents flickering)
            let newDisplayTime = Int(ceil(remaining))
            if newDisplayTime != displayTimeRemaining {
                displayTimeRemaining = newDisplayTime

                // Update critical state when crossing 5-second threshold
                if newDisplayTime <= 5 && !isTimerCritical {
                    isTimerCritical = true
                } else if newDisplayTime > 5 && isTimerCritical {
                    isTimerCritical = false
                }

                // Play sound effects at 10s and 5s warnings
                if displayTimeRemaining == 10 || displayTimeRemaining == 5 {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                }
            }
        }
    }

    func addTime(_ seconds: Double) {
        guard let endDate = timerEndDate, isTimerActive else { return }

        // Extend the timer by adding seconds to end date
        timerEndDate = endDate.addingTimeInterval(seconds)
        timeRemaining = timerEndDate!.timeIntervalSinceNow

        // Haptic feedback for time added
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    private func autoSubmitDueToTimeout() {
        if questionPhase == .phase1Location {
            if selectedChoice == nil {
                // No selection made = automatic wrong answer
                handleTimeoutFailure(phase: .phase1Location)
            } else {
                // User made a selection, score it normally
                submitLocationGuess()
            }
        } else if questionPhase == .phase2Price {
            // Submit current slider position (score it normally)
            submitPriceGuess()
        }
    }

    private func handleTimeoutFailure(phase: QuestionPhase) {
        // Common timeout failure logic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)

        // Update session state
        session.health -= 1

        // Trigger heart loss animation
        triggerHeartLossAnimation()

        // Update game state based on phase
        if phase == .phase1Location {
            gameState.isLocationCorrect = false
            gameState.phase1Points = 0
            gameState.phase = .transition  // CRITICAL: Transition to feedback view
            session.landmarksAttempted += 1

            // Show feedback
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                questionPhase = .phase1Feedback
            }
        } else if phase == .phase2Price {
            gameState.priceGuess = currentGuess  // For display only
            gameState.phase2Points = 0
            session.pricesAttempted += 1

            // Show feedback
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                gameState.phase = .result
                questionPhase = .phase2Feedback
                showResult = true
            }
        }

        // Check game over
        if session.health <= 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.questionPhase = .gameOver
                self.endGame()
            }
        }
    }

    // MARK: - Power-Ups System

    func usePowerUp(_ type: PowerUpType) {
        guard session.powerUps.use(type) else {
            // Not enough power-ups
            return
        }

        // Show feedback animation
        showPowerUpFeedback = type

        // Apply power-up effect
        switch type {
        case .extraLife:
            activateExtraLife()

        case .skipQuestion:
            activateSkipQuestion()

        case .timeFreeze:
            activateTimeFreeze()

        case .hintToken:
            activateHintToken()
        }

        // Hide feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showPowerUpFeedback = nil
        }
    }

    private func activateExtraLife() {
        // Add one heart (max 3)
        session.health = min(session.health + 1, 3)

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func activateSkipQuestion() {
        // Stop timer
        stopTimer()

        // Award minimum points to avoid penalizing skip
        let skipPoints = 5
        session.totalPoints += skipPoints

        // Advance to next question without breaking combo
        advanceToNextQuestion()

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func activateTimeFreeze() {
        // Add 15 seconds to timer
        addTime(15)

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    private func activateHintToken() {
        // Only works in Phase 1 (location)
        guard questionPhase == .phase1Location,
              let question = currentQuestion else { return }

        // Find one wrong answer that hasn't been revealed yet
        let correctChoice = locationChoices.first { $0.name == question.location }
        let wrongChoices = locationChoices.filter {
            $0.displayLabel != correctChoice?.displayLabel &&
            !revealedWrongChoices.contains($0.displayLabel)
        }

        if let wrongChoice = wrongChoices.randomElement() {
            revealedWrongChoices.insert(wrongChoice.displayLabel)
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func dismissPowerUpFeedback() {
        showPowerUpFeedback = nil
    }

    // MARK: - Question Flow

    func startCurrentQuestion() {
        guard let question = currentQuestion else {
            // No more questions - end game
            endGame()
            return
        }

        // Reset state for new question
        selectedChoice = nil
        sliderValue = 0.5
        gameState = GameState()
        revealedWrongChoices.removeAll()  // Clear hints for new question

        // Update camera and choices based on question type
        if isLocationQuestion {
            locationChoices = question.decoyLocations
            questionPhase = .phase1Location
            gameState.phase = .phase1Location

            // Start timer for Phase 1
            startTimer(for: .phase1Location)
        } else if isPriceQuestion {
            locationChoices = []
            questionPhase = .phase2Price
            gameState.phase = .phase2Price

            // Start timer for Phase 2
            startTimer(for: .phase2Price)
        }

        // Update camera position for new question
        updateCameraForCurrentQuestion()
    }

    func updateCameraForCurrentQuestion() {
        guard let question = currentQuestion else { return }

        // Update landmarks
        landmarkCoordinate = CLLocationCoordinate2D(
            latitude: question.landmarkCoordinate.latitude,
            longitude: question.landmarkCoordinate.longitude
        )
        regionCoordinate = CLLocationCoordinate2D(
            latitude: question.mapRegion.centerLatitude,
            longitude: question.mapRegion.centerLongitude
        )

        // Set camera
        let coord = CLLocationCoordinate2D(
            latitude: question.landmarkCoordinate.latitude,
            longitude: question.landmarkCoordinate.longitude
        )
        let camera = MapCamera(
            centerCoordinate: coord,
            distance: 2000,
            heading: 0,
            pitch: 60
        )

        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .camera(camera)
            currentCameraCoordinate = coord
        }
    }

    func advanceToNextQuestion() {
        session.currentQuestionIndex += 1

        if session.isGameOver {
            questionPhase = .gameOver
            endGame()
        } else {
            startCurrentQuestion()
        }
    }

    // MARK: - Phase 1: Location Selection

    func selectLocation(_ label: String) {
        selectedChoice = label
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func submitLocationGuess() {
        guard let selected = selectedChoice,
              let question = currentQuestion else { return }

        // Stop the timer
        stopTimer()

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Track landmark attempt
        session.landmarksAttempted += 1

        // Find the correct answer
        let correctChoice = locationChoices.first { $0.name == question.location }
        let isCorrect = correctChoice?.displayLabel == selected

        gameState.isLocationCorrect = isCorrect
        gameState.selectedLocation = selected

        // Clear selection immediately to hide submit button
        selectedChoice = nil

        if isCorrect {
            // Award points with difficulty and combo multipliers
            let points = GeoGameScoring.calculatePhase1Points(
                correct: true,
                isRetry: gameState.isRetryAttempt
            )
            gameState.phase1Points = points

            // Update session
            session.totalPoints += points
            session.questionsCorrect += 1  // Keep for backwards compatibility
            session.landmarksCorrect += 1  // New: Track landmarks separately

            // Show success feedback
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                gameState.phase = .transition
                questionPhase = .phase1Feedback
            }
            // User will manually press Continue button to advance
        } else {
            // Wrong answer - lose health
            session.health -= 1
            gameState.phase1Points = 0
            gameState.incorrectChoice = selected

            // Trigger heart loss animation
            triggerHeartLossAnimation()

            // Set phase for feedback display (use .transition for consistency)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                gameState.phase = .transition
            }

            if session.health <= 0 {
                // Show feedback briefly before game over
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.questionPhase = .gameOver
                    self?.endGame()
                }
            }
            // User will manually press Continue button to advance (if health > 0)
        }
    }

    // Called when user clicks Continue button after wrong answer
    func continueAfterWrongAnswer() {
        // If they got a landmark question wrong, skip to the next landmark question
        // (skip the 2 price questions for this location)
        if !gameState.isLocationCorrect && isLocationQuestion {
            // Find the next landmark question
            var nextIndex = session.currentQuestionIndex + 1
            while nextIndex < session.questions.count {
                let nextQuestion = session.questions[nextIndex]
                if GeoGameDataService.isLocationQuestion(nextQuestion) {
                    // Found next landmark question
                    session.currentQuestionIndex = nextIndex
                    startCurrentQuestion()
                    return
                }
                nextIndex += 1
            }
            // No more landmark questions - end game
            endGame()
        } else {
            // Normal advance for price questions
            advanceToNextQuestion()
        }
    }

    // MARK: - Phase 2: Price Estimation

    func submitPriceGuess() {
        guard let question = currentQuestion else { return }

        // Stop the timer
        stopTimer()

        let guess = currentGuess
        gameState.priceGuess = guess

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Track price attempt
        session.pricesAttempted += 1

        // Calculate accuracy (unused but kept for potential future use)
        let _ = 1.0 - (abs(guess - question.actualPrice) / question.actualPrice)

        // Calculate points based on price accuracy
        let points = GeoGameScoring.calculatePhase2Points(
            guess: guess,
            actual: question.actualPrice
        )
        gameState.phase2Points = points

        // Update session
        session.totalPoints += points

        // Determine if answer was good enough to maintain combo and avoid health loss
        let percentOff = abs(guess - question.actualPrice) / question.actualPrice

        if percentOff <= 0.25 {
            // Within 25% tolerance - counts as safe/correct
            session.questionsCorrect += 1  // Keep for backwards compatibility
            session.pricesCorrect += 1     // New: Track prices separately
        } else {
            // Way off (>25%) - lose health
            session.health -= 1

            // Trigger heart loss animation
            triggerHeartLossAnimation()
        }

        // Show result feedback
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            gameState.phase = .result
            questionPhase = .phase2Feedback
            showResult = true
        }

        // Check game over
        if session.health <= 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.questionPhase = .gameOver
                self?.endGame()
            }
        }
        // User will manually press Continue button to advance (if health > 0)
    }

    // MARK: - Game Completion

    func completeGame() {
        // Calculate overall accuracy
        let accuracy = session.questions.isEmpty ? 0.0 : Double(session.questionsCorrect) / Double(session.questions.count)

        // Create a game result (using first question's ID as gameId for now)
        let result = GameResult(
            id: UUID(),
            gameId: session.questions.first?.id ?? UUID(),
            userGuess: gameState.priceGuess ?? 0,
            actualPrice: currentQuestion?.actualPrice ?? 0,
            pointsEarned: session.totalPoints,
            accuracy: accuracy,
            playedAt: Date()
        )

        onGameComplete?(result)
        onDismiss?()
    }

    private func endGame() {
        questionPhase = .gameOver

        // Calculate overall accuracy
        let accuracy = session.questions.isEmpty ? 0.0 : Double(session.questionsCorrect) / Double(session.questions.count)

        // Create final game result
        let result = GameResult(
            id: session.id,
            gameId: session.questions.first?.id ?? UUID(),
            userGuess: 0,
            actualPrice: 0,
            pointsEarned: session.totalPoints,
            accuracy: accuracy,
            playedAt: Date()
        )

        onGameComplete?(result)
    }

    func resetGame() {
        // Stop any active timer
        stopTimer()

        // Create a new session
        session = GeoGameDataService.generateGameSession()
        gameState = GameState()
        selectedChoice = nil
        sliderValue = 0.5
        showResult = false
        currentHeading = 0
        isOrbiting = false
        questionPhase = .loading

        // Start the new game
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startCurrentQuestion()
        }
    }

    // Legacy method for backward compatibility
    func resetWithNewGame(_ newGame: DailyGame) {
        resetGame()
    }

    // MARK: - Map Exploration

    func enableExplorationMode() {
        // Disable orbit, allow user to pan/rotate
        isOrbiting = false

        // Set initial camera position with realistic elevation
        if let question = currentQuestion {
            let explorationCamera = question.mapRegion.updatedCamera(
                heading: 0,
                distance: 2000,
                pitch: 60
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

    func updateCameraHeading(_ heading: Double) {
        currentHeading = heading

        guard isOrbiting, let question = currentQuestion else { return }

        let distance: Double = gameState.phase == .phase1Location ? 3000 : 8000
        let pitch: Double = 60

        let updatedCamera = question.mapRegion.updatedCamera(
            heading: heading,
            distance: distance,
            pitch: pitch
        )

        cameraPosition = .camera(updatedCamera)
    }

    func adjustCameraForCardState(cardHeight: CGFloat, screenHeight: CGFloat) {
        guard let landmark = landmarkCoordinate else { return }

        // Calculate visible map height
        let topHUDHeight: CGFloat = 100  // Top HUD + padding
        _ = screenHeight - cardHeight - topHUDHeight  // visibleHeight for future use

        // For now, just ensure camera stays at current position
        // Future enhancement: Pan camera to keep landmark in visible area
        let camera = MapCamera(
            centerCoordinate: landmark,
            distance: zoomLevel,
            heading: currentHeading,
            pitch: 60
        )

        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .camera(camera)
        }
    }

    // MARK: - Heart Loss Animation

    private func triggerHeartLossAnimation() {
        showHeartLostAnimation = true
    }

    func dismissHeartLostAnimation() {
        showHeartLostAnimation = false
    }
}
