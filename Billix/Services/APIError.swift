import Foundation

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(String)
    case networkError(Error)
    case fileValidationFailed(String)
    case authenticationRequired
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .fileValidationFailed(let message):
            return message
        case .authenticationRequired:
            return "Please log in to continue"
        case .unauthorized:
            return "Your session has expired. Please log in again"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .unauthorized, .authenticationRequired:
            return "Please log in to continue using this feature."
        case .fileValidationFailed:
            return "Please upload a valid PDF, PNG, JPEG, or HEIC file under 10MB."
        case .serverError:
            return "Please try again. If the problem persists, contact support."
        default:
            return "Please try again later."
        }
    }
}
