import Foundation

// MARK: - Bill Analysis Response
struct BillAnalysis: Codable {
    // Core Information
    let provider: String
    let amount: Double
    let billDate: String
    let dueDate: String?
    let accountNumber: String?
    let category: String
    let zipCode: String?

    // Detailed Information
    let keyFacts: [KeyFact]?
    let lineItems: [LineItem]
    let costBreakdown: [CostBreakdown]?
    let insights: [Insight]?
    let marketplaceComparison: MarketplaceComparison?

    // Legacy compatibility - computed properties
    var totalAmount: Double { amount }
    var vendor: String? { provider }
    var date: Date? {
        ISO8601DateFormatter().date(from: billDate)
    }
    var potentialSavings: Double? {
        guard let comparison = marketplaceComparison else { return nil }
        // Show potential savings when user is paying ABOVE average
        if comparison.position == .above {
            return (amount - comparison.areaAverage)
        }
        return nil
    }

    // MARK: - Nested Types

    struct LineItem: Codable, Identifiable {
        let description: String
        let amount: Double
        let category: String?
        let quantity: Double?
        let rate: Double?
        let unit: String?
        let explanation: String?

        // Computed ID for Identifiable (not decoded from JSON)
        var id: String {
            "\(description)-\(amount)"
        }

        // Custom coding keys (exclude id from decoding)
        enum CodingKeys: String, CodingKey {
            case description
            case amount
            case category
            case quantity
            case rate
            case unit
            case explanation
        }

        init(description: String, amount: Double, category: String? = nil,
             quantity: Double? = nil, rate: Double? = nil, unit: String? = nil, explanation: String? = nil) {
            self.description = description
            self.amount = amount
            self.category = category
            self.quantity = quantity
            self.rate = rate
            self.unit = unit
            self.explanation = explanation
        }
    }

    struct KeyFact: Codable {
        let label: String
        let value: String
        let icon: String?
    }

    struct CostBreakdown: Codable {
        let category: String
        let amount: Double
        let percentage: Double
    }

    struct Insight: Codable {
        let type: InsightType
        let title: String
        let description: String

        enum InsightType: String, Codable {
            case savings
            case warning
            case info
            case success
        }
    }

    struct MarketplaceComparison: Codable {
        let areaAverage: Double
        let percentDiff: Double
        let zipPrefix: String
        let position: Position

        enum Position: String, Codable {
            case below
            case average
            case above
        }
    }
}
