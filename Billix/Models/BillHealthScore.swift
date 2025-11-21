import Foundation
import SwiftUI

struct BillHealthScore: Codable, Identifiable {
    let id: UUID
    let score: Int // 0-100
    let interpretation: String
    let trend: Trend
    let lastUpdated: Date

    enum Trend: String, Codable {
        case improving
        case stable
        case declining
    }

    var color: Color {
        switch score {
        case 80...100:
            return .green
        case 50...79:
            return .orange
        default:
            return .red
        }
    }

    var gradientColors: [Color] {
        switch score {
        case 80...100:
            return [Color.green.opacity(0.8), Color.green]
        case 50...79:
            return [Color.orange.opacity(0.8), Color.orange]
        default:
            return [Color.red.opacity(0.8), Color.red]
        }
    }

    var statusText: String {
        switch score {
        case 80...100:
            return "Excellent"
        case 50...79:
            return "Moderate"
        default:
            return "Poor"
        }
    }

    init(id: UUID = UUID(), score: Int, interpretation: String, trend: Trend, lastUpdated: Date = Date()) {
        self.id = id
        self.score = min(100, max(0, score))
        self.interpretation = interpretation
        self.trend = trend
        self.lastUpdated = lastUpdated
    }
}
