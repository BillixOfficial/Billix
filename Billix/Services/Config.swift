import Foundation

struct Config {
    // Supabase Configuration
    static let supabaseURL = "https://pkecbalzzcndewlftiit.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBrZWNiYWx6emNuZGV3bGZ0aWl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3OTY1MzksImV4cCI6MjA3NjM3MjUzOX0.hu67o5d3XNkqGOdrusnj6vmqkeyNCWuRtF5r_hpehjo"

    // Backend API Configuration (LAW_4_ME)
    static let apiBaseURL = "https://www.billixapp.com"
    static let apiVersion = "v1"

    // API Endpoints
    static var billUploadEndpoint: String {
        "\(apiBaseURL)/api/\(apiVersion)/bills/upload"
    }

    static var marketplaceEndpoint: String {
        "\(apiBaseURL)/api/\(apiVersion)/marketplace"
    }

    static var housingMarketEndpoint: String {
        "\(apiBaseURL)/api/\(apiVersion)/housing-market"
    }

    // RentCast API Configuration
    static let rentcastAPIURL = "https://api.rentcast.io/v1"
    static let rentcastAPIKey = "YOUR_API_KEY_HERE"  // TODO: Replace with real API key

    // RentCast Endpoints
    static var rentcastMarketsEndpoint: String {
        "\(rentcastAPIURL)/markets"
    }

    static var rentcastRentEstimateEndpoint: String {
        "\(rentcastAPIURL)/avm/rent/long-term"
    }

    static var rentcastListingsEndpoint: String {
        "\(rentcastAPIURL)/listings/rental/long-term"
    }
}
