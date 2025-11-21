import Foundation
import SwiftUI

struct HomeAlert: Codable, Identifiable {
    let id: UUID
    let type: AlertType
    let message: String
    let priority: Priority
    let actionTitle: String?
    let dueDate: Date?
    let isRead: Bool

    enum AlertType: String, Codable {
        case billDue
        case priceIncrease
        case savingsFound
        case promoExpiring
        case unusualCharge
        case paymentFailed

        var icon: String {
            switch self {
            case .billDue: return "calendar.badge.exclamationmark"
            case .priceIncrease: return "arrow.up.circle.fill"
            case .savingsFound: return "dollarsign.circle.fill"
            case .promoExpiring: return "clock.badge.exclamationmark"
            case .unusualCharge: return "exclamationmark.triangle.fill"
            case .paymentFailed: return "xmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .billDue: return .orange
            case .priceIncrease: return .red
            case .savingsFound: return .green
            case .promoExpiring: return .yellow
            case .unusualCharge: return .red
            case .paymentFailed: return .red
            }
        }
    }

    enum Priority: String, Codable {
        case high
        case medium
        case low

        var sortOrder: Int {
            switch self {
            case .high: return 0
            case .medium: return 1
            case .low: return 2
            }
        }
    }

    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return components.day
    }

    init(id: UUID = UUID(),
         type: AlertType,
         message: String,
         priority: Priority,
         actionTitle: String? = nil,
         dueDate: Date? = nil,
         isRead: Bool = false) {
        self.id = id
        self.type = type
        self.message = message
        self.priority = priority
        self.actionTitle = actionTitle
        self.dueDate = dueDate
        self.isRead = isRead
    }
}
