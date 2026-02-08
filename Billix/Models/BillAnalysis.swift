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

    // Enhanced Analysis (New Fields)
    let plainEnglishSummary: String?
    let redFlags: [RedFlag]?
    let controllableCosts: ControlAnalysis?
    let savingsOpportunities: [ActionItem]?
    let jargonGlossary: [GlossaryTerm]?
    let assistancePrograms: [AssistanceProgram]?

    // Raw extracted text for AI chat context (from upload response)
    let rawExtractedText: String?

    // MARK: - Coding Keys (Map Swift names to backend field names)
    private enum CodingKeys: String, CodingKey {
        case provider, amount, billDate, dueDate, accountNumber
        case category, zipCode, keyFacts, lineItems
        case costBreakdown, insights, marketplaceComparison
        case plainEnglishSummary
        case redFlags
        case controllableCosts = "controlAnalysis"
        case savingsOpportunities = "actionItems"
        case jargonGlossary = "glossary"
        case assistancePrograms
        case rawExtractedText
    }

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

    // MARK: - Validation

    /// Validates that this analysis represents a valid bill
    /// - Returns: true if amount > 0, provider is not empty, and has at least 1 line item
    func isValidBill() -> Bool {
        return amount > 0
            && !provider.trimmingCharacters(in: .whitespaces).isEmpty
            && !lineItems.isEmpty
    }

    // MARK: - Copying with Raw Text

    /// Creates a copy of this analysis with rawExtractedText set
    /// Used when merging the upload response (analysis + rawExtractedText at top level)
    func withRawExtractedText(_ text: String?) -> BillAnalysis {
        BillAnalysis(
            provider: provider,
            amount: amount,
            billDate: billDate,
            dueDate: dueDate,
            accountNumber: accountNumber,
            category: category,
            zipCode: zipCode,
            keyFacts: keyFacts,
            lineItems: lineItems,
            costBreakdown: costBreakdown,
            insights: insights,
            marketplaceComparison: marketplaceComparison,
            plainEnglishSummary: plainEnglishSummary,
            redFlags: redFlags,
            controllableCosts: controllableCosts,
            savingsOpportunities: savingsOpportunities,
            jargonGlossary: jargonGlossary,
            assistancePrograms: assistancePrograms,
            rawExtractedText: text
        )
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
        let isNegotiable: Bool?
        let isAvoidable: Bool?

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
            case isNegotiable
            case isAvoidable
        }

        init(description: String, amount: Double, category: String? = nil,
             quantity: Double? = nil, rate: Double? = nil, unit: String? = nil, explanation: String? = nil,
             isNegotiable: Bool? = nil, isAvoidable: Bool? = nil) {
            self.description = description
            self.amount = amount
            self.category = category
            self.quantity = quantity
            self.rate = rate
            self.unit = unit
            self.explanation = explanation
            self.isNegotiable = isNegotiable
            self.isAvoidable = isAvoidable
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
        let state: String?        // 2-letter state code (e.g., "AZ")
        let sampleSize: Int?      // Number of bills compared against

        enum Position: String, Codable {
            case below
            case average
            case above
        }
    }

    struct RedFlag: Codable, Identifiable {
        let type: String  // "high" | "medium" | "low"
        let description: String
        let recommendation: String
        let potentialSavings: Double?

        // Stable ID for SwiftUI Identifiable (not decoded from JSON)
        let id = UUID()

        // Exclude id from Codable
        private enum CodingKeys: String, CodingKey {
            case type, description, recommendation, potentialSavings
        }

        init(type: String, description: String, recommendation: String, potentialSavings: Double? = nil) {
            self.type = type
            self.description = description
            self.recommendation = recommendation
            self.potentialSavings = potentialSavings
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(String.self, forKey: .type)
            description = try container.decode(String.self, forKey: .description)
            recommendation = try container.decode(String.self, forKey: .recommendation)
            // Handle potentialSavings as either Double or String
            if let doubleVal = try? container.decode(Double.self, forKey: .potentialSavings) {
                potentialSavings = doubleVal
            } else if let stringVal = try? container.decode(String.self, forKey: .potentialSavings),
                      let parsed = Double(stringVal) {
                potentialSavings = parsed
            } else {
                potentialSavings = nil
            }
        }
    }

    struct ControlAnalysis: Codable {
        let fixedCosts: CostDetail
        let variableCosts: CostDetail
        let controllablePercentage: Double

        struct CostDetail: Codable {
            let total: Double
            let items: [String]
            let explanation: String
        }
    }

    struct ActionItem: Codable, Identifiable {
        let action: String
        let explanation: String
        let potentialSavings: Double?
        let difficulty: String  // "easy" | "medium" | "hard"
        let category: String

        // Stable ID for SwiftUI Identifiable (not decoded from JSON)
        let id = UUID()

        // Exclude id from Codable
        private enum CodingKeys: String, CodingKey {
            case action, explanation, potentialSavings, difficulty, category
        }

        init(action: String, explanation: String, potentialSavings: Double? = nil,
             difficulty: String, category: String) {
            self.action = action
            self.explanation = explanation
            self.potentialSavings = potentialSavings
            self.difficulty = difficulty
            self.category = category
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            action = try container.decode(String.self, forKey: .action)
            explanation = try container.decode(String.self, forKey: .explanation)
            difficulty = try container.decode(String.self, forKey: .difficulty)
            category = try container.decode(String.self, forKey: .category)
            // Handle potentialSavings as either Double or String
            if let doubleVal = try? container.decode(Double.self, forKey: .potentialSavings) {
                potentialSavings = doubleVal
            } else if let stringVal = try? container.decode(String.self, forKey: .potentialSavings),
                      let parsed = Double(stringVal) {
                potentialSavings = parsed
            } else {
                potentialSavings = nil
            }
        }
    }

    struct GlossaryTerm: Codable, Identifiable {
        let term: String
        let definition: String
        let context: String

        // Stable ID for SwiftUI Identifiable (not decoded from JSON)
        let id = UUID()

        // Exclude id from Codable
        private enum CodingKeys: String, CodingKey {
            case term, definition, context
        }
    }

    struct AssistanceProgram: Codable, Identifiable {
        let title: String
        let description: String
        let programType: ProgramType
        let eligibility: String
        let applicationUrl: String?
        let phoneNumber: String?
        let estimatedBenefit: String  // "Up to $200/year" or "$100-500/year"
        let provider: String

        // Stable ID for SwiftUI Identifiable (not decoded from JSON)
        let id = UUID()

        enum ProgramType: String, Codable {
            case government, utility, local, nonprofit
        }

        // Exclude id from Codable
        private enum CodingKeys: String, CodingKey {
            case title, description, programType, eligibility
            case applicationUrl, phoneNumber, estimatedBenefit, provider
        }
    }
}
