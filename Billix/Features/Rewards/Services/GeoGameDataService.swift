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
                DecoyLocation(name: "Jersey City, NJ", displayLabel: "C"),
                DecoyLocation(name: "Boston, MA", displayLabel: "D")
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
}
