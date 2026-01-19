import Foundation

/// Unified cache manager that coordinates between memory and disk caches
/// Implements a three-tier caching strategy: Memory → Disk → Network
actor CacheManager {
    static let shared = CacheManager()

    private let memoryCache = MemoryCache()
    private let diskCache = DiskCache()

    private init() {}

    // MARK: - Public Interface

    /// Get cached data with automatic fallback from memory → disk
    func get<T: Codable>(_ key: String) async -> T? {
        // Try memory cache first (fastest)
        if let value: T = await memoryCache.get(key) {
            return value
        }

        // Fallback to disk cache
        if let value: T = await diskCache.get(key) {
            // Promote to memory cache for faster access next time
            await memoryCache.set(key, value: value)
            return value
        }

        return nil
    }

    /// Set data in both memory and disk caches
    func set<T: Codable>(_ key: String, value: T, memoryTTL: TimeInterval? = nil) async {
        // Store in memory cache with optional custom TTL
        await memoryCache.set(key, value: value, ttl: memoryTTL)

        // Store in disk cache for persistence
        await diskCache.set(key, value: value)
    }

    /// Remove data from both caches
    func remove(_ key: String) async {
        await memoryCache.remove(key)
        await diskCache.remove(key)
    }

    /// Clear all cached data
    func clearAll() async {
        await memoryCache.clear()
        await diskCache.clear()
    }

    /// Clear only expired entries (disk cache)
    func clearExpired() async {
        await diskCache.clearExpired()
    }

    /// Get total disk cache size in bytes
    func getCacheSize() async -> Int64 {
        await diskCache.getCacheSize()
    }

    /// Get formatted cache size (e.g., "12.5 MB")
    func getFormattedCacheSize() async -> String {
        let bytes = await diskCache.getCacheSize()
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - Cache Keys

enum CacheKey {
    // Bills Marketplace
    static func marketplaceList(zipPrefix: String?, category: String?, sort: String?) -> String {
        var parts = ["marketplace"]
        if let zip = zipPrefix { parts.append("zip_\(zip)") }
        if let cat = category { parts.append("cat_\(cat)") }
        if let sort = sort { parts.append("sort_\(sort)") }
        return parts.joined(separator: "_")
    }

    static func marketplaceBill(_ id: String) -> String {
        "marketplace_bill_\(id)"
    }

    // Housing Marketplace
    static func housingMarket(zipCode: String?, city: String?, state: String?, propertyType: String?, bedrooms: Int?) -> String {
        var parts = ["housing"]
        if let zip = zipCode { parts.append("zip_\(zip)") }
        if let city = city, let state = state { parts.append("\(city)_\(state)") }
        if let type = propertyType { parts.append("type_\(type)") }
        if let beds = bedrooms { parts.append("beds_\(beds)") }
        return parts.joined(separator: "_")
    }

    static func rentEstimate(address: String?, latitude: Double?, longitude: Double?, bedrooms: Int? = nil, bathrooms: Double? = nil) -> String {
        var parts: [String] = ["rent_estimate"]

        if let address = address {
            parts.append(address.replacingOccurrences(of: " ", with: "_"))
        } else if let lat = latitude, let lon = longitude {
            parts.append("\(lat)_\(lon)")
        } else {
            parts.append("unknown")
        }

        // Include filter parameters in cache key
        if let beds = bedrooms {
            parts.append("beds_\(beds)")
        }
        if let baths = bathrooms {
            parts.append("baths_\(Int(baths))")
        }

        return parts.joined(separator: "_")
    }

    static func marketTrends(zipCode: String, propertyType: String?, months: Int) -> String {
        var parts = ["trends", zipCode, "\(months)mo"]
        if let type = propertyType { parts.append(type) }
        return parts.joined(separator: "_")
    }

    static func comparables(zipCode: String) -> String {
        "comparables_\(zipCode)"
    }

    // RentCast API Cache Keys
    static func rentCastListings(zipCode: String) -> String {
        "rentcast_listings_\(zipCode)"
    }

    static func rentCastMarketStats(zipCode: String) -> String {
        "rentcast_market_stats_\(zipCode)"
    }
}
