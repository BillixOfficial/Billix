//
//  WeatherService.swift
//  Billix
//
//  Fetches weather data via Supabase Edge Function (API key stored server-side)
//

import Foundation
import Supabase

// MARK: - Weather Models

struct WeatherEdgeResponse: Codable {
    let success: Bool
    let data: WeatherEdgeData?
    let error: String?
}

struct WeatherEdgeData: Codable {
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let condition: String
    let conditionDescription: String
    let cityName: String
    let icon: String
}

struct WeatherData {
    let temperature: Double // Fahrenheit
    let feelsLike: Double
    let humidity: Int
    let condition: String
    let conditionDescription: String
    let cityName: String
    let icon: String

    var temperatureInt: Int {
        Int(round(temperature))
    }

    var feelsLikeInt: Int {
        Int(round(feelsLike))
    }

    var isHot: Bool {
        temperature >= 85
    }

    var isCold: Bool {
        temperature <= 40
    }

    var isMild: Bool {
        temperature > 40 && temperature < 85
    }
}

// MARK: - Weather Service

@MainActor
class WeatherService: ObservableObject {

    // MARK: - Singleton
    static let shared = WeatherService()

    // MARK: - Published Properties
    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    @Published var lastError: String?

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // Cache to avoid excessive API calls
    private var weatherCache: (zipCode: String, weather: WeatherData, timestamp: Date)?
    private let cacheTimeout: TimeInterval = 1800 // 30 minutes

    private init() {}

    // MARK: - Public Methods

    /// Fetch weather for a ZIP code via Supabase Edge Function
    func fetchWeather(zipCode: String) async throws {
        guard !zipCode.isEmpty else {
            return
        }

        // Check cache first
        if let cached = weatherCache,
           cached.zipCode == zipCode,
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            self.currentWeather = cached.weather
            return
        }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            // Call Supabase Edge Function
            let response: WeatherEdgeResponse = try await supabase.functions
                .invoke(
                    "get-weather",
                    options: .init(body: ["zipCode": zipCode])
                )

            if let error = response.error {
                lastError = error
                throw WeatherError.apiError(error)
            }

            guard let data = response.data else {
                throw WeatherError.noData
            }

            // Convert to WeatherData
            let weather = WeatherData(
                temperature: data.temperature,
                feelsLike: data.feelsLike,
                humidity: data.humidity,
                condition: data.condition,
                conditionDescription: data.conditionDescription,
                cityName: data.cityName,
                icon: data.icon
            )

            // Update cache
            weatherCache = (zipCode, weather, Date())

            self.currentWeather = weather

        } catch let error as WeatherError {
            throw error
        } catch {
            lastError = error.localizedDescription
            print("❌ WeatherService error: \(error)")
            throw WeatherError.networkError(error)
        }
    }

    /// Get a bill-saving tip based on current weather
    func getWeatherBasedTip() -> String? {
        guard let weather = currentWeather else { return nil }

        if weather.isHot {
            return "It's \(weather.temperatureInt)°F today. Set your AC to 78° to save ~$8 this week."
        } else if weather.isCold {
            return "It's \(weather.temperatureInt)°F today. Lower your thermostat 1° to save ~3% on heating."
        } else if weather.condition.lowercased().contains("rain") {
            return "Rainy day - great time to review your bills indoors!"
        } else if weather.isMild {
            return "Perfect weather to skip the AC. Open windows and save ~$15 this week."
        }

        return nil
    }

    /// Get weather icon SF Symbol name
    func getWeatherIcon() -> String {
        guard let weather = currentWeather else { return "cloud.fill" }

        switch weather.condition.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "thunderstorm":
            return "cloud.bolt.rain.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog", "haze":
            return "cloud.fog.fill"
        default:
            return "cloud.fill"
        }
    }

    /// Clear weather cache
    func clearCache() {
        weatherCache = nil
    }
}

// MARK: - Weather Errors

enum WeatherError: LocalizedError {
    case noData
    case apiError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noData:
            return "No weather data received"
        case .apiError(let message):
            return "Weather API error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
