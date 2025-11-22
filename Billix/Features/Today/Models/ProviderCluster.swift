import Foundation

struct ProviderCluster: Identifiable, Codable {
    let id: UUID
    let category: String
    let categoryIcon: String
    let zipPrefix: String
    let topProviders: [ClusterProvider]
    let totalProviders: Int
    let averagePrice: Int
    let memberCount: Int
    let medianPrice: Int?

    init(
        id: UUID = UUID(),
        category: String,
        categoryIcon: String,
        zipPrefix: String,
        topProviders: [ClusterProvider],
        totalProviders: Int,
        averagePrice: Int,
        memberCount: Int,
        medianPrice: Int? = nil
    ) {
        self.id = id
        self.category = category
        self.categoryIcon = categoryIcon
        self.zipPrefix = zipPrefix
        self.topProviders = topProviders
        self.totalProviders = totalProviders
        self.averagePrice = averagePrice
        self.memberCount = memberCount
        self.medianPrice = medianPrice
    }
}

struct ClusterProvider: Identifiable, Codable {
    let id: UUID
    let name: String
    let avgPrice: Double?

    init(id: UUID = UUID(), name: String, avgPrice: Double? = nil) {
        self.id = id
        self.name = name
        self.avgPrice = avgPrice
    }
}

// MARK: - Mock Data

extension ProviderCluster {
    static let mockCluster = ProviderCluster(
        category: "Internet",
        categoryIcon: "📡",
        zipPrefix: "071",
        topProviders: [
            ClusterProvider(name: "Verizon", avgPrice: 89.99),
            ClusterProvider(name: "Comcast", avgPrice: 79.99),
            ClusterProvider(name: "AT&T", avgPrice: 85.00)
        ],
        totalProviders: 6,
        averagePrice: 82,
        memberCount: 47,
        medianPrice: 80
    )

    static let mockClusters: [ProviderCluster] = [
        mockCluster,
        ProviderCluster(
            category: "Electric",
            categoryIcon: "⚡️",
            zipPrefix: "071",
            topProviders: [
                ClusterProvider(name: "PSE&G", avgPrice: 120.00),
                ClusterProvider(name: "Constellation", avgPrice: 115.50),
                ClusterProvider(name: "Direct Energy", avgPrice: 118.75)
            ],
            totalProviders: 8,
            averagePrice: 118,
            memberCount: 134
        ),
        ProviderCluster(
            category: "Mobile",
            categoryIcon: "📱",
            zipPrefix: "071",
            topProviders: [
                ClusterProvider(name: "Verizon", avgPrice: 70.00),
                ClusterProvider(name: "T-Mobile", avgPrice: 60.00),
                ClusterProvider(name: "AT&T", avgPrice: 65.00)
            ],
            totalProviders: 5,
            averagePrice: 65,
            memberCount: 89
        )
    ]
}
