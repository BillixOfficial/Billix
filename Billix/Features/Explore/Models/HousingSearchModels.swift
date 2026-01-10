//
//  HousingSearchModels.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Data models for Rentometer-style property search
//

import Foundation
import SwiftUI
import MapKit

// MARK: - Property Type

enum PropertyType: String, CaseIterable, Identifiable {
    case all = "All"
    case singleFamily = "Single Family"
    case apartment = "Apartment"
    case condo = "Condo"
    case townhouse = "Townhouse"
    case manufactured = "Manufactured"
    case multiFamily = "Multi-Family"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "house.fill"
        case .singleFamily: return "house.fill"
        case .apartment: return "building.2.fill"
        case .condo: return "building.fill"
        case .townhouse: return "house.lodge.fill"
        case .manufactured: return "house.and.flag.fill"
        case .multiFamily: return "building.2.crop.circle.fill"
        }
    }

    var rentcastValue: String {
        // Return exact Rentcast API value
        switch self {
        case .all: return ""
        default: return rawValue
        }
    }
}

// MARK: - Property Amenities

enum PropertyAmenity: String, CaseIterable, Identifiable {
    case parking = "Parking"
    case pool = "Pool"
    case gym = "Gym"
    case airConditioning = "A/C"
    case laundry = "Laundry"
    case petFriendly = "Pet Friendly"
    case dishwasher = "Dishwasher"
    case balcony = "Balcony"
    case hardwood = "Hardwood Floors"
    case fireplace = "Fireplace"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .parking: return "car.fill"
        case .pool: return "figure.pool.swim"
        case .gym: return "dumbbell.fill"
        case .airConditioning: return "snowflake"
        case .laundry: return "washer.fill"
        case .petFriendly: return "pawprint.fill"
        case .dishwasher: return "dishwasher.fill"
        case .balcony: return "building.2.crop.circle.fill"
        case .hardwood: return "square.stack.3d.up.fill"
        case .fireplace: return "flame.fill"
        }
    }
}

// MARK: - Listing Status

enum ListingStatus: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case inactive = "Inactive"

    var id: String { rawValue }
}

// MARK: - Property Search Parameters

struct PropertySearchParams {
    let address: String
    let propertyType: PropertyType
    let bedrooms: Int?
    let bathrooms: Double?
    let squareFeet: Int?
    let searchRadius: Double  // in miles
    let lookbackDays: Int
}

// MARK: - Rent Estimate Result

struct RentEstimateResult {
    let estimatedRent: Double        // $2,450
    let lowEstimate: Double          // $2,083 (85%)
    let highEstimate: Double         // $2,818 (115%)
    let perSqft: Double              // $2.58
    let perBedroom: Double           // $1,225
    let confidence: String           // "High", "Medium", "Low"
    let comparablesCount: Int        // 15

    var estimateRange: ClosedRange<Double> {
        lowEstimate...highEstimate
    }

    var estimatePosition: Double {
        // Position of estimate within range (0.0 to 1.0)
        guard highEstimate > lowEstimate else { return 0.5 }
        return (estimatedRent - lowEstimate) / (highEstimate - lowEstimate)
    }
}

// MARK: - Rental Comparable

struct RentalComparable: Identifiable {
    let id: String
    let address: String
    let rent: Double?
    let lastSeen: Date
    let similarity: Double           // 0.0 to 100.0 (percentage)
    let distance: Double?            // in miles
    let bedrooms: Int
    let bathrooms: Double
    let sqft: Int?
    let propertyType: PropertyType
    let coordinate: CLLocationCoordinate2D

    var lastSeenFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastSeen, relativeTo: Date())
    }

    var distanceFormatted: String {
        guard let distance = distance else { return "N/A" }
        return String(format: "%.2f mi", distance)
    }

    var rentFormatted: String {
        guard let rent = rent else { return "N/A" }
        return "$\(Int(rent))/mo"
    }

    var similarityFormatted: String {
        String(format: "%.1f%%", similarity)
    }

    var sqftFormatted: String {
        guard let sqft = sqft else { return "N/A" }
        return "\(sqft)"
    }

    var bathroomsFormatted: String {
        if bathrooms.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(bathrooms))"
        } else {
            return String(format: "%.1f", bathrooms)
        }
    }
}

// MARK: - Comparable Column (for sorting)

enum ComparableColumn: String, CaseIterable {
    case address = "ADDRESS"
    case rent = "LISTED RENT"
    case lastSeen = "LAST SEEN"
    case similarity = "SIMILARITY %"
    case distance = "DISTANCE"
    case beds = "BEDS"
    case baths = "BATHS"
    case sqft = "SQ.FT."
    case type = "TYPE"

    var width: CGFloat {
        switch self {
        case .address: return 180
        case .rent: return 100
        case .lastSeen: return 100
        case .similarity: return 80
        case .distance: return 80
        case .beds: return 50
        case .baths: return 60
        case .sqft: return 70
        case .type: return 100
        }
    }

    var alignment: HorizontalAlignment {
        switch self {
        case .beds, .baths:
            return .center
        default:
            return .leading
        }
    }
}

// MARK: - Property Marker (for map)

struct PropertyMarker: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let isSearchedProperty: Bool  // true = blue pin, false = green pin
}
