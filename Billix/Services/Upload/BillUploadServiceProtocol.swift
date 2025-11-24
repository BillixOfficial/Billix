//
//  BillUploadServiceProtocol.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation

/// Protocol defining all bill upload and quick-add operations
/// This enables easy switching between mock and real implementations
protocol BillUploadServiceProtocol {

    // MARK: - Quick Add Operations

    /// Fetch list of available bill types
    func getBillTypes() async throws -> [BillType]

    /// Fetch providers for a specific ZIP code and bill type
    /// - Parameters:
    ///   - zipCode: User's ZIP code
    ///   - billType: Type of bill (e.g., electric, internet)
    func getProviders(zipCode: String, billType: BillType) async throws -> [BillProvider]

    /// Submit a quick-add bill and get comparison result
    /// - Parameters:
    ///   - request: Quick add data (bill type, provider, amount, frequency)
    /// - Returns: Result showing if user is overpaying
    func submitQuickAdd(request: QuickAddRequest) async throws -> QuickAddResult

    // MARK: - Scan/Upload Operations

    /// Upload and analyze a bill document
    /// - Parameters:
    ///   - fileData: Image or PDF data
    ///   - fileName: Original filename
    ///   - source: Where the file came from (camera, photos, etc.)
    /// - Returns: Full bill analysis with line items and insights
    func uploadAndAnalyzeBill(fileData: Data, fileName: String, source: UploadSource) async throws -> BillAnalysis

    // MARK: - Recent Uploads

    /// Fetch user's upload history
    func getRecentUploads() async throws -> [RecentUpload]

    /// Get status of a specific upload by ID
    /// - Parameter uploadId: UUID of the upload
    func getUploadStatus(uploadId: UUID) async throws -> UploadStatus
}
