//
//  UploadViewModel.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation
import SwiftData

/// Main ViewModel for the Upload Hub
/// Manages overall state and coordinates between Quick Add and Scan/Upload flows
@MainActor
class UploadViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var recentUploads: [RecentUpload] = []
    @Published var isLoadingRecent: Bool = false
    @Published var errorMessage: String?

    // Navigation
    @Published var showQuickAddFlow: Bool = false
    @Published var showScanUploadFlow: Bool = false

    // MARK: - Dependencies

    private let uploadService: BillUploadServiceProtocol
    var modelContext: ModelContext?

    // MARK: - Initialization

    init(uploadService: BillUploadServiceProtocol? = nil) {
        self.uploadService = uploadService ?? BillUploadServiceFactory.create()
    }

    // MARK: - Recent Uploads

    func loadRecentUploads() async {
        isLoadingRecent = true
        errorMessage = nil

        do {
            recentUploads = try await uploadService.getRecentUploads()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingRecent = false
    }

    func refreshUploadStatus(for uploadId: UUID) async {
        do {
            let status = try await uploadService.getUploadStatus(uploadId: uploadId)

            // Update the upload in the list
            if let index = recentUploads.firstIndex(where: { $0.id == uploadId }) {
                var updated = recentUploads[index]
                // Create new instance with updated status
                recentUploads[index] = RecentUpload(
                    id: updated.id,
                    provider: updated.provider,
                    amount: updated.amount,
                    source: updated.source,
                    status: status,
                    uploadDate: updated.uploadDate,
                    thumbnailName: updated.thumbnailName
                )
            }
        } catch {
            print("Failed to refresh status: \(error.localizedDescription)")
        }
    }

    // MARK: - Actions

    func startQuickAdd() {
        showQuickAddFlow = true
    }

    func startScanUpload() {
        showScanUploadFlow = true
    }

    func dismissFlows() {
        showQuickAddFlow = false
        showScanUploadFlow = false
    }

    func handleUploadComplete() {
        // Reload recent uploads after successful upload
        Task {
            await loadRecentUploads()
        }
    }
}
