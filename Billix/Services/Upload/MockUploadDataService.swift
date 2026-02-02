//
//  MockUploadDataService.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation

/// Static mock data for the upload feature
/// This provides realistic test data for all upload operations
struct MockUploadDataService {

    // MARK: - Bill Types

    static let billTypes: [BillType] = [
        // Utilities
        BillType(id: "electric", name: "Electric", icon: "bolt.fill", category: "Utilities"),
        BillType(id: "gas", name: "Natural Gas", icon: "flame.fill", category: "Utilities"),
        BillType(id: "water", name: "Water", icon: "drop.fill", category: "Utilities"),
        // Telecom
        BillType(id: "internet", name: "Internet", icon: "wifi", category: "Telecom"),
        BillType(id: "mobile", name: "Mobile Phone", icon: "iphone", category: "Telecom"),
        BillType(id: "cable", name: "Cable/TV", icon: "tv.fill", category: "Telecom"),
        // Insurance
        BillType(id: "insurance-auto", name: "Auto Insurance", icon: "car.fill", category: "Insurance"),
        BillType(id: "insurance-home", name: "Home Insurance", icon: "house.fill", category: "Insurance")
    ]

    // MARK: - Providers by ZIP (Realistic Data)

    static func getProviders(for zipCode: String, billType: BillType) -> [BillProvider] {
        let zipPrefix = String(zipCode.prefix(3))

        switch billType.id {
        case "electric":
            return electricProviders(for: zipPrefix)
        case "internet":
            return internetProviders(for: zipPrefix)
        case "mobile":
            return mobileProviders()
        case "cable":
            return cableProviders(for: zipPrefix)
        case "gas":
            return gasProviders(for: zipPrefix)
        default:
            return genericProviders(for: billType)
        }
    }

    private static func electricProviders(for zipPrefix: String) -> [BillProvider] {
        switch zipPrefix {
        case "481": // Ann Arbor, MI
            return [
                BillProvider(id: "dte", name: "DTE Energy", category: "utilities", avgAmount: 142.50, sampleSize: 47),
                BillProvider(id: "consumers", name: "Consumers Energy", category: "utilities", avgAmount: 128.75, sampleSize: 32)
            ]
        case "100", "101", "102": // New York City
            return [
                BillProvider(id: "coned", name: "Con Edison", category: "utilities", avgAmount: 185.00, sampleSize: 156),
                BillProvider(id: "psegli", name: "PSEG Long Island", category: "utilities", avgAmount: 168.25, sampleSize: 89)
            ]
        case "900", "901", "902": // Los Angeles
            return [
                BillProvider(id: "sce", name: "Southern California Edison", category: "utilities", avgAmount: 156.80, sampleSize: 203),
                BillProvider(id: "ladwp", name: "LA Dept. of Water & Power", category: "utilities", avgAmount: 134.20, sampleSize: 178)
            ]
        default:
            return [
                BillProvider(id: "generic-electric", name: "Local Electric Company", category: "utilities", avgAmount: nil, sampleSize: nil)
            ]
        }
    }

    private static func internetProviders(for zipPrefix: String) -> [BillProvider] {
        return [
            BillProvider(id: "comcast", name: "Comcast Xfinity", category: "telecom", avgAmount: 89.99, sampleSize: 234),
            BillProvider(id: "att", name: "AT&T Internet", category: "telecom", avgAmount: 75.00, sampleSize: 189),
            BillProvider(id: "verizon", name: "Verizon Fios", category: "telecom", avgAmount: 99.99, sampleSize: 156),
            BillProvider(id: "spectrum", name: "Spectrum", category: "telecom", avgAmount: 69.99, sampleSize: 145),
            BillProvider(id: "cox", name: "Cox Communications", category: "telecom", avgAmount: 79.99, sampleSize: 98)
        ]
    }

    private static func mobileProviders() -> [BillProvider] {
        return [
            BillProvider(id: "verizon-mobile", name: "Verizon Wireless", category: "telecom", avgAmount: 85.00, sampleSize: 312),
            BillProvider(id: "att-mobile", name: "AT&T Wireless", category: "telecom", avgAmount: 78.50, sampleSize: 287),
            BillProvider(id: "tmobile", name: "T-Mobile", category: "telecom", avgAmount: 65.00, sampleSize: 256),
            BillProvider(id: "sprint", name: "Sprint", category: "telecom", avgAmount: 70.00, sampleSize: 134),
            BillProvider(id: "mint", name: "Mint Mobile", category: "telecom", avgAmount: 25.00, sampleSize: 89)
        ]
    }

    private static func cableProviders(for zipPrefix: String) -> [BillProvider] {
        return [
            BillProvider(id: "comcast-cable", name: "Comcast Xfinity TV", category: "entertainment", avgAmount: 125.00, sampleSize: 178),
            BillProvider(id: "directv", name: "DirecTV", category: "entertainment", avgAmount: 135.00, sampleSize: 145),
            BillProvider(id: "dish", name: "Dish Network", category: "entertainment", avgAmount: 110.00, sampleSize: 123)
        ]
    }

    private static func gasProviders(for zipPrefix: String) -> [BillProvider] {
        switch zipPrefix {
        case "481": // Ann Arbor, MI
            return [
                BillProvider(id: "dte-gas", name: "DTE Gas", category: "utilities", avgAmount: 65.00, sampleSize: 42),
                BillProvider(id: "consumers-gas", name: "Consumers Energy Gas", category: "utilities", avgAmount: 58.75, sampleSize: 38)
            ]
        default:
            return [
                BillProvider(id: "generic-gas", name: "Local Gas Company", category: "utilities", avgAmount: nil, sampleSize: nil)
            ]
        }
    }

    private static func genericProviders(for billType: BillType) -> [BillProvider] {
        return [
            BillProvider(id: "generic-\(billType.id)", name: "\(billType.name) Provider", category: billType.category.lowercased(), avgAmount: nil, sampleSize: nil)
        ]
    }

    // MARK: - Quick Add Results (Mock Calculations)

    static func calculateQuickAddResult(request: QuickAddRequest) -> QuickAddResult {
        // Mock calculation: determine if user is overpaying based on amount
        let areaAverage = calculateAreaAverage(billType: request.billType, zipCode: request.zipCode)
        let difference = request.amount - areaAverage
        let percentDiff = (difference / areaAverage) * 100

        let status: QuickAddResult.Status
        if percentDiff > 10 {
            status = .overpaying
        } else if percentDiff < -10 {
            status = .underpaying
        } else {
            status = .average
        }

        let potentialSavings: Double? = percentDiff > 10 ? difference * 0.7 : nil

        return QuickAddResult(
            billType: request.billType,
            provider: request.provider,
            amount: request.amount,
            frequency: request.frequency,
            areaAverage: areaAverage,
            percentDifference: percentDiff,
            status: status,
            potentialSavings: potentialSavings,
            message: generateResultMessage(status: status, percentDiff: percentDiff),
            ctaMessage: generateCtaMessage(status: status)
        )
    }

    private static func generateCtaMessage(status: QuickAddResult.Status) -> String {
        switch status {
        case .overpaying:
            return "Find where to save"
        case .underpaying:
            return "Optimize further"
        case .average:
            return "Discover insights"
        }
    }

    private static func calculateAreaAverage(billType: BillType, zipCode: String) -> Double {
        // Mock area averages based on bill type
        switch billType.id {
        case "electric":
            return Double.random(in: 100...150)
        case "gas":
            return Double.random(in: 40...70)
        case "water":
            return Double.random(in: 30...60)
        case "internet":
            return Double.random(in: 60...80)
        case "mobile":
            return Double.random(in: 50...70)
        case "cable":
            return Double.random(in: 80...120)
        case "insurance-auto":
            return Double.random(in: 120...180)
        case "insurance-home":
            return Double.random(in: 80...140)
        default:
            return 100.0
        }
    }

    private static func generateResultMessage(status: QuickAddResult.Status, percentDiff: Double) -> String {
        switch status {
        case .overpaying:
            return "You're paying \(Int(abs(percentDiff)))% more than Billix average"
        case .underpaying:
            return "Great deal! You're paying \(Int(abs(percentDiff)))% below Billix average"
        case .average:
            return "You're paying close to the Billix average"
        }
    }

    // MARK: - Mock Bill Analysis

    static func generateMockBillAnalysis(fileName: String, source: UploadSource) -> BillAnalysis {
        let provider = ["DTE Energy", "Comcast", "AT&T", "Verizon", "Con Edison"].randomElement()!
        let amount = Double.random(in: 80...200)
        let zipCode = ["48104", "10001", "90001", "60601", "77001"].randomElement()!

        return BillAnalysis(
            provider: provider,
            amount: amount,
            billDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 15)),
            dueDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 15)),
            accountNumber: String(format: "%010d", Int.random(in: 1000000000...9999999999)),
            category: "Utilities",
            zipCode: zipCode,
            keyFacts: generateKeyFacts(provider: provider),
            lineItems: generateLineItems(totalAmount: amount),
            costBreakdown: generateCostBreakdown(),
            insights: generateInsights(amount: amount),
            marketplaceComparison: BillAnalysis.MarketplaceComparison(
                areaAverage: amount * 0.87,
                percentDiff: 13.0,
                zipPrefix: String(zipCode.prefix(3)),
                position: .above,
                state: "MI",
                sampleSize: 35
            ),
            plainEnglishSummary: nil,
            redFlags: nil,
            controllableCosts: nil,
            savingsOpportunities: nil,
            jargonGlossary: nil,
            assistancePrograms: nil
        )
    }

    private static func generateKeyFacts(provider: String) -> [BillAnalysis.KeyFact] {
        return [
            BillAnalysis.KeyFact(label: "Usage", value: "\(Int.random(in: 400...600)) kWh", icon: "bolt.fill"),
            BillAnalysis.KeyFact(label: "Rate", value: "$\(String(format: "%.2f", Double.random(in: 0.12...0.30)))/kWh", icon: "dollarsign.circle.fill"),
            BillAnalysis.KeyFact(label: "Days", value: "\(Int.random(in: 28...31)) days", icon: "calendar")
        ]
    }

    private static func generateLineItems(totalAmount: Double) -> [BillAnalysis.LineItem] {
        let supplyAmount = totalAmount * 0.65
        let deliveryAmount = totalAmount * 0.28
        let feesAmount = totalAmount * 0.07

        return [
            BillAnalysis.LineItem(
                description: "Electricity Supply",
                amount: supplyAmount,
                category: "Supply",
                quantity: 450,
                rate: supplyAmount / 450,
                unit: "kWh",
                explanation: "Cost of electricity generation"
            ),
            BillAnalysis.LineItem(
                description: "Delivery Charges",
                amount: deliveryAmount,
                category: "Delivery",
                quantity: nil,
                rate: nil,
                unit: nil,
                explanation: "Infrastructure maintenance and delivery"
            ),
            BillAnalysis.LineItem(
                description: "Taxes & Fees",
                amount: feesAmount,
                category: "Fees",
                quantity: nil,
                rate: nil,
                unit: nil,
                explanation: "State and local taxes"
            )
        ]
    }

    private static func generateCostBreakdown() -> [BillAnalysis.CostBreakdown] {
        return [
            BillAnalysis.CostBreakdown(category: "Supply", amount: 85.0, percentage: 65.0),
            BillAnalysis.CostBreakdown(category: "Delivery", amount: 35.0, percentage: 28.0),
            BillAnalysis.CostBreakdown(category: "Fees", amount: 10.0, percentage: 7.0)
        ]
    }

    private static func generateInsights(amount: Double) -> [BillAnalysis.Insight] {
        return [
            BillAnalysis.Insight(
                type: .warning,
                title: "Higher Than Average",
                description: "Your bill is 13% above the area average"
            ),
            BillAnalysis.Insight(
                type: .savings,
                title: "Potential Savings",
                description: "Switch to off-peak hours to save $\(Int(amount * 0.08))-\(Int(amount * 0.12))/month"
            )
        ]
    }

    // MARK: - Recent Uploads

    static func generateRecentUploads() -> [RecentUpload] {
        return [
            RecentUpload(
                id: UUID(),
                provider: "DTE Energy",
                amount: 124.56,
                source: .camera,
                status: .analyzed,
                uploadDate: Date().addingTimeInterval(-86400 * 2),
                thumbnailName: nil
            ),
            RecentUpload(
                id: UUID(),
                provider: "Comcast",
                amount: 89.99,
                source: .quickAdd,
                status: .analyzed,
                uploadDate: Date().addingTimeInterval(-86400 * 5),
                thumbnailName: nil
            ),
            RecentUpload(
                id: UUID(),
                provider: "AT&T Internet",
                amount: 65.00,
                source: .camera,
                status: .analyzed,
                uploadDate: Date().addingTimeInterval(-86400 * 7),
                thumbnailName: nil
            ),
            RecentUpload(
                id: UUID(),
                provider: "City Water Department",
                amount: 42.30,
                source: .quickAdd,
                status: .analyzed,
                uploadDate: Date().addingTimeInterval(-86400 * 10),
                thumbnailName: nil
            ),
            RecentUpload(
                id: UUID(),
                provider: "Netflix",
                amount: 15.49,
                source: .quickAdd,
                status: .analyzed,
                uploadDate: Date().addingTimeInterval(-86400 * 14),
                thumbnailName: nil
            ),
            RecentUpload(
                id: UUID(),
                provider: "State Farm Auto Insurance",
                amount: 156.80,
                source: .photos,
                status: .analyzed,
                uploadDate: Date().addingTimeInterval(-86400 * 18),
                thumbnailName: nil
            ),
            RecentUpload(
                id: UUID(),
                provider: "Unknown",
                amount: 0.0,
                source: .photos,
                status: .processing,
                uploadDate: Date().addingTimeInterval(-3600),
                thumbnailName: nil
            )
        ]
    }
}
