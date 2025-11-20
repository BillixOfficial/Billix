import Foundation

/// Aggregated marketplace data for a provider in a specific ZIP code
/// Matches the response from GET /api/v1/marketplace
struct MarketplaceData: Codable, Identifiable, Hashable {
    let id: String
    let providerId: String
    let zipPrefix: String
    let monthYear: String

    // Pricing statistics
    let avgAmount: Double
    let medianAmount: Double
    let minAmount: Double
    let maxAmount: Double
    let percentile25: Double
    let percentile75: Double

    // Metadata
    let sampleSize: Int
    let avgUsage: Double?
    let medianUsage: Double?
    let subcategory: String?

    // Provider info (from join)
    let provider: Provider?

    enum CodingKeys: String, CodingKey {
        case id
        case providerId = "provider_id"
        case zipPrefix = "zip_prefix"
        case monthYear = "month_year"
        case avgAmount = "avg_amount"
        case medianAmount = "median_amount"
        case minAmount = "min_amount"
        case maxAmount = "max_amount"
        case percentile25 = "percentile_25"
        case percentile75 = "percentile_75"
        case sampleSize = "sample_size"
        case avgUsage = "avg_usage"
        case medianUsage = "median_usage"
        case subcategory
        case provider
    }

    // Computed properties for UI
    var priceRange: String {
        "$\(Int(minAmount)) - $\(Int(maxAmount))"
    }

    var formattedAverage: String {
        "$\(Int(avgAmount))"
    }

    var formattedMedian: String {
        "$\(Int(medianAmount))"
    }

    var isNew: Bool {
        // Consider "new" if within last 7 days
        guard let date = parseMonthYear() else { return false }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return date > sevenDaysAgo
    }

    private func parseMonthYear() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.date(from: monthYear)
    }
}

/// Provider information
struct Provider: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
    }

    // Category-based icon/emoji
    var icon: String {
        switch category.lowercased() {
        case "electric", "electricity":
            return "⚡"
        case "internet", "broadband":
            return "📶"
        case "water":
            return "💧"
        case "gas", "natural gas":
            return "🔥"
        case "phone", "mobile":
            return "📱"
        case "cable", "tv":
            return "📺"
        default:
            return "📄"
        }
    }
}

/// Response wrapper for marketplace API
struct MarketplaceResponse: Codable {
    let data: [MarketplaceData]
    let count: Int?
}
