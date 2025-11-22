import SwiftUI

struct MarketUpdate: Identifiable, Codable {
    let id: UUID
    let category: String
    let categoryIcon: String
    let changePercent: Double
    let zipPrefix: String
    let currentAvg: Double?

    init(
        id: UUID = UUID(),
        category: String,
        categoryIcon: String,
        changePercent: Double,
        zipPrefix: String,
        currentAvg: Double? = nil
    ) {
        self.id = id
        self.category = category
        self.categoryIcon = categoryIcon
        self.changePercent = changePercent
        self.zipPrefix = zipPrefix
        self.currentAvg = currentAvg
    }

    var changeDirection: String {
        changePercent >= 0 ? "arrow.up.right" : "arrow.down.right"
    }

    var changeColor: Color {
        // For bills, up = bad (red), down = good (green)
        changePercent >= 0 ? .red : .billixMoneyGreen
    }

    var formattedChange: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", changePercent))%"
    }
}

// MARK: - Mock Data

extension MarketUpdate {
    static let mockUpdates: [MarketUpdate] = [
        MarketUpdate(
            category: "Internet",
            categoryIcon: "📡",
            changePercent: 3.2,
            zipPrefix: "071",
            currentAvg: 89.99
        ),
        MarketUpdate(
            category: "Electric",
            categoryIcon: "⚡️",
            changePercent: -2.1,
            zipPrefix: "071",
            currentAvg: 120.45
        ),
        MarketUpdate(
            category: "Mobile",
            categoryIcon: "📱",
            changePercent: -1.5,
            zipPrefix: "071",
            currentAvg: 65.00
        ),
        MarketUpdate(
            category: "Insurance",
            categoryIcon: "🏥",
            changePercent: 4.8,
            zipPrefix: "071",
            currentAvg: 245.00
        ),
        MarketUpdate(
            category: "Streaming",
            categoryIcon: "📺",
            changePercent: 0.5,
            zipPrefix: "071",
            currentAvg: 45.99
        )
    ]
}
