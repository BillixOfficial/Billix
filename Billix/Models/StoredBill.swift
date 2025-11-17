import Foundation
import SwiftData

@Model
final class StoredBill {
    var id: UUID
    var fileName: String
    var uploadDate: Date
    var analysisData: Data?

    init(id: UUID = UUID(), fileName: String, uploadDate: Date, analysis: BillAnalysis) {
        self.id = id
        self.fileName = fileName
        self.uploadDate = uploadDate

        // Store analysis as JSON data
        if let encoded = try? JSONEncoder().encode(analysis) {
            self.analysisData = encoded
        }
    }

    var analysis: BillAnalysis? {
        guard let data = analysisData else { return nil }
        return try? JSONDecoder().decode(BillAnalysis.self, from: data)
    }
}
