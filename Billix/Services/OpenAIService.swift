//
//  OpenAIService.swift
//  Billix
//
//  Calls Supabase Edge Function for AI-powered content generation
//  OpenAI API key is stored securely on the server side
//

import Foundation
import Supabase

// MARK: - Request/Response Models

struct AIContentRequest: Codable {
    let type: String // "weather_tip", "daily_brief", "national_averages"
    let context: AIContext

    struct AIContext: Codable {
        var zipCode: String?
        var city: String?
        var state: String?
        var temperature: Double?
        var weatherCondition: String?
        var billTypes: [String]?
        var billType: String?
        var upcomingBillName: String?
        var upcomingBillDays: Int?
    }
}

struct AIContentResponse: Codable {
    let success: Bool
    let content: String?
    let data: AIData?
    let error: String?

    struct AIData: Codable {
        var averages: [BillAverage]?
    }
}

struct BillAverage: Codable, Identifiable {
    var id: String { billType }
    let billType: String
    let average: Double
    let low: Double
    let high: Double
    let percentile: String?

    enum CodingKeys: String, CodingKey {
        case billType = "bill_type"
        case average, low, high, percentile
    }
}

// MARK: - OpenAI Service

@MainActor
class OpenAIService: ObservableObject {

    // MARK: - Singleton
    static let shared = OpenAIService()

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var lastError: String?

    // MARK: - Cache
    private var weatherTipCache: (tip: String, timestamp: Date)?
    private var dailyBriefCache: (brief: String, timestamp: Date)?
    private var nationalAveragesCache: [String: (averages: [BillAverage], timestamp: Date)] = [:]

    private let cacheTimeout: TimeInterval = 3600 // 1 hour

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private init() {}

    // MARK: - Weather Tip

    /// Generate a personalized weather-based bill-saving tip
    func generateWeatherTip(
        temperature: Double,
        condition: String,
        zipCode: String,
        city: String?,
        billTypes: [String]
    ) async throws -> String {
        // Check cache
        if let cached = weatherTipCache,
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return cached.tip
        }

        let request = AIContentRequest(
            type: "weather_tip",
            context: .init(
                zipCode: zipCode,
                city: city,
                temperature: temperature,
                weatherCondition: condition,
                billTypes: billTypes
            )
        )

        let response = try await callEdgeFunction(request: request)

        if let tip = response.content {
            weatherTipCache = (tip, Date())
            return tip
        }

        throw OpenAIError.noContent
    }

    // MARK: - Daily Brief

    /// Generate a personalized daily financial brief
    func generateDailyBrief(
        zipCode: String,
        city: String?,
        state: String?,
        temperature: Double?,
        weatherCondition: String?,
        billTypes: [String],
        upcomingBillName: String?,
        upcomingBillDays: Int?
    ) async throws -> String {
        // Check cache
        if let cached = dailyBriefCache,
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return cached.brief
        }

        let request = AIContentRequest(
            type: "daily_brief",
            context: .init(
                zipCode: zipCode,
                city: city,
                state: state,
                temperature: temperature,
                weatherCondition: weatherCondition,
                billTypes: billTypes,
                upcomingBillName: upcomingBillName,
                upcomingBillDays: upcomingBillDays
            )
        )

        let response = try await callEdgeFunction(request: request)

        if let brief = response.content {
            dailyBriefCache = (brief, Date())
            return brief
        }

        throw OpenAIError.noContent
    }

    // MARK: - National Averages

    /// Get national average bill costs for a ZIP code
    func getNationalAverages(zipCode: String) async throws -> [BillAverage] {
        // Check cache
        if let cached = nationalAveragesCache[zipCode],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return cached.averages
        }

        let request = AIContentRequest(
            type: "national_averages",
            context: .init(zipCode: zipCode)
        )

        let response = try await callEdgeFunction(request: request)

        if let averages = response.data?.averages {
            nationalAveragesCache[zipCode] = (averages, Date())
            return averages
        }

        // Return fallback data if API fails
        return getFallbackAverages()
    }

    // MARK: - Private Methods

    private func callEdgeFunction(request: AIContentRequest) async throws -> AIContentResponse {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            // Call Supabase Edge Function
            let response: AIContentResponse = try await supabase.functions
                .invoke(
                    "generate-content",
                    options: .init(body: request)
                )

            if let error = response.error {
                lastError = error
                throw OpenAIError.apiError(error)
            }

            return response

        } catch let error as OpenAIError {
            throw error
        } catch {
            lastError = error.localizedDescription
            print("❌ OpenAI Edge Function error: \(error)")
            throw OpenAIError.networkError(error)
        }
    }

    /// Fallback averages when API is unavailable
    private func getFallbackAverages() -> [BillAverage] {
        [
            BillAverage(billType: "Electric", average: 142, low: 90, high: 200, percentile: nil),
            BillAverage(billType: "Internet", average: 65, low: 45, high: 100, percentile: nil),
            BillAverage(billType: "Gas", average: 78, low: 40, high: 150, percentile: nil),
            BillAverage(billType: "Phone", average: 85, low: 50, high: 120, percentile: nil)
        ]
    }

    /// Clear all caches
    func clearCache() {
        weatherTipCache = nil
        dailyBriefCache = nil
        nationalAveragesCache.removeAll()
    }
}

// MARK: - OpenAI Errors

enum OpenAIError: LocalizedError {
    case noContent
    case apiError(String)
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noContent:
            return "No content received from AI"
        case .apiError(let message):
            return "AI Error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI service"
        }
    }
}
