import Foundation

struct Config {
    // Supabase Configuration
    static let supabaseURL = "https://pkecbalzzcndewlftiit.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBrZWNiYWx6emNuZGV3bGZ0aWl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzExNzI3NzEsImV4cCI6MjA0Njc0ODc3MX0.kx9m8wZQVGCZQXSYN8Og_qPINCz_uZvq3aUuQ9XaZHo"

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
}
