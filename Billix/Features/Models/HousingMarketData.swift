import Foundation

/// Housing market data for a specific location
/// Matches the response from GET /api/v1/housing-market
struct HousingMarketData: Codable, Identifiable, Hashable {
    let id: String
    let zipCode: String?
    let city: String?
    let state: String?
    let propertyType: String?
    let bedrooms: Int?

    // Rent statistics
    let rentAverage: Double?
    let rentMedian: Double?
    let rentMin: Double?
    let rentMax: Double?
    let rentPerSqft: Double?

    // Sale statistics
    let saleAverage: Double?
    let saleMedian: Double?
    let saleMin: Double?
    let saleMax: Double?
    let salePerSqft: Double?

    // Listing counts
    let totalListings: Int?
    let newListings: Int?

    // Metadata
    let lastUpdated: Date?
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case zipCode = "zip_code"
        case city
        case state
        case propertyType = "property_type"
        case bedrooms
        case rentAverage = "rent_average"
        case rentMedian = "rent_median"
        case rentMin = "rent_min"
        case rentMax = "rent_max"
        case rentPerSqft = "rent_per_sqft"
        case saleAverage = "sale_average"
        case saleMedian = "sale_median"
        case saleMin = "sale_min"
        case saleMax = "sale_max"
        case salePerSqft = "sale_per_sqft"
        case totalListings = "total_listings"
        case newListings = "new_listings"
        case lastUpdated = "last_updated"
        case expiresAt = "expires_at"
    }

    // Computed properties for UI
    var locationName: String {
        if let city = city, let state = state {
            return "\(city), \(state)"
        } else if let zipCode = zipCode {
            return "ZIP \(zipCode)"
        }
        return "Unknown Location"
    }

    var formattedRentAverage: String {
        guard let rent = rentAverage else { return "N/A" }
        return "$\(Int(rent))/mo"
    }

    var formattedSaleAverage: String {
        guard let sale = saleAverage else { return "N/A" }
        return "$\(formatLargeNumber(sale))"
    }

    var rentRange: String? {
        guard let min = rentMin, let max = rentMax else { return nil }
        return "$\(Int(min)) - $\(Int(max))"
    }

    var saleRange: String? {
        guard let min = saleMin, let max = saleMax else { return nil }
        return "$\(formatLargeNumber(min)) - $\(formatLargeNumber(max))"
    }

    var newListingsText: String {
        guard let count = newListings else { return "" }
        return "\(count) new in last 30 days"
    }

    var propertyTypeDisplay: String {
        propertyType?.capitalized ?? "All Types"
    }

    var bedroomsDisplay: String {
        guard let beds = bedrooms else { return "Any" }
        return beds == 0 ? "Studio" : "\(beds) bed"
    }

    private func formatLargeNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

/// Response wrapper for housing market API
struct HousingMarketResponse: Codable {
    let data: HousingMarketData?
    let cached: Bool?
}

/// Rent estimate for a specific property
/// Matches the response from GET /api/v1/housing-market/rent-estimate
struct RentEstimate: Codable, Identifiable {
    let id: String
    let address: String?
    let latitude: Double?
    let longitude: Double?

    let estimatedRent: Double
    let rentMin: Double
    let rentMax: Double
    let confidence: String?

    let comparables: [ComparableProperty]?
    let lastUpdated: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case address
        case latitude
        case longitude
        case estimatedRent = "estimated_rent"
        case rentMin = "rent_min"
        case rentMax = "rent_max"
        case confidence
        case comparables
        case lastUpdated = "last_updated"
    }

    var formattedEstimate: String {
        "$\(Int(estimatedRent))/mo"
    }

    var formattedRange: String {
        "$\(Int(rentMin)) - $\(Int(rentMax))"
    }
}

/// Comparable property for rent estimates
struct ComparableProperty: Codable, Identifiable {
    let id: String
    let address: String
    let bedrooms: Int?
    let bathrooms: Double?
    let squareFeet: Int?
    let rent: Double?
    let salePrice: Double?
    let distance: Double?
    let photoURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case address
        case bedrooms
        case bathrooms
        case squareFeet = "square_feet"
        case rent
        case salePrice = "sale_price"
        case distance
        case photoURL = "photo_url"
    }

    var formattedRent: String? {
        guard let rent = rent else { return nil }
        return "$\(Int(rent))/mo"
    }

    var formattedSalePrice: String? {
        guard let price = salePrice else { return nil }
        if price >= 1_000_000 {
            return String(format: "$%.1fM", price / 1_000_000)
        } else {
            return String(format: "$%.0fK", price / 1_000)
        }
    }

    var bedsAndBaths: String {
        let bedText = bedrooms.map { "\($0) bed" } ?? ""
        let bathText = bathrooms.map { String(format: "%.1f bath", $0) } ?? ""
        return [bedText, bathText].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        return String(format: "%.1f mi", distance)
    }
}

/// Market trend data point
/// Matches the response from GET /api/v1/housing-market/trends
struct MarketTrend: Codable, Identifiable {
    let id: String
    let date: Date
    let rentAverage: Double?
    let saleAverage: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case rentAverage = "rent_average"
        case saleAverage = "sale_average"
    }
}

/// Response wrapper for trends API
struct MarketTrendsResponse: Codable {
    let trends: [MarketTrend]
    let zipCode: String?
    let propertyType: String?
    let months: Int
}
