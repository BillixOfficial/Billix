//
//  ZipCodeService.swift
//  Billix
//
//  Zip code to city/state lookup service
//

import Foundation

struct ZipCodeInfo: Codable {
    let city: String
    let state: String
}

class ZipCodeService {
    static let shared = ZipCodeService()

    private init() {}

    /// Look up city and state from zip code using Zippopotam.us API
    func lookupZipCode(_ zipCode: String) async -> ZipCodeInfo? {
        guard zipCode.count == 5, zipCode.allSatisfy({ $0.isNumber }) else {
            return nil
        }

        let urlString = "https://api.zippopotam.us/us/\(zipCode)"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            let decoded = try JSONDecoder().decode(ZippopotamResponse.self, from: data)

            if let place = decoded.places.first {
                return ZipCodeInfo(city: place.placeName, state: place.stateAbbreviation)
            }

            return nil
        } catch {
            print("Zip code lookup failed: \(error)")
            return nil
        }
    }
}

// MARK: - Zippopotam API Response Models

private struct ZippopotamResponse: Codable {
    let postCode: String
    let country: String
    let countryAbbreviation: String
    let places: [ZippopotamPlace]

    enum CodingKeys: String, CodingKey {
        case postCode = "post code"
        case country
        case countryAbbreviation = "country abbreviation"
        case places
    }
}

private struct ZippopotamPlace: Codable {
    let placeName: String
    let longitude: String
    let state: String
    let stateAbbreviation: String
    let latitude: String

    enum CodingKeys: String, CodingKey {
        case placeName = "place name"
        case longitude
        case state
        case stateAbbreviation = "state abbreviation"
        case latitude
    }
}
