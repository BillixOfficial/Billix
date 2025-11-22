import Foundation

// MARK: - Data Connection Model

struct DataConnection: Codable, Equatable {
    var bankConnections: [BankConnection]
    var ingestionChannels: IngestionChannels
}

// MARK: - Bank Connection (Plaid)

struct BankConnection: Identifiable, Codable, Equatable {
    let id: UUID
    let institutionName: String
    let lastRefreshed: Date
    var isActive: Bool

    var lastRefreshedString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "Last refreshed: \(formatter.string(from: lastRefreshed))"
    }

    var icon: String {
        "building.columns.fill"
    }
}

// MARK: - Ingestion Channels

struct IngestionChannels: Codable, Equatable {
    var emailAddress: String
    var smsNumber: String
    var totalUploads: Int

    var emailDisplay: String {
        emailAddress
    }

    var smsDisplay: String {
        smsNumber
    }

    var uploadsText: String {
        "You've uploaded \(totalUploads) bill documents."
    }
}

// MARK: - Preview Data

extension DataConnection {
    static let preview = DataConnection(
        bankConnections: [
            BankConnection(
                id: UUID(),
                institutionName: "Chase",
                lastRefreshed: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                isActive: true
            ),
            BankConnection(
                id: UUID(),
                institutionName: "American Express",
                lastRefreshed: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                isActive: true
            )
        ],
        ingestionChannels: IngestionChannels(
            emailAddress: "ronald@bills.billix.com",
            smsNumber: "(555) 123-4567",
            totalUploads: 16
        )
    )

    static let previewNoConnections = DataConnection(
        bankConnections: [],
        ingestionChannels: IngestionChannels(
            emailAddress: "jane@bills.billix.com",
            smsNumber: "(555) 987-6543",
            totalUploads: 0
        )
    )
}
