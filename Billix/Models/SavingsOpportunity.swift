import Foundation
import SwiftUI

struct SavingsOpportunity: Codable, Identifiable {
    let id: UUID
    let billName: String
    let currentProvider: String
    let recommendedProvider: String
    let currentPrice: Double
    let truePriceAverage: Double
    let potentialSavings: Double
    let category: BillCategory
    let providerLogoURL: String?

    enum BillCategory: String, Codable {
        case internet
        case phone
        case electricity
        case gas
        case water
        case insurance
        case streaming
        case other

        var icon: String {
            switch self {
            case .internet: return "wifi"
            case .phone: return "phone.fill"
            case .electricity: return "bolt.fill"
            case .gas: return "flame.fill"
            case .water: return "drop.fill"
            case .insurance: return "shield.fill"
            case .streaming: return "play.rectangle.fill"
            case .other: return "doc.fill"
            }
        }

        var color: Color {
            switch self {
            case .internet: return .blue
            case .phone: return .green
            case .electricity: return .yellow
            case .gas: return .orange
            case .water: return .cyan
            case .insurance: return .purple
            case .streaming: return .pink
            case .other: return .gray
            }
        }
    }

    var savingsPercentage: Double {
        guard currentPrice > 0 else { return 0 }
        return (potentialSavings / currentPrice) * 100
    }

    var truePriceProgress: Double {
        guard truePriceAverage > 0 else { return 0 }
        return min(1.0, currentPrice / truePriceAverage)
    }

    init(id: UUID = UUID(),
         billName: String,
         currentProvider: String,
         recommendedProvider: String,
         currentPrice: Double,
         truePriceAverage: Double,
         potentialSavings: Double,
         category: BillCategory,
         providerLogoURL: String? = nil) {
        self.id = id
        self.billName = billName
        self.currentProvider = currentProvider
        self.recommendedProvider = recommendedProvider
        self.currentPrice = currentPrice
        self.truePriceAverage = truePriceAverage
        self.potentialSavings = potentialSavings
        self.category = category
        self.providerLogoURL = providerLogoURL
    }
}
