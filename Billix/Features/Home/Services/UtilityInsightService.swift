//
//  UtilityInsightService.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation
import Supabase

// MARK: - Models

/// Types of personal utility insights that cycle daily
enum UtilityInsightType: String, CaseIterable {
    case usageAnomaly = "usage_anomaly"
    case billForecast = "bill_forecast"
    case efficiencyCheck = "efficiency_check"
    case marketOpportunity = "market_opportunity"

    var title: String {
        switch self {
        case .usageAnomaly: return "Usage Anomaly"
        case .billForecast: return "Bill Forecast"
        case .efficiencyCheck: return "Efficiency Check"
        case .marketOpportunity: return "Market Opportunity"
        }
    }

    var icon: String {
        switch self {
        case .usageAnomaly: return "chart.line.uptrend.xyaxis"
        case .billForecast: return "calendar.badge.clock"
        case .efficiencyCheck: return "leaf.fill"
        case .marketOpportunity: return "sparkles"
        }
    }

    var color: String {
        switch self {
        case .usageAnomaly: return "#FF9500"    // Orange
        case .billForecast: return "#5856D6"    // Purple
        case .efficiencyCheck: return "#34C759" // Green
        case .marketOpportunity: return "#007AFF" // Blue
        }
    }
}

/// Personal utility insight for the bottom card
struct PersonalInsight {
    let type: UtilityInsightType
    let headline: String
    let detail: String
    let actionText: String?
    let hasData: Bool
}

/// Signal type for regional utility checkup
enum RegionalSignalType: String, Codable {
    case stable = "stable"
    case earlySignal = "early_signal"
    case costPressure = "cost_pressure"
    case limitedData = "limited_data"

    var emoji: String {
        switch self {
        case .stable: return "🟢"
        case .earlySignal: return "🟡"
        case .costPressure: return "🔴"
        case .limitedData: return "⚪"
        }
    }

    var label: String {
        switch self {
        case .stable: return "Stable"
        case .earlySignal: return "Early Signal"
        case .costPressure: return "Cost Pressure"
        case .limitedData: return "Limited Data"
        }
    }

    var description: String {
        switch self {
        case .stable: return "Costs consistent in your area"
        case .earlySignal: return "Some changes detected"
        case .costPressure: return "Elevated costs reported"
        case .limitedData: return "Need more community data"
        }
    }
}

/// Regional utility signal from database
struct RegionalUtilitySignal: Codable, Identifiable {
    let id: UUID
    let zipPrefix: String
    let category: String
    let signalType: String
    let confidenceLevel: Int
    let sampleSize: Int
    let avgChangePercent: Double?
    let trendDirection: String?
    let insightText: String?
    let dataFreshnessDays: Int
    let lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case id
        case zipPrefix = "zip_prefix"
        case category
        case signalType = "signal_type"
        case confidenceLevel = "confidence_level"
        case sampleSize = "sample_size"
        case avgChangePercent = "avg_change_percent"
        case trendDirection = "trend_direction"
        case insightText = "insight_text"
        case dataFreshnessDays = "data_freshness_days"
        case lastUpdated = "last_updated"
    }

    var signal: RegionalSignalType {
        RegionalSignalType(rawValue: signalType) ?? .limitedData
    }

    var categoryDisplay: String {
        switch category {
        case "energy": return "Energy"
        case "gas": return "Gas"
        case "water": return "Water"
        case "internet": return "Internet"
        case "mobile": return "Mobile"
        default: return category.capitalized
        }
    }

    var categoryIcon: String {
        switch category {
        case "energy": return "bolt.fill"
        case "gas": return "flame.fill"
        case "water": return "drop.fill"
        case "internet": return "wifi"
        case "mobile": return "antenna.radiowaves.left.and.right"
        default: return "dollarsign.circle.fill"
        }
    }
}

/// Complete utility checkup result
struct UtilityCheckup {
    let signals: [RegionalUtilitySignal]
    let overallStatus: RegionalSignalType
    let lastRefreshed: Date
    let zipPrefix: String

    var isEmpty: Bool {
        signals.isEmpty
    }
}

// MARK: - Protocol

protocol UtilityInsightServiceProtocol {
    // Personal Insights (dual card)
    func getTodaysInsightType() -> UtilityInsightType
    func getPersonalInsight() async throws -> PersonalInsight

    // Regional Checkup (replaces MicroTasks)
    func getRegionalCheckup() async throws -> UtilityCheckup
    func getSignalsForZip(_ zipPrefix: String) async throws -> [RegionalUtilitySignal]
}

// MARK: - Service Implementation

@MainActor
class UtilityInsightService: UtilityInsightServiceProtocol {

    // MARK: - Singleton
    static let shared = UtilityInsightService()

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // Cache for regional signals
    private var cachedSignals: [RegionalUtilitySignal] = []
    private var cacheZipPrefix: String?
    private var cacheDate: Date?

    // MARK: - Initialization
    private init() {}

    // MARK: - Personal Insight Methods

    /// Get today's insight type based on day of week cycling
    func getTodaysInsightType() -> UtilityInsightType {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let types = UtilityInsightType.allCases
        let index = (dayOfYear - 1) % types.count
        return types[index]
    }

    /// Get personalized insight for the bottom card
    func getPersonalInsight() async throws -> PersonalInsight {
        let insightType = getTodaysInsightType()

        // Check if user has bills uploaded
        let hasBills = try await userHasBills()

        if !hasBills {
            return PersonalInsight(
                type: insightType,
                headline: "Upload your first bill",
                detail: "Get personalized insights about your utility costs",
                actionText: "Upload Bill",
                hasData: false
            )
        }

        // Generate insight based on type
        // In a real implementation, this would analyze user's bill data
        switch insightType {
        case .usageAnomaly:
            return PersonalInsight(
                type: insightType,
                headline: "Usage looks normal",
                detail: "Your energy consumption is within typical range for this time of year",
                actionText: "View Details",
                hasData: true
            )

        case .billForecast:
            return PersonalInsight(
                type: insightType,
                headline: "Next bill estimate ready",
                detail: "Based on current usage patterns, we've projected your upcoming costs",
                actionText: "See Forecast",
                hasData: true
            )

        case .efficiencyCheck:
            return PersonalInsight(
                type: insightType,
                headline: "Efficiency score updated",
                detail: "Your household efficiency compared to similar homes in your area",
                actionText: "Check Score",
                hasData: true
            )

        case .marketOpportunity:
            return PersonalInsight(
                type: insightType,
                headline: "Market insights available",
                detail: "New rate options and provider offers in your region",
                actionText: "Explore",
                hasData: true
            )
        }
    }

    // MARK: - Regional Checkup Methods

    /// Get regional utility checkup for user's area
    func getRegionalCheckup() async throws -> UtilityCheckup {
        // Get user's ZIP prefix
        let zipPrefix = try await getUserZipPrefix()

        // Check cache
        if let cached = cacheZipPrefix,
           cached == zipPrefix,
           let cacheDate = cacheDate,
           Date().timeIntervalSince(cacheDate) < 3600 { // 1 hour cache
            return buildCheckup(from: cachedSignals, zipPrefix: zipPrefix)
        }

        // Fetch signals
        let signals = try await getSignalsForZip(zipPrefix)

        // Update cache
        cachedSignals = signals
        cacheZipPrefix = zipPrefix
        cacheDate = Date()

        return buildCheckup(from: signals, zipPrefix: zipPrefix)
    }

    /// Get signals for a specific ZIP prefix
    func getSignalsForZip(_ zipPrefix: String) async throws -> [RegionalUtilitySignal] {
        let response: [RegionalUtilitySignal] = try await supabase
            .from("regional_utility_signals")
            .select()
            .eq("zip_prefix", value: zipPrefix)
            .order("category", ascending: true)
            .execute()
            .value

        return response
    }

    // MARK: - Helper Methods

    private func userHasBills() async throws -> Bool {
        guard let session = try? await supabase.auth.session else {
            return false
        }

        struct BillCount: Codable {
            let count: Int
        }

        // Check bills table for user's bills
        let response: [BillCount] = try await supabase
            .from("bills")
            .select("id", head: false, count: .exact)
            .eq("user_id", value: session.user.id.uuidString)
            .limit(1)
            .execute()
            .value

        return !response.isEmpty
    }

    private func getUserZipPrefix() async throws -> String {
        guard let session = try? await supabase.auth.session else {
            return "100" // Default NYC area
        }

        struct VaultZip: Codable {
            let zipCode: String?

            enum CodingKeys: String, CodingKey {
                case zipCode = "zip_code"
            }
        }

        let response: [VaultZip] = try await supabase
            .from("user_vault")
            .select("zip_code")
            .eq("id", value: session.user.id.uuidString)
            .limit(1)
            .execute()
            .value

        if let zipCode = response.first?.zipCode, zipCode.count >= 3 {
            return String(zipCode.prefix(3))
        }

        return "100" // Default
    }

    private func buildCheckup(from signals: [RegionalUtilitySignal], zipPrefix: String) -> UtilityCheckup {
        // Determine overall status based on signals
        let overallStatus: RegionalSignalType
        if signals.isEmpty {
            overallStatus = .limitedData
        } else if signals.contains(where: { $0.signal == .costPressure }) {
            overallStatus = .costPressure
        } else if signals.contains(where: { $0.signal == .earlySignal }) {
            overallStatus = .earlySignal
        } else if signals.allSatisfy({ $0.signal == .stable || $0.signal == .limitedData }) {
            overallStatus = signals.contains(where: { $0.signal == .stable }) ? .stable : .limitedData
        } else {
            overallStatus = .stable
        }

        return UtilityCheckup(
            signals: signals,
            overallStatus: overallStatus,
            lastRefreshed: Date(),
            zipPrefix: zipPrefix
        )
    }

    /// Get confidence label for display
    func getConfidenceLabel(_ level: Int) -> String {
        switch level {
        case 0..<30: return "Low confidence"
        case 30..<60: return "Moderate confidence"
        case 60..<80: return "Good confidence"
        default: return "High confidence"
        }
    }

    /// Format sample size for display
    func formatSampleSize(_ size: Int) -> String {
        if size >= 100 {
            return "\(size)+ data points"
        } else if size >= 50 {
            return "\(size) data points"
        } else if size >= 10 {
            return "Limited data (\(size))"
        } else {
            return "Very limited data"
        }
    }

    /// Clear cache
    func clearCache() {
        cachedSignals = []
        cacheZipPrefix = nil
        cacheDate = nil
    }
}

// MARK: - Errors

enum UtilityInsightError: LocalizedError {
    case notAuthenticated
    case noDataAvailable
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in"
        case .noDataAvailable:
            return "No utility data available for your area"
        case .fetchFailed(let message):
            return "Failed to fetch data: \(message)"
        }
    }
}
