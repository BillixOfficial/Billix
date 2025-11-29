//
//  UploadViewModel.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation
import SwiftData
import SwiftUI

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
    @Published var selectedUpload: RecentUpload?
    @Published var selectedBill: StoredBill?

    // Media Pickers
    @Published var showCamera: Bool = false
    @Published var showGallery: Bool = false
    @Published var showDocumentPicker: Bool = false
    @Published var selectedImage: UIImage?
    @Published var selectedDocumentURL: URL?
    @Published var selectedFileData: Data?
    @Published var selectedFileName: String?

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

        // Query StoredBills from SwiftData instead of API
        guard let context = modelContext else {
            isLoadingRecent = false
            return
        }

        do {
            let descriptor = FetchDescriptor<StoredBill>(
                sortBy: [SortDescriptor(\.uploadDate, order: .reverse)]
            )
            let storedBills = try context.fetch(descriptor)

            // Convert to RecentUpload for display
            recentUploads = storedBills.compactMap { $0.toRecentUpload() }
        } catch {
            errorMessage = "Failed to load recent uploads"
        }

        isLoadingRecent = false
    }

    func refreshUploadStatus(for uploadId: UUID) async {
        do {
            let status = try await uploadService.getUploadStatus(uploadId: uploadId)

            // Update the upload in the list
            if let index = recentUploads.firstIndex(where: { $0.id == uploadId }) {
                let updated = recentUploads[index]
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

    func findStoredBill(for id: UUID) -> StoredBill? {
        guard let context = modelContext else { return nil }

        let descriptor = FetchDescriptor<StoredBill>(
            predicate: #Predicate { $0.id == id }
        )

        return try? context.fetch(descriptor).first
    }

    // MARK: - Actions

    func startQuickAdd() {
        showQuickAddFlow = true
    }

    func startScanUpload() {
        showScanUploadFlow = true
    }

    func startCamera() {
        showCamera = true
    }

    func startGallery() {
        showGallery = true
    }

    func startDocumentPicker() {
        showDocumentPicker = true
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

    // MARK: - Media Handling

    func handleImageSelected(_ image: UIImage) {
        selectedImage = image
        // Process the image - in this case, start the scan upload flow with the image
        showScanUploadFlow = true
    }

    func handleDocumentSelected(_ url: URL) {
        selectedDocumentURL = url

        // Access security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let fileData = try Data(contentsOf: url)
            let fileName = url.lastPathComponent

            // Try to load as image first
            if let image = UIImage(data: fileData) {
                selectedImage = image
                selectedFileData = nil
                selectedFileName = nil
            } else {
                // Not an image (e.g., PDF) - store raw file data
                selectedImage = nil
                selectedFileData = fileData
                selectedFileName = fileName
            }

            showScanUploadFlow = true
        } catch {
            print("Failed to read file: \(error.localizedDescription)")
        }
    }

    private func loadImageFromDocument(_ url: URL) -> UIImage? {
        // Try to load as image
        if let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }

        // Handle PDF - could extract first page
        // For now, just return nil for PDFs (could be extended)
        return nil
    }
}
