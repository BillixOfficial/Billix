import Foundation

struct FlashDrop: Identifiable, Codable {
    let id: UUID
    let title: String
    let provider: String
    let savingsAmount: Int
    let expiresAt: Date
    let category: String
    let detailURL: String?
    let description: String?
    let terms: String?

    init(
        id: UUID = UUID(),
        title: String,
        provider: String,
        savingsAmount: Int,
        expiresAt: Date,
        category: String,
        detailURL: String? = nil,
        description: String? = nil,
        terms: String? = nil
    ) {
        self.id = id
        self.title = title
        self.provider = provider
        self.savingsAmount = savingsAmount
        self.expiresAt = expiresAt
        self.category = category
        self.detailURL = detailURL
        self.description = description
        self.terms = terms
    }

    var categoryIcon: String {
        switch category {
        case "Internet":
            return "📡"
        case "Electric":
            return "⚡️"
        case "Mobile":
            return "📱"
        case "Cable":
            return "📺"
        default:
            return "💡"
        }
    }

    var timeRemaining: TimeInterval {
        expiresAt.timeIntervalSinceNow
    }

    var isExpired: Bool {
        timeRemaining <= 0
    }

    var formattedTimeRemaining: String {
        let interval = timeRemaining

        if interval <= 0 {
            return "Expired"
        }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Mock Data

extension FlashDrop {
    static let mockDrop = FlashDrop(
        title: "Switch to Mint Mobile",
        provider: "Mint Mobile",
        savingsAmount: 45,
        expiresAt: Date().addingTimeInterval(2 * 3600 + 14 * 60), // 2h 14m from now
        category: "Mobile",
        description: "Unlimited talk, text, and data for just $30/month. New customers only.",
        terms: "Requires 3-month prepay. Offer ends soon."
    )

    static let mockDrops: [FlashDrop] = [
        mockDrop,
        FlashDrop(
            title: "Comcast First-Time Customer Deal",
            provider: "Comcast",
            savingsAmount: 60,
            expiresAt: Date().addingTimeInterval(5 * 3600), // 5 hours
            category: "Internet",
            description: "200 Mbps internet for $39.99/month for 12 months.",
            terms: "First-time customers only. Price increases after promo period."
        ),
        FlashDrop(
            title: "Constellation Energy Switch Bonus",
            provider: "Constellation",
            savingsAmount: 120,
            expiresAt: Date().addingTimeInterval(8 * 3600), // 8 hours
            category: "Electric",
            description: "$120 credit when you switch to renewable energy.",
            terms: "12-month contract required."
        ),
        FlashDrop(
            title: "Spectrum TV + Internet Bundle",
            provider: "Spectrum",
            savingsAmount: 85,
            expiresAt: Date().addingTimeInterval(4 * 3600 + 30 * 60), // 4h 30m
            category: "Cable",
            description: "125+ channels + 300 Mbps internet for just $89.99/month.",
            terms: "12-month contract. Installation fees may apply."
        )
    ]
}
