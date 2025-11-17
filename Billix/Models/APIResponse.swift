import Foundation

// MARK: - Upload Response
struct BillUploadResponse: Codable {
    let success: Bool
    let analysis: BillAnalysis
    let metadata: UploadMetadata?
    let message: String?
}

// MARK: - Upload Metadata
struct UploadMetadata: Codable {
    let fileName: String?
    let fileSize: Int?
    let fileType: String?
}

// MARK: - Error Response
struct APIErrorResponse: Codable {
    let error: String
    let details: String?
}
