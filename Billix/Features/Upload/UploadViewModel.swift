import Foundation
import SwiftUI
import SwiftData

enum UploadState {
    case idle
    case selecting
    case uploading
    case analyzing
    case success(BillAnalysis)
    case error(UploadError)
}

enum UploadError: Error {
    case validationFailed(String)
    case uploadFailed(String)
    case analysisFailed(String)
    case unknown(String)

    var message: String {
        switch self {
        case .validationFailed(let msg),
             .uploadFailed(let msg),
             .analysisFailed(let msg),
             .unknown(let msg):
            return msg
        }
    }
}

@MainActor
class UploadViewModel: ObservableObject {
    @Published var uploadState: UploadState = .idle
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var errorMessage: String?
    @Published var analysisResult: BillAnalysis?
    @Published var showUploadOptions = false
    @Published var showCamera = false
    @Published var showPhotoPicker = false
    @Published var showDocumentPicker = false
    @Published var showDocumentScanner = false

    private let apiClient = APIClient.shared
    var modelContext: ModelContext?

    func selectFromCamera() {
        showCamera = true
        uploadState = .selecting
    }

    func selectFromPhotos() {
        showPhotoPicker = true
        uploadState = .selecting
    }

    func selectFromFiles() {
        showDocumentPicker = true
        uploadState = .selecting
    }

    func uploadBill(fileData: Data, fileName: String) async {
        uploadState = .uploading
        progress = 0.0
        statusMessage = "Validating file..."

        // Validate file
        let validation = FileValidator.validate(fileData: fileData, fileName: fileName)
        if !validation.isValid {
            uploadState = .error(.validationFailed(validation.errorMessage ?? "Invalid file"))
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

            // Analyze the bill
            let analysis = try await apiClient.uploadAndAnalyzeBill(fileData: fileData, fileName: fileName)

            progress = 0.9
            statusMessage = "Saving..."

            // Save to SwiftData
            if let context = modelContext {
                let storedBill = StoredBill(fileName: fileName, uploadDate: Date(), analysis: analysis)
                context.insert(storedBill)
                try context.save()
            }

            progress = 1.0
            statusMessage = "Complete!"
            analysisResult = analysis
            uploadState = .success(analysis)

        } catch {
            uploadState = .error(.uploadFailed(error.localizedDescription))
        }
    }

    func retry() {
        uploadState = .idle
        progress = 0.0
        statusMessage = ""
        errorMessage = nil
    }

    func reset() {
        uploadState = .idle
        progress = 0.0
        statusMessage = ""
        errorMessage = nil
        analysisResult = nil
        showUploadOptions = false
        showCamera = false
        showPhotoPicker = false
        showDocumentPicker = false
        showDocumentScanner = false
    }
}
