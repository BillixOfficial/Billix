import Foundation
import SwiftUI

struct RecentActivity: Codable, Identifiable {
    let id: UUID
    let type: ActivityType
    let billName: String
    let timestamp: Date
    let status: Status
    let amount: Double?

    enum ActivityType: String, Codable {
        case uploaded
        case analyzed
        case compared
        case saved
        case paid

        var icon: String {
            switch self {
            case .uploaded: return "arrow.up.doc.fill"
            case .analyzed: return "chart.bar.doc.horizontal.fill"
            case .compared: return "arrow.left.arrow.right"
            case .saved: return "dollarsign.circle.fill"
            case .paid: return "checkmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .uploaded: return .blue
            case .analyzed: return .purple
            case .compared: return .orange
            case .saved: return .green
            case .paid: return .green
            }
        }

        var actionText: String {
            switch self {
            case .uploaded: return "Uploaded"
            case .analyzed: return "Analyzed"
            case .compared: return "Compared"
            case .saved: return "Saved"
            case .paid: return "Paid"
            }
        }
    }

    enum Status: String, Codable {
        case completed
        case processing
        case failed
    }

    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    init(id: UUID = UUID(),
         type: ActivityType,
         billName: String,
         timestamp: Date,
         status: Status,
         amount: Double? = nil) {
        self.id = id
        self.type = type
        self.billName = billName
        self.timestamp = timestamp
        self.status = status
        self.amount = amount
    }
}
