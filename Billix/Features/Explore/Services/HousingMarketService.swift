import Foundation

/// Service for interacting with the Housing Market API
/// Implements cache-first strategy with automatic fallback to network
actor HousingMarketService {
    static let shared = HousingMarketService()

    private let cacheManager = CacheManager.shared
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Market Data

    /// Fetch housing market data for a location
    /// - Parameters:
    ///   - zipCode: ZIP code to search
    ///   - city: City name (requires state)
    ///   - state: State abbreviation (requires city)
    ///   - propertyType: Optional property type filter
    ///   - bedrooms: Optional bedroom count filter
    ///   - forceRefresh: If true, bypass cache and fetch from network
    func fetchMarketData(
        zipCode: String? = nil,
        city: String? = nil,
        state: String? = nil,
        propertyType: String? = nil,
        bedrooms: Int? = nil,
        forceRefresh: Bool = false
    ) async throws -> HousingMarketData {
        // Validate input
        guard zipCode != nil || (city != nil && state != nil) else {
            throw NetworkError.invalidURL
        }

        // Generate cache key
        let cacheKey = CacheKey.housingMarket(
            zipCode: zipCode,
            city: city,
            state: state,
            propertyType: propertyType,
            bedrooms: bedrooms
        )

        // Try cache first unless force refresh
        if !forceRefresh, let cached: HousingMarketResponse = await cacheManager.get(cacheKey),
           let data = cached.data {
            return data
        }

        // Build URL with query parameters
        var urlComponents = URLComponents(string: Config.housingMarketEndpoint)
        var queryItems: [URLQueryItem] = []

        if let zipCode = zipCode {
            queryItems.append(URLQueryItem(name: "zipCode", value: zipCode))
        }
        if let city = city {
            queryItems.append(URLQueryItem(name: "city", value: city))
        }
        if let state = state {
            queryItems.append(URLQueryItem(name: "state", value: state))
        }
        if let propertyType = propertyType {
            queryItems.append(URLQueryItem(name: "propertyType", value: propertyType))
        }
        if let bedrooms = bedrooms {
            queryItems.append(URLQueryItem(name: "bedrooms", value: "\(bedrooms)"))
        }

        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }

        // Make network request
        let data = try await performRequest(url: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let response = try decoder.decode(HousingMarketResponse.self, from: data)

        guard let marketData = response.data else {
            throw NetworkError.notFound
        }

        // Cache the response (30-day TTL for housing data)
        await cacheManager.set(cacheKey, value: response, memoryTTL: 1800) // 30 min memory cache

        return marketData
    }

    // MARK: - Rent Estimates

    /// Get rent estimate for a specific property
    /// - Parameters:
    ///   - address: Property address
    ///   - latitude: Property latitude (alternative to address)
    ///   - longitude: Property longitude (alternative to address)
    func fetchRentEstimate(
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        forceRefresh: Bool = false
    ) async throws -> RentEstimate {
        // Validate input
        guard address != nil || (latitude != nil && longitude != nil) else {
            throw NetworkError.invalidURL
        }

        // Generate cache key
        let cacheKey = CacheKey.rentEstimate(address: address, latitude: latitude, longitude: longitude)

        // Try cache first
        if !forceRefresh, let cached: RentEstimate = await cacheManager.get(cacheKey) {
            return cached
        }

        // Build URL
        let endpoint = "\(Config.housingMarketEndpoint)/rent-estimate"
        var urlComponents = URLComponents(string: endpoint)
        var queryItems: [URLQueryItem] = []

        if let address = address {
            queryItems.append(URLQueryItem(name: "address", value: address))
        }
        if let latitude = latitude {
            queryItems.append(URLQueryItem(name: "latitude", value: "\(latitude)"))
        }
        if let longitude = longitude {
            queryItems.append(URLQueryItem(name: "longitude", value: "\(longitude)"))
        }

        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }

        // Make request
        let data = try await performRequest(url: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let estimate = try decoder.decode(RentEstimate.self, from: data)

        // Cache the estimate
        await cacheManager.set(cacheKey, value: estimate, memoryTTL: 3600) // 1 hour memory cache

        return estimate
    }

    // MARK: - Market Trends

    /// Fetch historical market trends
    /// - Parameters:
    ///   - zipCode: ZIP code to search
    ///   - propertyType: Optional property type filter
    ///   - months: Number of months to fetch (6, 12, or 60)
    func fetchMarketTrends(
        zipCode: String,
        propertyType: String? = nil,
        months: Int = 12,
        forceRefresh: Bool = false
    ) async throws -> MarketTrendsResponse {
        // Validate months parameter
        guard [6, 12, 60].contains(months) else {
            throw NetworkError.invalidURL
        }

        // Generate cache key
        let cacheKey = CacheKey.marketTrends(zipCode: zipCode, propertyType: propertyType, months: months)

        // Try cache first
        if !forceRefresh, let cached: MarketTrendsResponse = await cacheManager.get(cacheKey) {
            return cached
        }

        // Build URL
        let endpoint = "\(Config.housingMarketEndpoint)/trends"
        var urlComponents = URLComponents(string: endpoint)
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "zipCode", value: zipCode),
            URLQueryItem(name: "months", value: "\(months)")
        ]

        if let propertyType = propertyType {
            queryItems.append(URLQueryItem(name: "propertyType", value: propertyType))
        }

        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }

        // Make request
        let data = try await performRequest(url: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let trends = try decoder.decode(MarketTrendsResponse.self, from: data)

        // Cache the trends
        await cacheManager.set(cacheKey, value: trends, memoryTTL: 3600) // 1 hour memory cache

        return trends
    }

    // MARK: - Comparables

    /// Fetch comparable properties for a location
    func fetchComparables(zipCode: String, forceRefresh: Bool = false) async throws -> [ComparableProperty] {
        let cacheKey = CacheKey.comparables(zipCode: zipCode)

        // Try cache first
        if !forceRefresh, let cached: [ComparableProperty] = await cacheManager.get(cacheKey) {
            return cached
        }

        // Build URL
        let endpoint = "\(Config.housingMarketEndpoint)/listings"
        var urlComponents = URLComponents(string: endpoint)
        urlComponents?.queryItems = [URLQueryItem(name: "zipCode", value: zipCode)]

        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }

        // Make request
        let data = try await performRequest(url: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let comparables = try decoder.decode([ComparableProperty].self, from: data)

        // Cache the comparables
        await cacheManager.set(cacheKey, value: comparables, memoryTTL: 1800) // 30 min memory cache

        return comparables
    }

    // MARK: - Helper Methods

    private func performRequest(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return data
        case 404:
            throw NetworkError.notFound
        case 401:
            throw NetworkError.unauthorized
        case 500...599:
            throw NetworkError.serverError("Server error (\(httpResponse.statusCode))")
        default:
            throw NetworkError.serverError("Unexpected status code: \(httpResponse.statusCode)")
        }
    }
}
