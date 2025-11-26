//
//  RecentUploadsViewModel.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation

/// ViewModel for managing recent uploads list
@MainActor
class RecentUploadsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var uploads: [RecentUpload] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var filterSource: UploadSource?
    @Published var sortOrder: SortOrder = .dateDescending

    // MARK: - Sort Order

    enum SortOrder {
        case dateDescending
        case dateAscending
        case amountDescending
        case amountAscending

        var displayName: String {
            switch self {
            case .dateDescending: return "Newest First"
            case .dateAscending: return "Oldest First"
            case .amountDescending: return "Highest Amount"
            case .amountAscending: return "Lowest Amount"
            }
        }
    }

    // MARK: - Dependencies

    private let uploadService: BillUploadServiceProtocol

    // MARK: - Initialization

    init(uploadService: BillUploadServiceProtocol? = nil) {
        self.uploadService = uploadService ?? BillUploadServiceFactory.create()
    }

    // MARK: - Load Uploads

    func loadUploads() async {
        isLoading = true
        errorMessage = nil

        do {
            uploads = try await uploadService.getRecentUploads()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refreshStatus(for uploadId: UUID) async {
        do {
            let status = try await uploadService.getUploadStatus(uploadId: uploadId)

            // Update in list
            if let index = uploads.firstIndex(where: { $0.id == uploadId }) {
                let upload = uploads[index]
                uploads[index] = RecentUpload(
                    id: upload.id,
                    provider: upload.provider,
                    amount: upload.amount,
                    source: upload.source,
                    status: status,
                    uploadDate: upload.uploadDate,
                    thumbnailName: upload.thumbnailName
                )
            }
        } catch {
            print("Failed to refresh status: \(error.localizedDescription)")
        }
    }

    // MARK: - Filtering & Sorting

    var filteredUploads: [RecentUpload] {
        var result = uploads

        // Filter by source if selected
        if let source = filterSource {
            result = result.filter { $0.source == source }
        }

        // Sort
        switch sortOrder {
        case .dateDescending:
            result.sort { $0.uploadDate > $1.uploadDate }
        case .dateAscending:
            result.sort { $0.uploadDate < $1.uploadDate }
        case .amountDescending:
            result.sort { $0.amount > $1.amount }
        case .amountAscending:
            result.sort { $0.amount < $1.amount }
        }

        return result
    }

    func toggleFilter(source: UploadSource) {
        if filterSource == source {
            filterSource = nil
        } else {
            filterSource = source
        }
    }

    func clearFilter() {
        filterSource = nil
    }

    // MARK: - Computed Properties

    var processingCount: Int {
        uploads.filter { $0.status == .processing }.count
    }

    var analyzedCount: Int {
        uploads.filter { $0.status == .analyzed }.count
    }

    var totalAmount: Double {
        uploads.reduce(0) { $0 + $1.amount }
    }
}
