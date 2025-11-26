//
//  ScanUploadViewModel.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation
import SwiftData
import UIKit

/// ViewModel for Scan/Upload flow
@MainActor
class ScanUploadViewModel: ObservableObject {

    // MARK: - Upload State

    enum UploadState {
        case idle
        case selecting
        case uploading
        case analyzing
        case success(BillAnalysis)
        case error(UploadError)
    }

    // MARK: - Published Properties

    @Published var uploadState: UploadState = .idle
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = ""

    // File pickers
    @Published var showCamera: Bool = false
    @Published var showPhotoPicker: Bool = false
    @Published var showDocumentPicker: Bool = false

    // MARK: - Dependencies

    private let uploadService: BillUploadServiceProtocol
    var modelContext: ModelContext?
    private var preselectedImage: UIImage?

    // MARK: - Initialization

    init(preselectedImage: UIImage? = nil, uploadService: BillUploadServiceProtocol? = nil) {
        self.preselectedImage = preselectedImage
        self.uploadService = uploadService ?? BillUploadServiceFactory.create()

        // If image is preselected, start processing immediately
        if let image = preselectedImage {
            Task {
                await processImage(image, source: .camera)
            }
        }
    }

    // MARK: - File Selection

    func selectFromCamera() {
        uploadState = .selecting
        showCamera = true
    }

    func selectFromPhotos() {
        uploadState = .selecting
        showPhotoPicker = true
    }

    func selectFromFiles() {
        uploadState = .selecting
        showDocumentPicker = true
    }

    // MARK: - Upload

    func uploadBill(fileData: Data, fileName: String, source: UploadSource) async {
        uploadState = .uploading
        progress = 0.0
        statusMessage = "Validating file..."

        // Client-side validation
        guard fileData.count >= 100 else {
            uploadState = .error(.validationFailed("File is too small"))
            return
        }

        guard fileData.count <= 10_485_760 else {
            uploadState = .error(.validationFailed("File too large (max 10MB)"))
            return
        }

        progress = 0.2
        statusMessage = "Uploading..."

        do {
            // Simulate upload progress
            for i in 1...3 {
                try await Task.sleep(nanoseconds: 300_000_000)
                progress = 0.2 + (Double(i) * 0.2)
            }

            statusMessage = "Analyzing bill..."
            progress = 0.8

            // Upload and analyze
            let analysis = try await uploadService.uploadAndAnalyzeBill(
                fileData: fileData,
                fileName: fileName,
                source: source
            )

            progress = 0.9
            statusMessage = "Saving..."

            // Save to SwiftData
            if let context = modelContext {
                let storedBill = StoredBill(
                    fileName: fileName,
                    uploadDate: Date(),
                    analysis: analysis
                )
                context.insert(storedBill)
                try context.save()
            }

            progress = 1.0
            statusMessage = "Complete!"
            uploadState = .success(analysis)

        } catch let error as UploadError {
            uploadState = .error(error)
        } catch {
            uploadState = .error(.uploadFailed(error.localizedDescription))
        }
    }

    // MARK: - Retry & Reset

    func retry() {
        uploadState = .idle
        progress = 0.0
        statusMessage = ""
    }

    func reset() {
        uploadState = .idle
        progress = 0.0
        statusMessage = ""
        showCamera = false
        showPhotoPicker = false
        showDocumentPicker = false
    }

    // MARK: - Image Processing

    func processImage(_ image: UIImage, source: UploadSource) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            uploadState = .error(.validationFailed("Failed to process image"))
            return
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "\(source.rawValue)-\(timestamp).jpg"

        await uploadBill(fileData: imageData, fileName: fileName, source: source)
    }
}
