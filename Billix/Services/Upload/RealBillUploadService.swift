//
//  RealBillUploadService.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation

/// Real API implementation for bill upload service
/// Currently stubbed with TODO comments for backend integration
///
/// ## API Integration Guide
///
/// When backend is ready, uncomment the real API code and remove mock returns.
/// All endpoints are documented with request/response structures.
///
/// Base URL: https://api.billixapp.com/v1
/// Authentication: Bearer token in Authorization header
///
class RealBillUploadService: BillUploadServiceProtocol {

    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let baseURL: String

    init(baseURL: String = "https://api.billixapp.com/v1") {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: configuration)

        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601

        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601

        self.baseURL = baseURL
    }

    // MARK: - Quick Add Operations

    /// GET /bill-types
    /// Response: [{ "id": "electric", "name": "Electric", "icon": "bolt.fill", "category": "Utilities" }]
    func getBillTypes() async throws -> [BillType] {
        // TODO: Uncomment when backend is ready
        /*
        guard let url = URL(string: "\(baseURL)/bill-types") else {
            throw UploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = AuthService.shared.currentUser?.id.uuidString {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw UploadError.serverError("Failed to fetch bill types: \(httpResponse.statusCode)")
        }

        return try jsonDecoder.decode([BillType].self, from: data)
        */

        // MOCK: Remove when backend ready
        return MockUploadDataService.billTypes
    }

    /// GET /providers?zipCode={zipCode}&billTypeId={billTypeId}
    /// Response: [{ "id": "dte", "name": "DTE Energy", "logoName": "dte_logo", "serviceArea": "Michigan" }]
    func getProviders(zipCode: String, billType: BillType) async throws -> [BillProvider] {
        // TODO: Uncomment when backend is ready
        /*
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

        if let token = AuthService.shared.currentUser?.id.uuidString {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw UploadError.serverError("Failed to fetch providers: \(httpResponse.statusCode)")
        }

        return try jsonDecoder.decode([BillProvider].self, from: data)
        */

        // MOCK: Remove when backend ready
        return MockUploadDataService.getProviders(for: zipCode, billType: billType)
    }

    /// POST /quick-add
    /// Request: { "billTypeId": "electric", "providerId": "dte", "zipCode": "48104", "amount": 124.56, "frequency": "monthly" }
    /// Response: { "areaAverage": 110.0, "percentDifference": 13.2, "status": "overpaying", "potentialSavings": 10.19, "ctaMessage": "Upload your full bill...", ... }
    /// Note: Backend should ALWAYS include ctaMessage in response regardless of status
    func submitQuickAdd(request: QuickAddRequest) async throws -> QuickAddResult {
        // TODO: Uncomment when backend is ready
        /*
        guard let url = URL(string: "\(baseURL)/quick-add") else {
            throw UploadError.invalidURL
        }

        var httpRequest = URLRequest(url: url)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = AuthService.shared.currentUser?.id.uuidString {
            httpRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode request body
        struct RequestBody: Encodable {
            let billTypeId: String
            let providerId: String
            let zipCode: String
            let amount: Double
            let frequency: String
        }

        let body = RequestBody(
            billTypeId: request.billType.id,
            providerId: request.provider.id,
            zipCode: request.zipCode,
            amount: request.amount,
            frequency: request.frequency.rawValue
        )

        httpRequest.httpBody = try jsonEncoder.encode(body)

        let (data, response) = try await session.data(for: httpRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try jsonDecoder.decode(QuickAddResult.self, from: data)
        case 400:
            let error = try? jsonDecoder.decode(UploadAPIErrorResponse.self, from: data)
            throw UploadError.validationFailed(error?.message ?? "Invalid request")
        case 401:
            throw UploadError.unauthorized
        default:
            throw UploadError.serverError("Failed to submit quick add: \(httpResponse.statusCode)")
        }
        */

        // MOCK: Remove when backend ready
        return MockUploadDataService.calculateQuickAddResult(request: request)
    }

    // MARK: - Scan/Upload Operations

    /// POST /bills/upload (multipart/form-data)
    /// Form fields: file (binary), fileName (string), source (string)
    /// Response: Full BillAnalysis object
    func uploadAndAnalyzeBill(fileData: Data, fileName: String, source: UploadSource) async throws -> BillAnalysis {
        // TODO: Uncomment when backend is ready
        /*
        guard let url = URL(string: "\(baseURL)/bills/upload") else {
            throw UploadError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = AuthService.shared.currentUser?.id.uuidString {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Build multipart body
        var body = Data()

        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(getMimeType(for: fileName))\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        // Add source field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"source\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(source.rawValue)\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try jsonDecoder.decode(BillAnalysis.self, from: data)
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
        */

        // MOCK: Remove when backend ready
        return MockUploadDataService.generateMockBillAnalysis(fileName: fileName, source: source)
    }

    // MARK: - Recent Uploads

    /// GET /bills/recent?limit=20
    /// Response: [{ "id": "...", "provider": "DTE Energy", "amount": 124.56, "source": "camera", "status": "analyzed", ... }]
    func getRecentUploads() async throws -> [RecentUpload] {
        // TODO: Uncomment when backend is ready
        /*
        guard let url = URL(string: "\(baseURL)/bills/recent?limit=20") else {
            throw UploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = AuthService.shared.currentUser?.id.uuidString {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw UploadError.serverError("Failed to fetch recent uploads: \(httpResponse.statusCode)")
        }

        return try jsonDecoder.decode([RecentUpload].self, from: data)
        */

        // MOCK: Remove when backend ready
        return MockUploadDataService.generateRecentUploads()
    }

    /// GET /bills/{uploadId}/status
    /// Response: { "status": "processing" | "analyzed" | "needsConfirmation" }
    func getUploadStatus(uploadId: UUID) async throws -> UploadStatus {
        // TODO: Uncomment when backend is ready
        /*
        guard let url = URL(string: "\(baseURL)/bills/\(uploadId.uuidString)/status") else {
            throw UploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = AuthService.shared.currentUser?.id.uuidString {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw UploadError.serverError("Failed to fetch status: \(httpResponse.statusCode)")
        }

        struct StatusResponse: Decodable {
            let status: String
        }

        let statusResponse = try jsonDecoder.decode(StatusResponse.self, from: data)
        return UploadStatus(rawValue: statusResponse.status) ?? .processing
        */

        // MOCK: Remove when backend ready
        return Bool.random() ? .processing : .analyzed
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
}

// MARK: - API Error Response

struct UploadAPIErrorResponse: Decodable {
    let error: String
    let message: String
}
