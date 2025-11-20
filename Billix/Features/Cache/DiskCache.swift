import Foundation

/// Disk-based cache for persistent storage across app sessions
/// Uses FileManager to store data in the app's cache directory
actor DiskCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let defaultTTL: TimeInterval = 86400 * 30 // 30 days

    init() {
        // Use the system's cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = paths[0].appendingPathComponent("BillixExploreCache", isDirectory: true)

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public Interface

    func get<T: Codable>(_ key: String) async -> T? {
        let fileURL = cacheDirectory.appendingPathComponent(sanitizeKey(key))

        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        // Read metadata and data
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return nil
        }

        // Check if expired
        if modificationDate.addingTimeInterval(defaultTTL) < Date() {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }

        // Read and decode data
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }

    func set<T: Codable>(_ key: String, value: T) async {
        let fileURL = cacheDirectory.appendingPathComponent(sanitizeKey(key))

        // Encode data
        guard let data = try? JSONEncoder().encode(value) else { return }

        // Write to disk
        try? data.write(to: fileURL, options: .atomic)
    }

    func remove(_ key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent(sanitizeKey(key))
        try? fileManager.removeItem(at: fileURL)
    }

    func clear() async {
        // Remove all files in cache directory
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }

    func clearExpired() async {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }

        for file in files {
            guard let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                  let modificationDate = attributes[.modificationDate] as? Date else {
                continue
            }

            // Remove if expired
            if modificationDate.addingTimeInterval(defaultTTL) < Date() {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    func getCacheSize() async -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for file in files {
            guard let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                  let fileSize = attributes[.size] as? Int64 else {
                continue
            }
            totalSize += fileSize
        }

        return totalSize
    }

    // MARK: - Helper Methods

    private func sanitizeKey(_ key: String) -> String {
        // Replace special characters with underscores
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return key.components(separatedBy: allowed.inverted).joined(separator: "_")
    }
}
