import Foundation

/// Comprehensive network error types for the Explore feature
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)
    case cacheError(String)
    case timeout
    case noInternetConnection

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please try again."
        case .invalidResponse:
            return "Invalid response from server."
        case .unauthorized:
            return "You need to log in to access this feature."
        case .notFound:
            return "The requested data was not found."
        case .serverError(let message):
            return "Server error: \(message)"
        case .decodingError:
            return "Failed to process server response."
        case .networkError:
            return "Network error. Please check your connection."
        case .cacheError(let message):
            return "Cache error: \(message)"
        case .timeout:
            return "Request timed out. Please try again."
        case .noInternetConnection:
            return "No internet connection. Please check your network."
        }
    }

    var userFriendlyMessage: String {
        switch self {
        case .invalidURL, .invalidResponse, .decodingError:
            return "Something went wrong. Please try again."
        case .unauthorized:
            return "Please log in to continue."
        case .notFound:
            return "No data found for this location."
        case .serverError:
            return "Our servers are having issues. Please try again later."
        case .networkError, .timeout, .noInternetConnection:
            return "Connection issue. Please check your internet."
        case .cacheError:
            return "Failed to load cached data."
        }
    }

    var shouldRetry: Bool {
        switch self {
        case .networkError, .timeout, .serverError, .noInternetConnection:
            return true
        default:
            return false
        }
    }
}
