//
//  LocationModels.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  Location models for Explore marketplace
//

import Foundation

/// Represents a metro area location for marketplace data
struct Location: Codable, Equatable, Hashable {
    let metro: String        // "Metro Detroit"
    let city: String         // "Detroit"
    let state: String        // "MI"
    let zipPrefix: String    // "482" (first 3 digits)

    var displayName: String {
        metro
    }

    var fullName: String {
        "\(city), \(state)"
    }
}

// MARK: - Mock Locations

extension Location {
    /// Mock locations for UI testing
    static let mockLocations: [Location] = [
        Location(metro: "Metro Detroit", city: "Detroit", state: "MI", zipPrefix: "482"),
        Location(metro: "San Francisco Bay Area", city: "San Francisco", state: "CA", zipPrefix: "941"),
        Location(metro: "Greater Chicago", city: "Chicago", state: "IL", zipPrefix: "606"),
        Location(metro: "Metro Atlanta", city: "Atlanta", state: "GA", zipPrefix: "303"),
        Location(metro: "Greater Seattle", city: "Seattle", state: "WA", zipPrefix: "981"),
        Location(metro: "Metro Phoenix", city: "Phoenix", state: "AZ", zipPrefix: "850"),
        Location(metro: "Greater Boston", city: "Boston", state: "MA", zipPrefix: "021"),
        Location(metro: "Metro Denver", city: "Denver", state: "CO", zipPrefix: "802")
    ]

    static let defaultLocation = mockLocations[0] // Metro Detroit
}
