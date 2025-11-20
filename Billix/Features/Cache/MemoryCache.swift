import Foundation

/// In-memory cache using NSCache for fast access to recent data
/// Automatically evicts entries when memory pressure is high
actor MemoryCache {
    private let cache = NSCache<NSString, CacheEntry>()
    private let defaultTTL: TimeInterval = 300 // 5 minutes

    init(countLimit: Int = 100) {
        cache.countLimit = countLimit
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    // MARK: - Public Interface

    func get<T: Codable>(_ key: String) -> T? {
        guard let entry = cache.object(forKey: key as NSString) else {
            return nil
        }

        // Check if expired
        if entry.expiresAt < Date() {
            cache.removeObject(forKey: key as NSString)
            return nil
        }

        // Decode and return
        guard let data = entry.data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func set<T: Codable>(_ key: String, value: T, ttl: TimeInterval? = nil) {
        guard let data = try? JSONEncoder().encode(value) else { return }

        let expiresAt = Date().addingTimeInterval(ttl ?? defaultTTL)
        let entry = CacheEntry(data: data, expiresAt: expiresAt)

        // Set cost based on data size (in bytes)
        let cost = data.count
        cache.setObject(entry, forKey: key as NSString, cost: cost)
    }

    func remove(_ key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func clear() {
        cache.removeAllObjects()
    }
}

// MARK: - Cache Entry

private class CacheEntry {
    let data: Data?
    let expiresAt: Date

    init(data: Data?, expiresAt: Date) {
        self.data = data
        self.expiresAt = expiresAt
    }
}
