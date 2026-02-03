//
//  RealBillUploadService.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation

/// Real API implementation for bill upload service
/// Connects to the Billix backend at billixapp.com
///
/// ## API Endpoints
/// - GET /v1/bill-types - List all bill types
/// - GET /v1/providers - Get providers for ZIP/bill type
/// - POST /v1/marketplace/quick-add - Submit quick add comparison
/// - POST /v1/bills/upload - Full bill analysis with AI
///
class RealBillUploadService: BillUploadServiceProtocol {

    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let baseURL: String

    init(baseURL: String = "https://www.billixapp.com/api/v1") {
        let configuration = URLSessionConfiguration.default
        // Increased timeouts for AI bill analysis which can take 30-90 seconds
        configuration.timeoutIntervalForRequest = 120  // 2 minutes for request
        configuration.timeoutIntervalForResource = 180 // 3 minutes total
        self.session = URLSession(configuration: configuration)

        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601

        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601

        self.baseURL = baseURL
    }

    // MARK: - Quick Add Operations

    /// Returns static bill types for Quick Add selection
    /// These are the core bill categories users can compare
    func getBillTypes() async throws -> [BillType] {
        return [
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
    }

    /// GET /providers?zipCode={zipCode}&billTypeId={billTypeId}
    /// Response: { "success": true, "providers": [...], "totalProviders": N }
    func getProviders(zipCode: String, billType: BillType) async throws -> [BillProvider] {
        guard var components = URLComponents(string: "\(baseURL)/providers") else {
            throw UploadError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "zipCode", value: zipCode),
            URLQueryItem(name: "billTypeId", value: billType.id)
        ]

        guard let url = components.url else {
            throw UploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw UploadError.serverError("Failed to fetch providers: \(httpResponse.statusCode)")
        }

        // Parse wrapped response: { providers: [...] }
        struct ProvidersResponse: Decodable {
            let providers: [BillProvider]
        }

        let apiResponse = try jsonDecoder.decode(ProvidersResponse.self, from: data)
        return apiResponse.providers
    }

    /// POST /marketplace/quick-add
    /// Request: { "billTypeId": "electric", "providerId": "dte", "zipCode": "48104", "amount": 124.56, "frequency": "monthly" }
    /// Response: { "success": true, "comparison": { "yourAmount": ..., "areaAverage": ..., "status": "above_average", ... } }
    func submitQuickAdd(request: QuickAddRequest) async throws -> QuickAddResult {
        guard let url = URL(string: "\(baseURL)/marketplace/quick-add") else {
            throw UploadError.invalidURL
        }

        var httpRequest = URLRequest(url: url)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode request body - matches backend expected fields
        struct RequestBody: Encodable {
            let provider: String
            let category: String
            let subcategory: String
            let amount: Double
            let zipCode: String
        }

        let body = RequestBody(
            provider: request.provider.name,
            category: request.billType.category.lowercased(),
            subcategory: mapBillTypeToSubcategory(request.billType.id),
            amount: request.amount,
            zipCode: request.zipCode
        )

        httpRequest.httpBody = try jsonEncoder.encode(body)

        let (data, response) = try await session.data(for: httpRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200, 201:
            // Parse API response and map to QuickAddResult
            struct APIResponse: Decodable {
                let comparison: ComparisonData
            }

            struct ComparisonData: Decodable {
                let yourAmount: Double
                let areaAverage: Double
                let percentDifference: Double
                let status: String
                let potentialSavings: Double?
                let message: String
            }

            let apiResponse = try jsonDecoder.decode(APIResponse.self, from: data)

            // Map API response to QuickAddResult
            return QuickAddResult(
                billType: request.billType,
                provider: request.provider,
                amount: apiResponse.comparison.yourAmount,
                frequency: request.frequency,
                areaAverage: apiResponse.comparison.areaAverage,
                percentDifference: apiResponse.comparison.percentDifference,
                status: QuickAddResult.Status(fromAPIStatus: apiResponse.comparison.status),
                potentialSavings: apiResponse.comparison.potentialSavings,
                message: apiResponse.comparison.message,
                ctaMessage: "Upload your full bill for a detailed analysis and personalized savings recommendations."
            )
        case 400:
            let error = try? jsonDecoder.decode(UploadAPIErrorResponse.self, from: data)
            throw UploadError.validationFailed(error?.message ?? "Invalid request")
        case 401:
            throw UploadError.unauthorized
        default:
            throw UploadError.serverError("Failed to submit quick add: \(httpResponse.statusCode)")
        }
    }

    // MARK: - Scan/Upload Operations

    /// POST /bills/upload (multipart/form-data)
    /// Form fields: file (binary)
    /// Response: { "success": true, "analysis": { ... } }
    func uploadAndAnalyzeBill(fileData: Data, fileName: String, source: UploadSource) async throws -> BillAnalysis {
        let uploadURL = "\(baseURL)/bills/upload"
        print("🔄 [RealBillUploadService] Starting upload to: \(uploadURL)")
        print("🔄 [RealBillUploadService] File: \(fileName), Size: \(fileData.count) bytes")

        guard let url = URL(string: uploadURL) else {
            print("❌ [RealBillUploadService] Invalid URL: \(uploadURL)")
            throw UploadError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Build multipart body
        var body = Data()

        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(getMimeType(for: fileName))\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("🔄 [RealBillUploadService] Sending request... Body size: \(body.count) bytes")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
            print("✅ [RealBillUploadService] Received response")
        } catch {
            print("❌ [RealBillUploadService] Network error: \(error)")
            print("❌ [RealBillUploadService] Error domain: \((error as NSError).domain)")
            print("❌ [RealBillUploadService] Error code: \((error as NSError).code)")
            print("❌ [RealBillUploadService] Error userInfo: \((error as NSError).userInfo)")
            throw UploadError.uploadFailed("Network error: \(error.localizedDescription)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [RealBillUploadService] Invalid response type")
            throw UploadError.invalidResponse
        }
        print("🔄 [RealBillUploadService] HTTP Status: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200, 201:
            // Parse wrapped response: { analysis: { ... } }
            struct UploadResponse: Decodable {
                let analysis: BillAnalysis
            }

            do {
                let apiResponse = try jsonDecoder.decode(UploadResponse.self, from: data)
                return apiResponse.analysis
            } catch {
                print("❌ Decoding Error: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch for type '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        print("Debug: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Value not found for type '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    case .dataCorrupted(let context):
                        print("Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        print("Debug: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                throw UploadError.decodingFailed("Failed to decode bill analysis: \(error.localizedDescription)")
            }
        case 400:
            let error = try? jsonDecoder.decode(UploadAPIErrorResponse.self, from: data)
            throw UploadError.validationFailed(error?.message ?? "Invalid file")
        case 401:
            throw UploadError.unauthorized
        case 413:
            throw UploadError.validationFailed("File too large (max 10MB)")
        default:
            throw UploadError.serverError("Upload failed: \(httpResponse.statusCode)")
        }
    }

    // MARK: - Recent Uploads

    /// Recent uploads are stored locally using SwiftData
    /// This method returns empty array - actual data comes from UploadViewModel querying SwiftData
    func getRecentUploads() async throws -> [RecentUpload] {
        // Recent uploads are managed locally via SwiftData in UploadViewModel
        // This service method is kept for protocol conformance
        return []
    }

    /// Upload status - since uploads are synchronous, always return .analyzed
    func getUploadStatus(uploadId: UUID) async throws -> UploadStatus {
        // Uploads complete synchronously with the real API
        return .analyzed
    }

    // MARK: - Helper Methods

    private func getMimeType(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "application/pdf"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "heic": return "image/heic"
        default: return "application/octet-stream"
        }
    }

    /// Maps iOS bill type IDs to backend subcategory values
    private func mapBillTypeToSubcategory(_ billTypeId: String) -> String {
        switch billTypeId {
        case "electric": return "electricity"
        case "gas": return "natural_gas"
        case "insurance-auto": return "auto_insurance"
        case "insurance-home": return "home_insurance"
        case "cable": return "cable_tv"
        default: return billTypeId  // water, internet, mobile stay the same
        }
    }
}

// MARK: - API Error Response

struct UploadAPIErrorResponse: Decodable {
    let error: String
    let message: String
}
