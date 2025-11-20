import Foundation

/// Service for interacting with the Bills Marketplace API
/// Implements cache-first strategy with automatic fallback to network
actor MarketplaceService {
    static let shared = MarketplaceService()

    private let cacheManager = CacheManager.shared
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Public API

    /// Fetch marketplace data with filtering and sorting
    /// - Parameters:
    ///   - zipPrefix: Optional ZIP code prefix for filtering
    ///   - category: Optional category filter (e.g., "Electric", "Internet")
    ///   - sort: Optional sort parameter
    ///   - forceRefresh: If true, bypass cache and fetch from network
    /// - Returns: Array of marketplace data
    func fetchMarketplaceData(
        zipPrefix: String? = nil,
        category: String? = nil,
        sort: String? = nil,
        forceRefresh: Bool = false
    ) async throws -> [MarketplaceData] {
        // Generate cache key
        let cacheKey = CacheKey.marketplaceList(zipPrefix: zipPrefix, category: category, sort: sort)

        // Try cache first unless force refresh
        if !forceRefresh, let cached: MarketplaceResponse = await cacheManager.get(cacheKey) {
            return cached.data
        }

        // Build URL with query parameters
        var urlComponents = URLComponents(string: Config.marketplaceEndpoint)
        var queryItems: [URLQueryItem] = []

        if let zipPrefix = zipPrefix {
            queryItems.append(URLQueryItem(name: "zip_prefix", value: zipPrefix))
        }
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if let sort = sort {
            queryItems.append(URLQueryItem(name: "sort", value: sort))
        }

        if !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems
        }

        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }

        // Make network request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let marketplaceResponse = try decoder.decode(MarketplaceResponse.self, from: data)

            // Cache the response
            await cacheManager.set(cacheKey, value: marketplaceResponse, memoryTTL: 600) // 10 min memory cache

            return marketplaceResponse.data

        case 400:
            throw NetworkError.badRequest("ZIP code is required. Please enter your ZIP code.")

        case 404:
            throw NetworkError.notFound

        case 500...599:
            throw NetworkError.serverError("Server error (\(httpResponse.statusCode))")

        default:
            throw NetworkError.serverError("Unexpected status code: \(httpResponse.statusCode)")
        }
    }

    /// Get unique categories available in the marketplace
    /// Returns hardcoded list to avoid API calls without ZIP code
    func getCategories() -> [String] {
        return ["Electric", "Internet", "Water", "Gas", "Phone", "Cable"].sorted()
    }

    /// Get marketplace statistics for a specific category
    func getCategoryStats(category: String, zipPrefix: String? = nil) async throws -> CategoryStats {
        let data = try await fetchMarketplaceData(zipPrefix: zipPrefix, category: category)

        guard !data.isEmpty else {
            throw NetworkError.notFound
        }

        let averages = data.map { $0.avgAmount }
        let totalSamples = data.reduce(0) { $0 + $1.sampleSize }

        return CategoryStats(
            category: category,
            providerCount: data.count,
            lowestAverage: averages.min() ?? 0,
            highestAverage: averages.max() ?? 0,
            overallAverage: averages.reduce(0, +) / Double(averages.count),
            totalSamples: totalSamples
        )
    }
}

// MARK: - Supporting Types

struct CategoryStats {
    let category: String
    let providerCount: Int
    let lowestAverage: Double
    let highestAverage: Double
    let overallAverage: Double
    let totalSamples: Int

    var potentialSavings: Double {
        highestAverage - lowestAverage
    }

    var formattedSavings: String {
        "$\(Int(potentialSavings))/mo"
    }
}
