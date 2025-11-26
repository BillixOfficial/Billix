//
//  MockBillUploadService.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation

/// Mock implementation of bill upload service
/// Uses static mock data and simulates network delays for realistic testing
class MockBillUploadService: BillUploadServiceProtocol {

    private let mockDelay: TimeInterval
    private let shouldSucceed: Bool

    init(mockDelay: TimeInterval = 1.5, shouldSucceed: Bool = true) {
        self.mockDelay = mockDelay
        self.shouldSucceed = shouldSucceed
    }

    // MARK: - Quick Add Operations

    func getBillTypes() async throws -> [BillType] {
        try await simulateNetworkDelay(0.3)

        if !shouldSucceed {
            throw UploadError.networkError("Failed to fetch bill types")
        }

        return MockUploadDataService.billTypes
    }

    func getProviders(zipCode: String, billType: BillType) async throws -> [BillProvider] {
        try await simulateNetworkDelay(0.5)

        if !shouldSucceed {
            throw UploadError.networkError("Failed to fetch providers")
        }

        // Validate ZIP code format
        guard zipCode.count == 5, zipCode.allSatisfy({ $0.isNumber }) else {
            throw UploadError.validationFailed("Invalid ZIP code format")
        }

        return MockUploadDataService.getProviders(for: zipCode, billType: billType)
    }

    func submitQuickAdd(request: QuickAddRequest) async throws -> QuickAddResult {
        try await simulateNetworkDelay(mockDelay)

        if !shouldSucceed {
            throw UploadError.networkError("Failed to submit quick add")
        }

        // Validate request
        guard request.amount > 0 else {
            throw UploadError.validationFailed("Amount must be greater than zero")
        }

        return MockUploadDataService.calculateQuickAddResult(request: request)
    }

    // MARK: - Scan/Upload Operations

    func uploadAndAnalyzeBill(fileData: Data, fileName: String, source: UploadSource) async throws -> BillAnalysis {
        try await simulateNetworkDelay(mockDelay * 2)

        if !shouldSucceed {
            throw UploadError.uploadFailed("Mock upload failed")
        }

        // Validate file size (100 bytes to 10MB)
        guard fileData.count >= 100 else {
            throw UploadError.validationFailed("File is too small (minimum 100 bytes)")
        }

        guard fileData.count <= 10_485_760 else {
            throw UploadError.validationFailed("File is too large (maximum 10MB)")
        }

        // Validate file extension
        let ext = (fileName as NSString).pathExtension.lowercased()
        let allowedExtensions = ["pdf", "jpg", "jpeg", "png", "heic"]
        guard allowedExtensions.contains(ext) else {
            throw UploadError.validationFailed("Invalid file type. Allowed: PDF, JPG, PNG, HEIC")
        }

        return MockUploadDataService.generateMockBillAnalysis(fileName: fileName, source: source)
    }

    // MARK: - Recent Uploads

    func getRecentUploads() async throws -> [RecentUpload] {
        try await simulateNetworkDelay(0.5)

        if !shouldSucceed {
            throw UploadError.networkError("Failed to fetch recent uploads")
        }

        return MockUploadDataService.generateRecentUploads()
    }

    func getUploadStatus(uploadId: UUID) async throws -> UploadStatus {
        try await simulateNetworkDelay(0.3)

        if !shouldSucceed {
            throw UploadError.networkError("Failed to fetch upload status")
        }

        // Mock status - randomly return processing or analyzed
        return Bool.random() ? .processing : .analyzed
    }

    // MARK: - Helper Methods

    private func simulateNetworkDelay(_ delay: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
}
