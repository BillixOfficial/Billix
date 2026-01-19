//
//  HousingMockData.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Mock data generators for property search feature
//

import Foundation
import MapKit

struct HousingMockData {

    // MARK: - Mock Addresses

    private static let mockAddresses = [
        "418 N Center St, Royal Oak, MI 48067",
        "435 N Washington Ave, Royal Oak, MI 48067",
        "526 N Washington Ave, Royal Oak, MI 48067",
        "601 N Main St, Royal Oak, MI 48067",
        "312 E 4th St, Royal Oak, MI 48067",
        "1245 Woodward Ave, Royal Oak, MI 48067",
        "789 Pleasant St, Royal Oak, MI 48067",
        "234 Lincoln Ave, Royal Oak, MI 48067",
        "567 11 Mile Rd, Royal Oak, MI 48067",
        "890 Crooks Rd, Royal Oak, MI 48067",
        "123 Coolidge Hwy, Royal Oak, MI 48067",
        "456 Campbell Rd, Royal Oak, MI 48067"
    ]

    // MARK: - Generate Rent Estimate

    static func generateRentEstimate(params: PropertySearchParams) -> RentEstimateResult {
        // Calculate base rent based on bedrooms
        let baseBedrooms = params.bedrooms ?? 2
        var baseRent = 1650.0 + (Double(baseBedrooms - 1) * 350.0)

        // Adjust for square footage if provided
        if let sqft = params.squareFeet {
            let sqftFactor = Double(sqft) / 950.0
            baseRent *= sqftFactor
        }

        // Adjust for property type
        switch params.propertyType {
        case .singleFamily:
            baseRent *= 1.15
        case .condo:
            baseRent *= 1.05
        case .townhouse:
            baseRent *= 1.10
        case .manufactured:
            baseRent *= 0.85
        case .multiFamily:
            baseRent *= 1.12
        case .apartment, .all:
            break
        }

        // Add some randomness (±5%)
        let randomFactor = Double.random(in: 0.95...1.05)
        baseRent *= randomFactor

        let lowEstimate = baseRent * 0.85
        let highEstimate = baseRent * 1.15

        let sqftValue = params.squareFeet ?? 950
        let perSqft = baseRent / Double(sqftValue)
        let perBedroom = baseRent / Double(baseBedrooms)

        // Determine confidence based on sample size
        let confidence: String
        let comparablesCount = Int.random(in: 8...15)
        if comparablesCount >= 12 {
            confidence = "High"
        } else if comparablesCount >= 10 {
            confidence = "Medium"
        } else {
            confidence = "Low"
        }

        return RentEstimateResult(
            estimatedRent: baseRent,
            lowEstimate: lowEstimate,
            highEstimate: highEstimate,
            perSqft: perSqft,
            perBedroom: perBedroom,
            confidence: confidence,
            comparablesCount: comparablesCount
        )
    }

    // MARK: - Generate Comparable Properties

    static func generateComparables(
        params: PropertySearchParams,
        estimate: RentEstimateResult
    ) -> [RentalComparable] {
        var comparables: [RentalComparable] = []

        for i in 0..<estimate.comparablesCount {
            // Generate rent within ±20% of estimate
            let rentVariation = Double.random(in: 0.80...1.20)
            let rent = estimate.estimatedRent * rentVariation

            // Generate similarity score (95.0-99.9%, higher = closer match)
            let similarity = Double.random(in: 95.0...99.9)

            // Generate distance within search radius
            let distance = Double.random(in: 0.01...params.searchRadius)

            // Randomize bedrooms (mostly match, some variation)
            let baseBeds = params.bedrooms ?? 2
            let bedrooms: Int
            if Double.random(in: 0...1) > 0.7 {
                bedrooms = max(1, baseBeds + Int.random(in: -1...1))
            } else {
                bedrooms = baseBeds
            }

            // Randomize bathrooms
            let bathrooms = Double([1.0, 1.5, 2.0, 2.5, 3.0].randomElement() ?? 1.5)

            // Generate sqft if params had it
            let sqft: Int?
            if let paramSqft = params.squareFeet {
                sqft = paramSqft + Int.random(in: -200...200)
            } else {
                sqft = Int.random(in: 650...1500)
            }

            // Randomize property type (mostly match params)
            let propertyType: PropertyType
            if params.propertyType == .all {
                propertyType = PropertyType.allCases.filter { $0 != .all }.randomElement() ?? .apartment
            } else {
                propertyType = Double.random(in: 0...1) > 0.8 ?
                    PropertyType.allCases.filter { $0 != .all }.randomElement() ?? params.propertyType :
                    params.propertyType
            }

            // Generate last seen date (within lookback period)
            let daysAgo = Int.random(in: 1...params.lookbackDays)
            let lastSeen = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

            // Generate coordinate
            let coordinate = generateMockCoordinate(radiusMiles: params.searchRadius)

            let comparable = RentalComparable(
                id: "comp_\(i)",
                address: mockAddresses[i % mockAddresses.count],
                rent: rent,
                lastSeen: lastSeen,
                similarity: similarity,
                distance: distance,
                bedrooms: bedrooms,
                bathrooms: bathrooms,
                sqft: sqft,
                propertyType: propertyType,
                coordinate: coordinate,
                yearBuilt: Int.random(in: 1960...2023),
                lotSize: Int.random(in: 2000...10000),
                status: Bool.random() ? "Active" : "Inactive"
            )

            comparables.append(comparable)
        }

        // Sort by similarity (descending) by default
        return comparables.sorted { $0.similarity > $1.similarity }
    }

    // MARK: - Generate Map Coordinates

    static func generateMockCoordinate(radiusMiles: Double) -> CLLocationCoordinate2D {
        // Detroit base coordinates: 42.3314, -83.0458
        let baseLat = 42.3314
        let baseLng = -83.0458

        // ~1 mile = 0.0145 degrees latitude/longitude
        let offset = radiusMiles * 0.0145

        let lat = baseLat + Double.random(in: -offset...offset)
        let lng = baseLng + Double.random(in: -offset...offset)

        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    // MARK: - Generate Searched Property Marker

    static func generateSearchedPropertyMarker(params: PropertySearchParams) -> PropertyMarker {
        // Use base coordinates for searched property
        return PropertyMarker(
            id: "searched_property",
            coordinate: CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458),
            isSearchedProperty: true,
            isActive: true
        )
    }

    // MARK: - Generate Comparable Markers

    static func generateComparableMarkers(comparables: [RentalComparable]) -> [PropertyMarker] {
        comparables.map { comp in
            PropertyMarker(
                id: comp.id,
                coordinate: comp.coordinate,
                isSearchedProperty: false,
                isActive: comp.isActive
            )
        }
    }
}
