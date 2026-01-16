//
//  RentCastEdgeFunctionService.swift
//  Billix
//
//  Created by Claude Code on 1/14/26.
//  Service layer for calling RentCast API via Supabase Edge Functions
//

import Foundation
import Supabase

// MARK: - Request Structs (Encodable)

private struct MarketStatisticsRequest: Encodable {
    let zipCode: String
    let historyRange: Int
}

private struct RentEstimateRequest: Encodable {
    let address: String
    let propertyType: String?
    let bedrooms: Int?
    let bathrooms: Double?
    let squareFootage: Int?
    let maxRadius: Double?
    let daysOld: Int?
    let compCount: Int?
}

private struct RentalListingsRequest: Encodable {
    let city: String?
    let state: String?
    let zipCode: String?
    let latitude: Double?
    let longitude: Double?
    let radius: Double?
    let propertyType: String?
    let bedrooms: String?
    let bathrooms: String?
    let price: String?
    let squareFootage: String?
    let yearBuilt: String?
    let lotSize: String?
    let daysOld: String?
    let status: String?
    let limit: Int
    let offset: Int
}

private struct ListingsResponse: Decodable {
    let listings: [RentCastListing]?
}

// MARK: - Service

actor RentCastEdgeFunctionService {
    static let shared = RentCastEdgeFunctionService()

    private let supabase = SupabaseService.shared.client

    // MARK: - API Call Tracking
    private var apiCallCount: Int = 0

    private func logAPICall(_ endpoint: String) {
        apiCallCount += 1
        print("📊 [API CALL #\(apiCallCount)] \(endpoint)")
    }

    /// Get total API calls made this session
    func getAPICallCount() -> Int {
        return apiCallCount
    }

    // Custom decoder for RentCast date formats
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try ISO8601 without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try simple date format (YYYY-MM-DD)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date from: \(dateString)"
            )
        }
        return decoder
    }

    // MARK: - Market Statistics

    func fetchMarketStatistics(
        zipCode: String,
        historyRange: Int = 12
    ) async throws -> RentCastMarketResponse {
        logAPICall("fetch-market-statistics")
        print("🏠 [RentCast] Fetching market statistics...")
        print("   📍 ZIP: \(zipCode), History: \(historyRange) months")

        let request = MarketStatisticsRequest(
            zipCode: zipCode,
            historyRange: historyRange
        )

        do {
            // Use custom decode closure to get raw Data, then decode with our custom decoder
            let result: RentCastMarketResponse = try await supabase.functions.invoke(
                "fetch-market-statistics",
                options: FunctionInvokeOptions(body: request),
                decode: { data, response in
                    print("   ✅ Received \(data.count) bytes from edge function")

                    // Debug: Print raw JSON response
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("   📦 Raw response: \(jsonString.prefix(500))...")
                    }

                    let result = try self.decoder.decode(RentCastMarketResponse.self, from: data)
                    print("   ✅ Successfully decoded market data for ZIP: \(result.zipCode)")
                    if let rental = result.rentalData {
                        print("   💰 Average rent: $\(Int(rental.averageRent))")
                        print("   📊 Bedrooms data count: \(rental.dataByBedrooms.count)")
                        print("   📈 History months: \(rental.history.count)")
                    }
                    return result
                }
            )

            return result

        } catch {
            print("   ❌ Error fetching market statistics: \(error)")
            if let decodingError = error as? DecodingError {
                print("   🔍 Decoding error details: \(decodingError)")
            }
            throw error
        }
    }

    // MARK: - Rent Estimate

    func fetchRentEstimate(
        address: String,
        propertyType: String? = nil,
        bedrooms: Int? = nil,
        bathrooms: Double? = nil,
        squareFootage: Int? = nil,
        maxRadius: Double? = nil,
        daysOld: Int? = nil,
        compCount: Int? = nil
    ) async throws -> RentCastEstimateResponse {
        logAPICall("fetch-rent-estimate")
        print("🏠 [RentCast] Fetching rent estimate...")
        print("   📍 Address: \(address)")
        print("   🛏️ Beds: \(bedrooms ?? -1), Baths: \(bathrooms ?? -1), SqFt: \(squareFootage ?? -1)")
        print("   📏 Radius: \(maxRadius ?? -1) miles, Days: \(daysOld ?? -1)")

        let request = RentEstimateRequest(
            address: address,
            propertyType: propertyType,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            squareFootage: squareFootage,
            maxRadius: maxRadius,
            daysOld: daysOld,
            compCount: compCount
        )

        do {
            // Use custom decode closure to get raw Data, then decode with our custom decoder
            let result: RentCastEstimateResponse = try await supabase.functions.invoke(
                "fetch-rent-estimate",
                options: FunctionInvokeOptions(body: request),
                decode: { data, response in
                    print("   ✅ Received \(data.count) bytes from edge function")

                    // Debug: Print raw JSON response
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("   📦 Raw response: \(jsonString.prefix(500))...")
                    }

                    let result = try self.decoder.decode(RentCastEstimateResponse.self, from: data)
                    print("   ✅ Successfully decoded rent estimate")
                    print("   💰 Estimated rent: $\(Int(result.rent))")
                    print("   📊 Range: $\(Int(result.rentRangeLow)) - $\(Int(result.rentRangeHigh))")
                    print("   🏘️ Comparables: \(result.comparables.count)")
                    return result
                }
            )

            return result

        } catch {
            print("   ❌ Error fetching rent estimate: \(error)")
            if let decodingError = error as? DecodingError {
                print("   🔍 Decoding error details: \(decodingError)")
            }
            throw error
        }
    }

    // MARK: - Rental Listings

    func fetchRentalListings(
        city: String? = nil,
        state: String? = nil,
        zipCode: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        radius: Double? = nil,
        propertyType: String? = nil,
        bedrooms: String? = nil,
        bathrooms: String? = nil,
        price: String? = nil,
        squareFootage: String? = nil,
        yearBuilt: String? = nil,
        lotSize: String? = nil,
        daysOld: String? = nil,
        status: String? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [RentCastListing] {
        logAPICall("fetch-rental-listings")
        print("🏠 [RentCast] Fetching rental listings...")
        print("   📍 City: \(city ?? "nil"), State: \(state ?? "nil"), ZIP: \(zipCode ?? "nil")")
        print("   🛏️ Beds: \(bedrooms ?? "any"), Baths: \(bathrooms ?? "any")")
        print("   💵 Price: \(price ?? "any"), Status: \(status ?? "any")")
        print("   📏 Radius: \(radius ?? -1) miles, Limit: \(limit)")
        print("   🏠 Type: \(propertyType ?? "any"), Days: \(daysOld ?? "any")")

        let request = RentalListingsRequest(
            city: city,
            state: state,
            zipCode: zipCode,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            propertyType: propertyType,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            price: price,
            squareFootage: squareFootage,
            yearBuilt: yearBuilt,
            lotSize: lotSize,
            daysOld: daysOld,
            status: status,
            limit: limit,
            offset: offset
        )

        do {
            // Use custom decode closure to get raw Data, then decode with our custom decoder
            let listings: [RentCastListing] = try await supabase.functions.invoke(
                "fetch-rental-listings",
                options: FunctionInvokeOptions(body: request),
                decode: { data, response in
                    print("   ✅ Received \(data.count) bytes from edge function")

                    // Debug: Print raw JSON response
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("   📦 Raw response: \(jsonString.prefix(500))...")
                    }

                    let result = try self.decoder.decode(ListingsResponse.self, from: data)
                    let listings = result.listings ?? []
                    print("   ✅ Successfully decoded \(listings.count) listings")
                    if let first = listings.first {
                        print("   🏠 First listing: \(first.formattedAddress) - $\(first.price)/mo")
                    }
                    return listings
                }
            )

            return listings

        } catch {
            print("   ❌ Error fetching rental listings: \(error)")
            if let decodingError = error as? DecodingError {
                print("   🔍 Decoding error details: \(decodingError)")
            }
            throw error
        }
    }
}
