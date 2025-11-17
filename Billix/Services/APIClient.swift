import Foundation

/// API Client for communicating with the Billix backend (LAW_4_ME)
/// Handles bill upload, analysis, and marketplace interactions
class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    private init() {
        // Configure URLSession with timeout
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: configuration)

        // Configure JSON decoder for ISO8601 dates
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601

        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Bill Upload & Analysis

    /// Upload and analyze a bill using the LAW_4_ME backend
    /// - Parameters:
    ///   - fileData: The bill file data (PDF, PNG, JPEG, or HEIC)
    ///   - fileName: The original file name
    ///   - bearerToken: Optional authentication token for authenticated uploads
    /// - Returns: Complete bill analysis with AI insights
    /// - Throws: APIError if the upload or analysis fails
    func uploadAndAnalyzeBill(
        fileData: Data,
        fileName: String,
        bearerToken: String? = nil
    ) async throws -> BillAnalysis {
        // Validate file before uploading
        let validation = FileValidator.validate(fileData: fileData, fileName: fileName)
        guard validation.isValid else {
            throw APIError.fileValidationFailed(validation.errorMessage ?? "Invalid file")
        }

        // Create URL
        guard let url = URL(string: Config.billUploadEndpoint) else {
            throw APIError.invalidURL
        }

        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Add bearer token if authenticated
        if let token = bearerToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Build multipart body
        var body = Data()

        // Add file data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(getMimeType(for: fileName))\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        request.httpBody = body

        // Send request
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Handle different status codes
            switch httpResponse.statusCode {
            case 200:
                // Success - decode response
                do {
                    // Debug: Print raw response
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📦 Raw Response (first 500 chars): \(responseString.prefix(500))")
                    }

                    // Try to decode the full response wrapper first
                    do {
                        let uploadResponse = try jsonDecoder.decode(BillUploadResponse.self, from: data)
                        print("✅ Successfully decoded BillUploadResponse")
                        return uploadResponse.analysis
                    } catch {
                        print("⚠️ Failed to decode BillUploadResponse wrapper, trying direct analysis decode...")

                        // Fallback: Try to decode just the analysis field directly
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let analysisData = json["analysis"] as? [String: Any],
                           let analysisJson = try? JSONSerialization.data(withJSONObject: analysisData) {
                            let analysis = try jsonDecoder.decode(BillAnalysis.self, from: analysisJson)
                            print("✅ Successfully decoded BillAnalysis directly from 'analysis' field")
                            return analysis
                        }

                        throw error
                    }
                } catch {
                    print("❌ Decoding error: \(error)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("  Missing key: \(key.stringValue)")
                            print("  Context: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("  Type mismatch: \(type)")
                            print("  Context: \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("  Value not found: \(type)")
                            print("  Context: \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("  Data corrupted: \(context.debugDescription)")
                        @unknown default:
                            print("  Unknown decoding error")
                        }
                    }
                    throw APIError.decodingError(error)
                }

            case 400:
                // Bad request - decode error message
                if let errorResponse = try? jsonDecoder.decode(APIErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.error)
                } else {
                    throw APIError.serverError("Bad request - please check your file")
                }

            case 401:
                throw APIError.unauthorized

            case 500:
                // Server error - try to decode error message
                if let errorResponse = try? jsonDecoder.decode(APIErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.error)
                } else {
                    throw APIError.serverError("Server error - please try again")
                }

            default:
                throw APIError.serverError("Unexpected response code: \(httpResponse.statusCode)")
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Helper Methods

    private func getMimeType(for fileName: String) -> String {
        let pathExtension = (fileName as NSString).pathExtension.lowercased()
        switch pathExtension {
        case "pdf": return "application/pdf"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "heic": return "image/heic"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Data Extension
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
