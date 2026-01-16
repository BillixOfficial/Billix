//
//  GeocodingService.swift
//  Billix
//
//  Created by Claude Code on 1/15/26.
//  Apple MapKit geocoding to convert addresses to zip codes (free)
//

import Foundation
import CoreLocation

/// Service for converting addresses/cities to zip codes using Apple's free geocoding
actor GeocodingService {
    static let shared = GeocodingService()

    private let geocoder = CLGeocoder()

    private init() {}

    // MARK: - Public Interface

    /// Convert an address or city name to a zip code
    /// - Parameter address: Address string (e.g., "Royal Oak, MI" or "123 Main St, Detroit")
    /// - Returns: 5-digit zip code if found, nil otherwise
    func getZipCode(from address: String) async -> String? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)

            // Get the first placemark with a postal code
            for placemark in placemarks {
                if let postalCode = placemark.postalCode {
                    // Return first 5 digits (US zip codes)
                    let zip = String(postalCode.prefix(5))
                    if zip.count == 5, zip.allSatisfy({ $0.isNumber }) {
                        return zip
                    }
                }
            }

            return nil
        } catch {
            print("❌ Geocoding error: \(error.localizedDescription)")
            return nil
        }
    }

    /// Get full location info from an address
    /// - Parameter address: Address string
    /// - Returns: Tuple of (zipCode, city, state, coordinate) if found
    func getLocationInfo(from address: String) async -> (zipCode: String?, city: String?, state: String?, coordinate: CLLocationCoordinate2D?)? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)

            guard let placemark = placemarks.first else {
                return nil
            }

            let zipCode = placemark.postalCode.flatMap { String($0.prefix(5)) }
            let city = placemark.locality
            let state = placemark.administrativeArea
            let coordinate = placemark.location?.coordinate

            return (zipCode, city, state, coordinate)
        } catch {
            print("❌ Geocoding error: \(error.localizedDescription)")
            return nil
        }
    }
}
