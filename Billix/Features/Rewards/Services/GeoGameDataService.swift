//
//  GeoGameDataService.swift
//  Billix
//
//  Created by Claude Code
//  Mock data service for Geo-Economic game prototyping
//

import Foundation

struct GeoGameDataService {

    // MARK: - Mock Games

    static let mockGames: [DailyGame] = [
        // Game 1: Grocery Run - Phoenix
        DailyGame(
            id: UUID(),
            subject: "Gallon of Milk",
            location: "Phoenix, AZ",
            locationCode: "85001",
            category: .grocery,
            actualPrice: 3.89,
            minGuess: 2.00,
            maxGuess: 7.00,
            unit: "gallon",
            expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            gameMode: .groceryRun,
            coordinates: LocationCoordinate(
                latitude: 33.4484,
                longitude: -112.0740
            ),
            mapRegion: MapRegionData(
                centerLatitude: 33.4484,
                centerLongitude: -112.0740,
                pitch: 45,
                heading: 0
            ),
            decoyLocations: [
                DecoyLocation(name: "Phoenix, AZ", displayLabel: "A"),
                DecoyLocation(name: "Los Angeles, CA", displayLabel: "B"),
                DecoyLocation(name: "Denver, CO", displayLabel: "C"),
                DecoyLocation(name: "Albuquerque, NM", displayLabel: "D")
            ],
            economicContext: "To live here, you need $52,000/year",
            landmarkCoordinate: LocationCoordinate(
                latitude: 33.466667,  // Desert Botanical Garden
                longitude: -112.070774
            )
        ),

        // Game 2: Grocery Run - Seattle
        DailyGame(
            id: UUID(),
            subject: "Pound of Ground Beef",
            location: "Seattle, WA",
            locationCode: "98101",
            category: .grocery,
            actualPrice: 6.49,
            minGuess: 3.00,
            maxGuess: 12.00,
            unit: "pound",
            expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            gameMode: .groceryRun,
            coordinates: LocationCoordinate(
                latitude: 47.6062,
                longitude: -122.3321
            ),
            mapRegion: MapRegionData(
                centerLatitude: 47.6062,
                centerLongitude: -122.3321,
                pitch: 50,
                heading: 45
            ),
            decoyLocations: [
                DecoyLocation(name: "Portland, OR", displayLabel: "A"),
                DecoyLocation(name: "Seattle, WA", displayLabel: "B"),
                DecoyLocation(name: "San Francisco, CA", displayLabel: "C"),
                DecoyLocation(name: "Vancouver, BC", displayLabel: "D")
            ],
            economicContext: "To live here, you need $78,000/year",
            landmarkCoordinate: LocationCoordinate(
                latitude: 47.6205,  // Space Needle
                longitude: -122.3493
            )
        ),

        // Game 3: Grocery Run - Chicago
        DailyGame(
            id: UUID(),
            subject: "Bag of Coffee (12 oz)",
            location: "Chicago, IL",
            locationCode: "60601",
            category: .grocery,
            actualPrice: 8.99,
            minGuess: 4.00,
            maxGuess: 15.00,
            unit: "bag",
            expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            gameMode: .groceryRun,
            coordinates: LocationCoordinate(
                latitude: 41.8781,
                longitude: -87.6298
            ),
            mapRegion: MapRegionData(
                centerLatitude: 41.8781,
                centerLongitude: -87.6298,
                pitch: 55,
                heading: 90
            ),
            decoyLocations: [
                DecoyLocation(name: "Milwaukee, WI", displayLabel: "A"),
                DecoyLocation(name: "Detroit, MI", displayLabel: "B"),
                DecoyLocation(name: "Chicago, IL", displayLabel: "C"),
                DecoyLocation(name: "Indianapolis, IN", displayLabel: "D")
            ],
            economicContext: "To live here, you need $65,000/year",
            landmarkCoordinate: LocationCoordinate(
                latitude: 41.8826,  // Cloud Gate "The Bean"
                longitude: -87.6233
            )
        ),

        // Game 4: Apartment Hunt - Manhattan
        DailyGame(
            id: UUID(),
            subject: "1-Bed Apartment (700 sq ft)",
            location: "Manhattan, NY",
            locationCode: "10001",
            category: .rent,
            actualPrice: 3850.0,
            minGuess: 2000.0,
            maxGuess: 6000.0,
            unit: "month",
            expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            gameMode: .apartmentHunt,
            coordinates: LocationCoordinate(
                latitude: 40.7580,
                longitude: -73.9855
            ),
            mapRegion: MapRegionData(
                centerLatitude: 40.7580,
                centerLongitude: -73.9855,
                pitch: 60,
                heading: 180
            ),
            decoyLocations: [
                DecoyLocation(name: "Manhattan, NY", displayLabel: "A"),
                DecoyLocation(name: "Brooklyn, NY", displayLabel: "B"),
                DecoyLocation(name: "Queens, NY", displayLabel: "C"),
                DecoyLocation(name: "The Bronx, NY", displayLabel: "D")
            ],
            economicContext: "To live here, you need $120,000/year",
            landmarkCoordinate: LocationCoordinate(
                latitude: 40.7484,  // Empire State Building
                longitude: -73.9857
            )
        ),

        // Game 5: Apartment Hunt - San Francisco
        DailyGame(
            id: UUID(),
            subject: "1-Bed Apartment (700 sq ft)",
            location: "San Francisco, CA",
            locationCode: "94102",
            category: .rent,
            actualPrice: 3200.0,
            minGuess: 1800.0,
            maxGuess: 5000.0,
            unit: "month",
            expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            gameMode: .apartmentHunt,
            coordinates: LocationCoordinate(
                latitude: 37.7749,
                longitude: -122.4194
            ),
            mapRegion: MapRegionData(
                centerLatitude: 37.7749,
                centerLongitude: -122.4194,
                pitch: 50,
                heading: 270
            ),
            decoyLocations: [
                DecoyLocation(name: "Oakland, CA", displayLabel: "A"),
                DecoyLocation(name: "San Jose, CA", displayLabel: "B"),
                DecoyLocation(name: "San Francisco, CA", displayLabel: "C"),
                DecoyLocation(name: "Sacramento, CA", displayLabel: "D")
            ],
            economicContext: "To live here, you need $110,000/year",
            landmarkCoordinate: LocationCoordinate(
                latitude: 37.8199,  // Golden Gate Bridge
                longitude: -122.4783
            )
        )
    ]

    // MARK: - Helper Methods

    /// Get a random mock game for testing
    static func getRandomGame() -> DailyGame {
        return mockGames.randomElement() ?? mockGames[0]
    }

    /// Get today's game (for now, returns a random one)
    static func getTodaysGame() -> DailyGame {
        // In production, this would fetch from API based on current date
        return getRandomGame()
    }

    /// Get game by category
    static func getGamesByCategory(_ category: GameCategory) -> [DailyGame] {
        return mockGames.filter { $0.category == category }
    }

    /// Get game by mode
    static func getGamesByMode(_ mode: GameMode) -> [DailyGame] {
        return mockGames.filter { $0.gameMode == mode }
    }

    // MARK: - Multi-Question Game Session

    /// Mock questions for the new 12-question game format
    /// Structure: 4 locations × 3 questions each
    /// Q1: Location identification, Q2-3: Cost items for that location
    static let mockQuestions: [GameQuestion] = [
        // LOCATION 1: PHOENIX, AZ - Questions 1-3
        // Q1: Location
        GameQuestion(
            subject: "Desert Landmark",
            location: "Phoenix, AZ",
            category: .grocery,
            difficulty: .easy,
            coordinates: LocationCoordinate(latitude: 33.4484, longitude: -112.0740),
            mapRegion: MapRegionData(centerLatitude: 33.4484, centerLongitude: -112.0740, pitch: 45, heading: 0),
            landmarkCoordinate: LocationCoordinate(latitude: 33.459965, longitude: -111.944751),
            decoyLocations: [
                DecoyLocation(name: "Phoenix, AZ", displayLabel: "A"),
                DecoyLocation(name: "Las Vegas, NV", displayLabel: "B"),
                DecoyLocation(name: "Tucson, AZ", displayLabel: "C"),
                DecoyLocation(name: "Albuquerque, NM", displayLabel: "D")
            ],
            actualPrice: 0,  // Not used for location questions
            minGuess: 0,
            maxGuess: 0,
            unit: "",
            economicContext: "To live here, you need $52,000/year"
        ),
        // Q2: Food cost
        GameQuestion(
            subject: "Gallon of Milk",
            location: "Phoenix, AZ",
            category: .grocery,
            difficulty: .easy,
            coordinates: LocationCoordinate(latitude: 33.4484, longitude: -112.0740),
            mapRegion: MapRegionData(centerLatitude: 33.4484, centerLongitude: -112.0740, pitch: 45, heading: 0),
            landmarkCoordinate: LocationCoordinate(latitude: 33.459965, longitude: -111.944751),
            decoyLocations: [],  // Not used for price questions
            actualPrice: 3.89,
            minGuess: 2.00,
            maxGuess: 7.00,
            unit: "gallon"
        ),
        // Q3: Transportation cost
        GameQuestion(
            subject: "Gallon of Gas",
            location: "Phoenix, AZ",
            category: .gas,
            difficulty: .easy,
            coordinates: LocationCoordinate(latitude: 33.4484, longitude: -112.0740),
            mapRegion: MapRegionData(centerLatitude: 33.4484, centerLongitude: -112.0740, pitch: 45, heading: 0),
            landmarkCoordinate: LocationCoordinate(latitude: 33.459965, longitude: -111.944751),
            decoyLocations: [],
            actualPrice: 3.45,
            minGuess: 2.50,
            maxGuess: 5.50,
            unit: "gallon"
        ),

        // LOCATION 2: SEATTLE, WA - Questions 4-6
        // Q4: Location
        GameQuestion(
            subject: "Pacific Northwest Landmark",
            location: "Seattle, WA",
            category: .grocery,
            difficulty: .moderate,
            coordinates: LocationCoordinate(latitude: 47.6062, longitude: -122.3321),
            mapRegion: MapRegionData(centerLatitude: 47.6062, centerLongitude: -122.3321, pitch: 50, heading: 45),
            landmarkCoordinate: LocationCoordinate(latitude: 47.6205, longitude: -122.3493),
            decoyLocations: [
                DecoyLocation(name: "Portland, OR", displayLabel: "A"),
                DecoyLocation(name: "Seattle, WA", displayLabel: "B"),
                DecoyLocation(name: "Vancouver, BC", displayLabel: "C"),
                DecoyLocation(name: "Tacoma, WA", displayLabel: "D")
            ],
            actualPrice: 0,
            minGuess: 0,
            maxGuess: 0,
            unit: "",
            economicContext: "To live here, you need $78,000/year"
        ),
        // Q5: Food cost
        GameQuestion(
            subject: "Pound of Ground Beef",
            location: "Seattle, WA",
            category: .grocery,
            difficulty: .moderate,
            coordinates: LocationCoordinate(latitude: 47.6062, longitude: -122.3321),
            mapRegion: MapRegionData(centerLatitude: 47.6062, centerLongitude: -122.3321, pitch: 50, heading: 45),
            landmarkCoordinate: LocationCoordinate(latitude: 47.6205, longitude: -122.3493),
            decoyLocations: [],
            actualPrice: 6.49,
            minGuess: 3.00,
            maxGuess: 12.00,
            unit: "pound"
        ),
        // Q6: Housing cost
        GameQuestion(
            subject: "Monthly Electric Bill (avg)",
            location: "Seattle, WA",
            category: .utility,
            difficulty: .moderate,
            coordinates: LocationCoordinate(latitude: 47.6062, longitude: -122.3321),
            mapRegion: MapRegionData(centerLatitude: 47.6062, centerLongitude: -122.3321, pitch: 50, heading: 45),
            landmarkCoordinate: LocationCoordinate(latitude: 47.6205, longitude: -122.3493),
            decoyLocations: [],
            actualPrice: 95.0,
            minGuess: 50.0,
            maxGuess: 200.0,
            unit: "month"
        ),

        // LOCATION 3: MANHATTAN, NY - Questions 7-9
        // Q7: Location
        GameQuestion(
            subject: "Iconic NYC Landmark",
            location: "Manhattan, NY",
            category: .rent,
            difficulty: .hard,
            coordinates: LocationCoordinate(latitude: 40.7580, longitude: -73.9855),
            mapRegion: MapRegionData(centerLatitude: 40.7580, centerLongitude: -73.9855, pitch: 60, heading: 180),
            landmarkCoordinate: LocationCoordinate(latitude: 40.7484, longitude: -73.9857),
            decoyLocations: [
                DecoyLocation(name: "Manhattan, NY", displayLabel: "A"),
                DecoyLocation(name: "Brooklyn, NY", displayLabel: "B"),
                DecoyLocation(name: "Jersey City, NJ", displayLabel: "C"),
                DecoyLocation(name: "Philadelphia, PA", displayLabel: "D")
            ],
            actualPrice: 0,
            minGuess: 0,
            maxGuess: 0,
            unit: "",
            economicContext: "To live here, you need $120,000/year"
        ),
        // Q8: Housing cost
        GameQuestion(
            subject: "1-Bed Apartment (700 sq ft)",
            location: "Manhattan, NY",
            category: .rent,
            difficulty: .hard,
            coordinates: LocationCoordinate(latitude: 40.7580, longitude: -73.9855),
            mapRegion: MapRegionData(centerLatitude: 40.7580, centerLongitude: -73.9855, pitch: 60, heading: 180),
            landmarkCoordinate: LocationCoordinate(latitude: 40.7484, longitude: -73.9857),
            decoyLocations: [],
            actualPrice: 3850.0,
            minGuess: 2000.0,
            maxGuess: 6000.0,
            unit: "month"
        ),
        // Q9: Food cost
        GameQuestion(
            subject: "Coffee (Starbucks Latte)",
            location: "Manhattan, NY",
            category: .grocery,
            difficulty: .hard,
            coordinates: LocationCoordinate(latitude: 40.7580, longitude: -73.9855),
            mapRegion: MapRegionData(centerLatitude: 40.7580, centerLongitude: -73.9855, pitch: 60, heading: 180),
            landmarkCoordinate: LocationCoordinate(latitude: 40.7484, longitude: -73.9857),
            decoyLocations: [],
            actualPrice: 5.75,
            minGuess: 3.00,
            maxGuess: 8.00,
            unit: "cup"
        ),

        // LOCATION 4: SAN FRANCISCO, CA - Questions 10-12
        // Q10: Location
        GameQuestion(
            subject: "Bay Area Landmark",
            location: "San Francisco, CA",
            category: .rent,
            difficulty: .hard,
            coordinates: LocationCoordinate(latitude: 37.7749, longitude: -122.4194),
            mapRegion: MapRegionData(centerLatitude: 37.7749, centerLongitude: -122.4194, pitch: 50, heading: 270),
            landmarkCoordinate: LocationCoordinate(latitude: 37.8199, longitude: -122.4783),
            decoyLocations: [
                DecoyLocation(name: "Oakland, CA", displayLabel: "A"),
                DecoyLocation(name: "San Jose, CA", displayLabel: "B"),
                DecoyLocation(name: "San Francisco, CA", displayLabel: "C"),
                DecoyLocation(name: "Los Angeles, CA", displayLabel: "D")
            ],
            actualPrice: 0,
            minGuess: 0,
            maxGuess: 0,
            unit: "",
            economicContext: "To live here, you need $110,000/year"
        ),
        // Q11: Transportation cost
        GameQuestion(
            subject: "Monthly Muni Pass",
            location: "San Francisco, CA",
            category: .subscription,
            difficulty: .hard,
            coordinates: LocationCoordinate(latitude: 37.7749, longitude: -122.4194),
            mapRegion: MapRegionData(centerLatitude: 37.7749, centerLongitude: -122.4194, pitch: 50, heading: 270),
            landmarkCoordinate: LocationCoordinate(latitude: 37.8199, longitude: -122.4783),
            decoyLocations: [],
            actualPrice: 81.0,
            minGuess: 40.0,
            maxGuess: 150.0,
            unit: "month"
        ),
        // Q12: Housing cost
        GameQuestion(
            subject: "1-Bed Apartment (700 sq ft)",
            location: "San Francisco, CA",
            category: .rent,
            difficulty: .hard,
            coordinates: LocationCoordinate(latitude: 37.7749, longitude: -122.4194),
            mapRegion: MapRegionData(centerLatitude: 37.7749, centerLongitude: -122.4194, pitch: 50, heading: 270),
            landmarkCoordinate: LocationCoordinate(latitude: 37.8199, longitude: -122.4783),
            decoyLocations: [],
            actualPrice: 3200.0,
            minGuess: 1800.0,
            maxGuess: 5000.0,
            unit: "month"
        )
    ]

    /// Generate a complete game session with 12 questions (4 locations × 3 questions each)
    static func generateGameSession() -> GameSession {
        // Group questions by location (every 3 questions = 1 location)
        // Q1-3: Location 1, Q4-6: Location 2, Q7-9: Location 3, Q10-12: Location 4
        let locationGroups = stride(from: 0, to: mockQuestions.count, by: 3).map { index in
            Array(mockQuestions[index..<min(index + 3, mockQuestions.count)])
        }

        // Randomize the order of location groups, not individual questions
        let shuffledGroups = locationGroups.shuffled()

        // Flatten back to a single array
        let shuffledQuestions = shuffledGroups.flatMap { $0 }

        return GameSession(
            id: UUID(),
            questions: shuffledQuestions,
            currentQuestionIndex: 0,
            health: 3,
            totalPoints: 0,
            questionsCorrect: 0,
            startedAt: Date()
        )
    }

    /// Helper to determine if a question is a location question
    static func isLocationQuestion(_ question: GameQuestion) -> Bool {
        return !question.decoyLocations.isEmpty
    }

    /// Helper to determine if a question is a price question
    static func isPriceQuestion(_ question: GameQuestion) -> Bool {
        return question.decoyLocations.isEmpty && question.actualPrice > 0
    }
}
