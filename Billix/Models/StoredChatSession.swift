//
//  StoredChatSession.swift
//  Billix
//
//  Created by Claude Code on 2/5/26.
//  SwiftData model for locally stored chat sessions with 7-day expiry
//

import Foundation
import SwiftData

/// Stores encrypted chat history for a bill
/// - Messages are AES-256 encrypted for privacy
/// - Sessions expire after 7 days
/// - Linked to a bill by billId
@Model
final class StoredChatSession {
    var id: UUID = UUID()
    var billId: UUID
    var messagesData: Data  // Encrypted JSON of [AskBillixMessage]
    var createdAt: Date = Date()
    var expiresAt: Date

    init(billId: UUID) {
        self.billId = billId
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        self.messagesData = Data()
    }
}
