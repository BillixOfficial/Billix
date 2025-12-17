//
//  SeasonLocation.swift
//  Billix
//
//  Created by Claude Code
//

import Foundation
import CoreLocation

struct SeasonLocation: Identifiable, Codable, Hashable {
    let id: UUID
    let seasonPartId: UUID
    let locationNumber: Int
    let subject: String
    let locationName: String
    let category: String
    let difficulty: String
    let locationData: LocationDataJSON
    let priceData: PriceDataJSON
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case seasonPartId = "season_part_id"
        case locationNumber = "location_number"
        case subject
        case locationName = "location_name"
        case category
        case difficulty
        case locationData = "location_data"
        case priceData = "price_data"
        case createdAt = "created_at"
    }
}

// MARK: - Location Data JSONB Structure
struct LocationDataJSON: Codable, Hashable {
    let landmarkName: String
    let coordinates: CoordinateData
    let landmark: CoordinateData
    let mapRegion: MapRegionDataJSON
    let decoyLocations: [DecoyLocationJSON]

    enum CodingKeys: String, CodingKey {
        case landmarkName = "landmark_name"
        case coordinates
        case landmark
        case mapRegion
        case decoyLocations
    }
}

// JSONB storage format (matches database)
struct CoordinateData: Codable, Hashable {
    let lat: Double
    let lng: Double

    // Convert to LocationCoordinate for game
    func toLocationCoordinate() -> LocationCoordinate {
        LocationCoordinate(latitude: lat, longitude: lng)
    }
}

// JSONB storage format (matches database)
struct MapRegionDataJSON: Codable, Hashable {
    let pitch: Double
    let heading: Double
    let altitude: Double

    // Convert to MapRegionData for game
    func toMapRegionData(coordinates: CoordinateData) -> MapRegionData {
        MapRegionData(
            centerLatitude: coordinates.lat,
            centerLongitude: coordinates.lng,
            pitch: pitch,
            heading: heading
        )
    }
}

// JSONB storage format (matches database)
struct DecoyLocationJSON: Codable, Hashable {
    let id: String
    let displayLabel: String
    let name: String
    let isCorrect: Bool

    // Convert to DecoyLocation for game
    func toDecoyLocation() -> DecoyLocation {
        DecoyLocation(
            id: UUID(), // Generate new UUID
            name: name,
            displayLabel: displayLabel
        )
    }
}

// MARK: - Price Data JSONB Structure
struct PriceDataJSON: Codable, Hashable {
    let questions: [PriceQuestion]
}

struct PriceQuestion: Codable, Hashable, Identifiable {
    var id: String { question } // Use question text as ID
    let type: String // "slider"
    let question: String
    let actualPrice: Double
    let minGuess: Double
    let maxGuess: Double
    let unit: String

    enum CodingKeys: String, CodingKey {
        case type
        case question
        case actualPrice
        case minGuess
        case maxGuess
        case unit
    }
}

// MARK: - Conversion to GameQuestion
extension SeasonLocation {
    /// Converts a SeasonLocation to a GameQuestion for use in the existing game engine
    func toGameQuestions() -> [GameQuestion] {
        var questions: [GameQuestion] = []

        // Convert map region data
        let mapRegionConverted = locationData.mapRegion.toMapRegionData(coordinates: locationData.coordinates)

        // Convert decoy locations
        let decoyLocationsConverted = locationData.decoyLocations.map { $0.toDecoyLocation() }

        // Question 1: Location identification (Phase 1)
        let locationQuestion = GameQuestion(
            id: UUID(),
            subject: subject,
            location: locationName,
            category: GameCategory(rawValue: category) ?? .grocery,
            difficulty: QuestionDifficulty(rawValue: difficulty) ?? .moderate,
            coordinates: locationData.coordinates.toLocationCoordinate(),
            mapRegion: mapRegionConverted,
            landmarkCoordinate: locationData.landmark.toLocationCoordinate(),
            decoyLocations: decoyLocationsConverted,
            actualPrice: 0, // Not used for location question
            minGuess: 0,
            maxGuess: 0,
            unit: "",
            economicContext: nil
        )
        questions.append(locationQuestion)

        // Questions 2 & 3: Price questions (Phase 2)
        for priceQ in priceData.questions {
            let priceQuestion = GameQuestion(
                id: UUID(),
                subject: priceQ.question,
                location: locationName,
                category: GameCategory(rawValue: category) ?? .grocery,
                difficulty: QuestionDifficulty(rawValue: difficulty) ?? .moderate,
                coordinates: locationData.coordinates.toLocationCoordinate(),
                mapRegion: mapRegionConverted,
                landmarkCoordinate: locationData.landmark.toLocationCoordinate(),
                decoyLocations: [], // No decoys for price questions
                actualPrice: priceQ.actualPrice,
                minGuess: priceQ.minGuess,
                maxGuess: priceQ.maxGuess,
                unit: priceQ.unit,
                economicContext: nil
            )
            questions.append(priceQuestion)
        }

        return questions
    }
}

// MARK: - GameCategory Extension
extension GameCategory {
    init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "grocery": self = .grocery
        case "utilities", "utility": self = .utility
        case "rent": self = .rent
        case "subscription": self = .subscription
        case "gas": self = .gas
        case "urban", "island": self = .grocery // Default to grocery for urban/island
        default: self = .grocery
        }
    }
}

// MARK: - QuestionDifficulty Extension
extension QuestionDifficulty {
    init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "easy": self = .easy
        case "moderate": self = .moderate
        case "hard": self = .hard
        default: self = .moderate
        }
    }
}
