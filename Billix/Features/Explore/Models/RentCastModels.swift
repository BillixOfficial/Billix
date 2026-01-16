//
//  RentCastModels.swift
//  Billix
//
//  Created by Claude Code on 1/14/26.
//  Codable models for RentCast API responses
//

import Foundation

// MARK: - Market Statistics Response

struct RentCastMarketResponse: Codable {
    let id: String
    let zipCode: String
    let rentalData: RentalMarketData?
    let saleData: SaleMarketData?
}

struct RentalMarketData: Codable {
    let lastUpdatedDate: Date
    let averageRent: Double
    let medianRent: Double
    let minRent: Double
    let maxRent: Double
    let averageRentPerSquareFoot: Double?
    let medianRentPerSquareFoot: Double?
    let averageSquareFootage: Double?
    let medianSquareFootage: Double?
    let averageDaysOnMarket: Double?
    let medianDaysOnMarket: Double?
    let newListings: Int?
    let totalListings: Int?
    let dataByBedrooms: [BedroomMarketData]
    let dataByPropertyType: [PropertyTypeMarketData]?
    let history: [String: HistoricalMarketData]  // Key: "YYYY-MM"
}

struct SaleMarketData: Codable {
    let lastUpdatedDate: Date
    let averagePrice: Double
    let medianPrice: Double
    let minPrice: Double
    let maxPrice: Double
    let averagePricePerSquareFoot: Double?
    let dataByBedrooms: [BedroomMarketData]?
    let history: [String: HistoricalMarketData]?
}

struct BedroomMarketData: Codable {
    let bedrooms: Int
    let averageRent: Double
    let medianRent: Double?  // Optional - not present in historical data
    let minRent: Double?
    let maxRent: Double?
    let averageRentPerSquareFoot: Double?
    let averageSquareFootage: Double?
    let averageDaysOnMarket: Double?
    let newListings: Int?
    let totalListings: Int?
}

struct PropertyTypeMarketData: Codable {
    let propertyType: String
    let averageRent: Double
    let medianRent: Double?  // Optional for safety
    let totalListings: Int?
}

struct HistoricalMarketData: Codable {
    let date: Date
    let averageRent: Double
    let medianRent: Double?
    let minRent: Double?
    let maxRent: Double?
    let newListings: Int?
    let totalListings: Int?
    let dataByBedrooms: [BedroomMarketData]?
}

// MARK: - Rent Estimate Response

struct RentCastEstimateResponse: Codable {
    let rent: Double
    let rentRangeLow: Double
    let rentRangeHigh: Double
    let latitude: Double
    let longitude: Double
    let comparables: [RentCastComparable]
    let subjectProperty: RentCastSubjectProperty?
}

struct RentCastSubjectProperty: Codable {
    let id: String?
    let formattedAddress: String?
    let addressLine1: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let latitude: Double?
    let longitude: Double?
    let propertyType: String?
    let bedrooms: Int?
    let bathrooms: Double?
    let squareFootage: Int?
    let lotSize: Int?
    let yearBuilt: Int?
}

struct RentCastComparable: Codable {
    let id: String
    let formattedAddress: String
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let latitude: Double
    let longitude: Double
    let propertyType: String
    let bedrooms: Int
    let bathrooms: Double?
    let squareFootage: Int?
    let lotSize: Int?
    let yearBuilt: Int?
    let price: Int  // Monthly rent or sale price
    let status: String
    let listingType: String?
    let listedDate: Date
    let removedDate: Date?
    let lastSeenDate: Date
    let daysOnMarket: Int
    let distance: Double
    let daysOld: Int
    let correlation: Double
}

// MARK: - Rental Listings Response

struct RentCastListing: Codable {
    let id: String
    let formattedAddress: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String
    let state: String
    let stateFips: String?
    let zipCode: String
    let county: String?
    let countyFips: String?
    let latitude: Double
    let longitude: Double
    let propertyType: String?
    let bedrooms: Int?
    let bathrooms: Double?
    let squareFootage: Int?
    let lotSize: Int?
    let yearBuilt: Int?
    let status: String?
    let price: Int
    let listingType: String?
    let listedDate: Date?
    let removedDate: Date?
    let createdDate: Date?
    let lastSeenDate: Date?
    let daysOnMarket: Int?
    let mlsName: String?
    let mlsNumber: String?
    let listingAgent: ListingContact?
    let listingOffice: ListingContact?
}

struct ListingContact: Codable {
    let name: String?
    let phone: String?
    let email: String?
    let website: String?
}
