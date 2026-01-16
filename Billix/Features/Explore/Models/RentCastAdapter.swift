//
//  RentCastAdapter.swift
//  Billix
//
//  Created by Claude Code on 1/14/26.
//  Extensions to convert RentCast API responses to Billix models
//

import Foundation
import CoreLocation

// MARK: - Market Response Adapters

extension RentCastMarketResponse {
    func toMarketTrendsData(location: String) -> MarketTrendsData {
        guard let rentalData = self.rentalData else {
            // Return empty data if no rental info
            return MarketTrendsData(
                location: location,
                averageRent: 0,
                rentChange12Month: 0,
                lowRent: 0,
                highRent: 0,
                bedroomStats: [],
                lastUpdated: Date()
            )
        }

        return MarketTrendsData(
            location: location,
            averageRent: rentalData.averageRent,
            rentChange12Month: calculateYoYChange(history: rentalData.history),
            lowRent: rentalData.minRent,
            highRent: rentalData.maxRent,
            bedroomStats: rentalData.dataByBedrooms.map { $0.toBedroomStats() },
            lastUpdated: rentalData.lastUpdatedDate
        )
    }

    func toHistoryData() -> [RentHistoryPoint] {
        guard let rentalData = self.rentalData else { return [] }

        var points: [RentHistoryPoint] = []

        // Convert history dictionary to sorted array
        let sortedHistory = rentalData.history.sorted { $0.key < $1.key }

        for (_, historyEntry) in sortedHistory {
            // Add average rent point
            points.append(RentHistoryPoint(
                date: historyEntry.date,
                bedroomType: .average,
                rent: historyEntry.averageRent
            ))

            // Add bedroom-specific points
            if let bedroomData = historyEntry.dataByBedrooms {
                for bedroom in bedroomData {
                    let bedroomType = BedroomType.fromBedroomCount(bedroom.bedrooms)
                    points.append(RentHistoryPoint(
                        date: historyEntry.date,
                        bedroomType: bedroomType,
                        rent: bedroom.averageRent
                    ))
                }
            }
        }

        return points
    }

    private func calculateYoYChange(history: [String: HistoricalMarketData]) -> Double {
        // Get current and 12 months ago
        let sortedKeys = history.keys.sorted()
        guard sortedKeys.count >= 12 else { return 0 }

        let currentKey = sortedKeys[sortedKeys.count - 1]
        let yearAgoIndex = max(0, sortedKeys.count - 13)
        let yearAgoKey = sortedKeys[yearAgoIndex]

        guard let current = history[currentKey],
              let yearAgo = history[yearAgoKey] else { return 0 }

        guard yearAgo.averageRent > 0 else { return 0 }

        let change = ((current.averageRent - yearAgo.averageRent) / yearAgo.averageRent) * 100
        return change
    }
}

extension BedroomMarketData {
    func toBedroomStats() -> BedroomStats {
        BedroomStats(
            bedroomCount: self.bedrooms,
            averageRent: self.averageRent,
            rentChange: 0,  // RentCast doesn't provide per-bedroom change in market stats
            sampleSize: self.totalListings ?? 0
        )
    }
}

// MARK: - Rent Estimate Adapters

extension RentCastEstimateResponse {
    func toRentEstimateResult() -> RentEstimateResult {
        let sqft = subjectProperty?.squareFootage ?? comparables.first?.squareFootage ?? 1000
        let beds = subjectProperty?.bedrooms ?? comparables.first?.bedrooms ?? 2

        return RentEstimateResult(
            estimatedRent: self.rent,
            lowEstimate: self.rentRangeLow,
            highEstimate: self.rentRangeHigh,
            perSqft: self.rent / Double(sqft),
            perBedroom: self.rent / Double(max(beds, 1)),
            confidence: determineConfidence(comparables.count),
            comparablesCount: comparables.count
        )
    }

    private func determineConfidence(_ count: Int) -> String {
        if count >= 12 { return "High" }
        if count >= 8 { return "Medium" }
        return "Low"
    }
}

extension RentCastComparable {
    func toRentalComparable() -> RentalComparable {
        RentalComparable(
            id: self.id,
            address: self.formattedAddress,
            rent: Double(self.price),
            lastSeen: self.lastSeenDate,
            similarity: self.correlation * 100,  // 0-1 → 0-100%
            distance: self.distance,
            bedrooms: self.bedrooms,
            bathrooms: self.bathrooms ?? 1.0,
            sqft: self.squareFootage,
            propertyType: PropertyType.fromRentCastString(self.propertyType),
            coordinate: CLLocationCoordinate2D(
                latitude: self.latitude,
                longitude: self.longitude
            ),
            yearBuilt: self.yearBuilt,
            lotSize: self.lotSize,
            status: self.status  // "Active" or "Inactive"
        )
    }
}

// MARK: - Listing Adapters

extension RentCastListing {
    func toRentalComparable() -> RentalComparable {
        toRentalComparable(withDistance: nil)
    }

    func toRentalComparable(withDistance distance: Double?) -> RentalComparable {
        // Build address from components if formattedAddress is nil
        let displayAddress = self.formattedAddress ?? "\(self.addressLine1 ?? ""), \(self.city), \(self.state) \(self.zipCode)"

        return RentalComparable(
            id: self.id,
            address: displayAddress,
            rent: Double(self.price),
            lastSeen: self.lastSeenDate ?? Date(),
            similarity: 0,  // Listings don't have similarity scores
            distance: distance,  // Calculated from search center
            bedrooms: self.bedrooms ?? 0,
            bathrooms: self.bathrooms ?? 1.0,
            sqft: self.squareFootage,
            propertyType: PropertyType.fromRentCastString(self.propertyType ?? "Unknown"),
            coordinate: CLLocationCoordinate2D(
                latitude: self.latitude,
                longitude: self.longitude
            ),
            yearBuilt: self.yearBuilt,
            lotSize: self.lotSize,
            status: self.status  // "Active" or "Inactive"
        )
    }
}

// MARK: - BedroomType Helpers

extension BedroomType {
    static func fromBedroomCount(_ count: Int) -> BedroomType {
        switch count {
        case 0: return .studio
        case 1: return .oneBed
        case 2: return .twoBed
        case 3: return .threeBed
        case 4: return .fourBed
        case 5: return .fiveBed
        default: return .average
        }
    }
}

// MARK: - PropertyType Helpers

extension PropertyType {
    static func fromRentCastString(_ value: String) -> PropertyType {
        switch value {
        case "Single Family": return .singleFamily
        case "Condo": return .condo
        case "Townhouse": return .townhouse
        case "Manufactured": return .manufactured
        case "Multi-Family": return .multiFamily
        case "Apartment": return .apartment
        default: return .all
        }
    }
}
