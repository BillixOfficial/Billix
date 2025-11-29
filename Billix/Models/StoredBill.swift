import Foundation
import SwiftData

@Model
final class StoredBill {
    var id: UUID = UUID()
    var fileName: String = ""
    var uploadDate: Date = Date()
    var analysisData: Data?
    var quickAddData: Data?
    var sourceRawValue: String = "documentScanner"

    init(id: UUID = UUID(), fileName: String, uploadDate: Date, analysis: BillAnalysis, source: UploadSource = .documentScanner) {
        self.id = id
        self.fileName = fileName
        self.uploadDate = uploadDate
        self.sourceRawValue = source.rawValue

        // Store analysis as JSON data
        if let encoded = try? JSONEncoder().encode(analysis) {
            self.analysisData = encoded
        }
    }

    /// Initialize with Quick Add result
    init(id: UUID = UUID(), uploadDate: Date, quickAddResult: QuickAddResult, source: UploadSource = .quickAdd) {
        self.id = id
        self.fileName = "\(quickAddResult.provider.name) - Quick Add"
        self.uploadDate = uploadDate
        self.sourceRawValue = source.rawValue

        // Store Quick Add result as JSON data
        if let encoded = try? JSONEncoder().encode(quickAddResult) {
            self.quickAddData = encoded
        }
    }

    var analysis: BillAnalysis? {
        guard let data = analysisData else { return nil }
        return try? JSONDecoder().decode(BillAnalysis.self, from: data)
    }

    var quickAddResult: QuickAddResult? {
        guard let data = quickAddData else { return nil }
        return try? JSONDecoder().decode(QuickAddResult.self, from: data)
    }

    var source: UploadSource {
        UploadSource(rawValue: sourceRawValue) ?? .documentScanner
    }

    /// Convert to RecentUpload for display in the UI
    func toRecentUpload() -> RecentUpload? {
        // For Quick Add bills
        if source == .quickAdd, let result = quickAddResult {
            return RecentUpload(
                id: id,
                provider: result.provider.name,
                amount: result.amount,
                source: source,
                status: .analyzed,
                uploadDate: uploadDate,
                thumbnailName: nil
            )
        }

        // For scanned bills
        guard let analysis = analysis else { return nil }
        return RecentUpload(
            id: id,
            provider: analysis.provider,
            amount: analysis.amount,
            source: source,
            status: .analyzed,
            uploadDate: uploadDate,
            thumbnailName: nil
        )
    }
}
