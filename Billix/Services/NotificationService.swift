//
//  NotificationService.swift
//  Billix
//
//  Service for managing push notifications and in-app notifications
//  for BillSwap events
//

import Foundation
import UserNotifications
import UIKit
import Supabase
import SwiftUI

// MARK: - App Notification Types (Unified)

/// All notification types shown in the notification bell
enum AppNotificationType: String, CaseIterable {
    // Swap notifications
    case matchFound = "match_found"
    case partnerCommitted = "partner_committed"
    case chatUnlocked = "chat_unlocked"
    case billPaid = "bill_paid"
    case swapComplete = "swap_complete"
    case reminder = "reminder"
    case expiringSoon = "expiring_soon"

    // Other notification types (future extensibility)
    case billDueSoon = "bill_due_soon"
    case savingsFound = "savings_found"
    case achievementUnlocked = "achievement_unlocked"
    case scoreUpdate = "score_update"

    var title: String {
        switch self {
        case .matchFound: return "Perfect Match Found!"
        case .partnerCommitted: return "Partner Committed!"
        case .chatUnlocked: return "Chat Unlocked!"
        case .billPaid: return "Payment Received!"
        case .swapComplete: return "Swap Complete!"
        case .reminder: return "Swap Waiting"
        case .expiringSoon: return "Match Expiring Soon"
        case .billDueSoon: return "Bill Due Soon"
        case .savingsFound: return "Savings Found"
        case .achievementUnlocked: return "Achievement Unlocked!"
        case .scoreUpdate: return "Score Update"
        }
    }

    var icon: String {
        switch self {
        case .matchFound: return "person.2.fill"
        case .partnerCommitted: return "hand.thumbsup.fill"
        case .chatUnlocked: return "message.fill"
        case .billPaid: return "dollarsign.circle.fill"
        case .swapComplete: return "checkmark.seal.fill"
        case .reminder: return "clock.fill"
        case .expiringSoon: return "exclamationmark.clock.fill"
        case .billDueSoon: return "bolt.fill"
        case .savingsFound: return "arrow.down.circle.fill"
        case .achievementUnlocked: return "star.fill"
        case .scoreUpdate: return "chart.line.uptrend.xyaxis"
        }
    }

    var iconColor: Color {
        switch self {
        case .matchFound: return Color(hex: "#5B8A6B")
        case .partnerCommitted: return Color(hex: "#5BA4D4")
        case .chatUnlocked: return Color(hex: "#5BA4D4")
        case .billPaid: return Color(hex: "#4CAF7A")
        case .swapComplete: return Color(hex: "#4CAF7A")
        case .reminder: return Color(hex: "#E8A54B")
        case .expiringSoon: return Color(hex: "#E07A6B")
        case .billDueSoon: return Color(hex: "#E8A54B")
        case .savingsFound: return Color(hex: "#4CAF7A")
        case .achievementUnlocked: return Color(hex: "#5BA4D4")
        case .scoreUpdate: return Color(hex: "#5B8A6B")
        }
    }
}

/// Unified notification item for the notification bell
struct AppNotificationItem: Identifiable, Equatable {
    let id: UUID
    let type: AppNotificationType
    let title: String
    let subtitle: String
    let createdAt: Date
    var isUnread: Bool
    let swapId: UUID?

    init(
        id: UUID = UUID(),
        type: AppNotificationType,
        title: String? = nil,
        subtitle: String,
        createdAt: Date = Date(),
        isUnread: Bool = true,
        swapId: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title ?? type.title
        self.subtitle = subtitle
        self.createdAt = createdAt
        self.isUnread = isUnread
        self.swapId = swapId
    }

    var icon: String { type.icon }
    var iconColor: Color { type.iconColor }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Swap Notification Types

enum SwapNotificationType: String, CaseIterable {
    case matchFound = "match_found"
    case partnerCommitted = "partner_committed"
    case chatUnlocked = "chat_unlocked"
    case billPaid = "bill_paid"
    case swapComplete = "swap_complete"
    case reminder = "reminder"
    case expiringSoon = "expiring_soon"

    var title: String {
        switch self {
        case .matchFound:
            return "Perfect Match Found!"
        case .partnerCommitted:
            return "Partner Committed!"
        case .chatUnlocked:
            return "Chat Unlocked!"
        case .billPaid:
            return "Payment Received!"
        case .swapComplete:
            return "Swap Complete!"
        case .reminder:
            return "Swap Waiting"
        case .expiringSoon:
            return "Match Expiring Soon"
        }
    }

    var icon: String {
        switch self {
        case .matchFound:
            return "person.2.fill"
        case .partnerCommitted:
            return "hand.thumbsup.fill"
        case .chatUnlocked:
            return "message.fill"
        case .billPaid:
            return "dollarsign.circle.fill"
        case .swapComplete:
            return "checkmark.seal.fill"
        case .reminder:
            return "clock.fill"
        case .expiringSoon:
            return "exclamationmark.clock.fill"
        }
    }

    var iconColor: String {
        switch self {
        case .matchFound:
            return "#5B8A6B"  // Green
        case .partnerCommitted:
            return "#5BA4D4"  // Blue
        case .chatUnlocked:
            return "#5BA4D4"  // Blue
        case .billPaid:
            return "#4CAF7A"  // Success green
        case .swapComplete:
            return "#4CAF7A"  // Success green
        case .reminder:
            return "#E8A54B"  // Warning amber
        case .expiringSoon:
            return "#E07A6B"  // Danger red
        }
    }
}

// MARK: - Notification Service

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    // MARK: - Published Properties

    @Published var hasPermission = false
    @Published var deviceToken: String?
    @Published var pendingNotification: SwapNotificationData?
    @Published var notifications: [AppNotificationItem] = []

    /// Count of unread notifications for badge display
    var unreadCount: Int {
        notifications.filter { $0.isUnread }.count
    }

    // MARK: - Private Properties

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var swapChannel: RealtimeChannelV2?

    private override init() {
        super.init()
    }

    // MARK: - Realtime Subscriptions

    /// Subscribe to swap updates for the current user
    func subscribeToSwapUpdates() async {
        guard let userId = AuthService.shared.currentUser?.id else { return }

        // Unsubscribe from existing channel if any
        await unsubscribeFromSwapUpdates()

        // Create channel for swap updates
        swapChannel = supabase.channel("swap-updates-\(userId.uuidString)")

        // Listen for changes to swaps where user is involved
        let changes = swapChannel?.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "swaps",
            filter: "or(user_a_id.eq.\(userId.uuidString),user_b_id.eq.\(userId.uuidString))"
        )

        // Handle swap updates
        Task {
            guard let changes = changes else { return }
            for await change in changes {
                await handleSwapUpdate(change)
            }
        }

        // Subscribe to channel
        await swapChannel?.subscribe()
        print("Subscribed to swap updates for user \(userId)")
    }

    /// Unsubscribe from swap updates
    func unsubscribeFromSwapUpdates() async {
        await swapChannel?.unsubscribe()
        swapChannel = nil
    }

    /// Handle incoming swap update from Realtime
    private func handleSwapUpdate(_ change: UpdateAction) async {
        guard let userId = AuthService.shared.currentUser?.id else { return }

        // Decode the swap from the change record
        let record = change.record
        guard let swapIdString = record["id"]?.stringValue,
              let swapId = UUID(uuidString: swapIdString),
              let statusString = record["status"]?.stringValue else {
            return
        }

        let oldRecord = change.oldRecord
        let oldStatusString = oldRecord["status"]?.stringValue

        // Determine what changed and show appropriate notification
        let userAIdString = record["user_a_id"]?.stringValue
        let isUserA = userAIdString == userId.uuidString

        // Check for status change to active (both committed)
        if statusString == "active" && oldStatusString == "pending" {
            showInAppToast(
                type: .chatUnlocked,
                message: "Both partners committed! Chat is now unlocked.",
                swapId: swapId
            )
            return
        }

        // Check for status change to completed
        if statusString == "completed" && oldStatusString != "completed" {
            showInAppToast(
                type: .swapComplete,
                message: "Swap complete! You both saved money.",
                swapId: swapId
            )
            return
        }

        // Check for partner fee payment (commitment)
        let userAPaidFee = record["user_a_paid_fee"]?.boolValue ?? false
        let userBPaidFee = record["user_b_paid_fee"]?.boolValue ?? false
        let oldUserAPaidFee = oldRecord["user_a_paid_fee"]?.boolValue ?? false
        let oldUserBPaidFee = oldRecord["user_b_paid_fee"]?.boolValue ?? false

        if isUserA && userBPaidFee && !oldUserBPaidFee {
            showInAppToast(
                type: .partnerCommitted,
                message: "Your partner committed! Chat is now unlocked.",
                swapId: swapId
            )
        } else if !isUserA && userAPaidFee && !oldUserAPaidFee {
            showInAppToast(
                type: .partnerCommitted,
                message: "Your partner committed! Chat is now unlocked.",
                swapId: swapId
            )
        }

        // Check for partner bill payment
        let userAPaidPartner = record["user_a_paid_partner"]?.boolValue ?? false
        let userBPaidPartner = record["user_b_paid_partner"]?.boolValue ?? false
        let oldUserAPaidPartner = oldRecord["user_a_paid_partner"]?.boolValue ?? false
        let oldUserBPaidPartner = oldRecord["user_b_paid_partner"]?.boolValue ?? false

        if isUserA && userBPaidPartner && !oldUserBPaidPartner {
            showInAppToast(
                type: .billPaid,
                message: "Your partner paid your bill!",
                swapId: swapId
            )
        } else if !isUserA && userAPaidPartner && !oldUserAPaidPartner {
            showInAppToast(
                type: .billPaid,
                message: "Your partner paid your bill!",
                swapId: swapId
            )
        }
    }

    // MARK: - Permission Management

    /// Request notification permissions from the user
    func requestPermissions() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            hasPermission = granted

            if granted {
                // Register for remote notifications on main thread
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }

            return granted
        } catch {
            print("Failed to request notification permissions: \(error)")
            return false
        }
    }

    /// Check current notification permission status
    func checkPermissionStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        hasPermission = settings.authorizationStatus == .authorized
    }

    // MARK: - Device Token Management

    /// Register device token received from APNs
    func registerDeviceToken(_ tokenData: Data) async {
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString

        print("APNs Device Token: \(tokenString)")

        // Store token in Supabase
        await storeDeviceToken(tokenString)
    }

    /// Store device token in Supabase for push notifications
    private func storeDeviceToken(_ token: String) async {
        guard let userId = AuthService.shared.currentUser?.id else {
            print("Cannot store device token: No authenticated user")
            return
        }

        do {
            // Upsert the device token (insert or update if exists)
            let record = DeviceTokenRecord(
                userId: userId,
                apnsToken: token
            )

            try await supabase
                .from("device_tokens")
                .upsert(record, onConflict: "user_id")
                .execute()

            print("Device token stored successfully")
        } catch {
            print("Failed to store device token: \(error)")
        }
    }

    /// Remove device token when user logs out
    func removeDeviceToken() async {
        guard let userId = AuthService.shared.currentUser?.id else { return }

        do {
            try await supabase
                .from("device_tokens")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()

            deviceToken = nil
            print("Device token removed")
        } catch {
            print("Failed to remove device token: \(error)")
        }
    }

    // MARK: - Handle Notification Response

    /// Handle when user taps on a notification
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo

        guard let typeString = userInfo["type"] as? String,
              let type = SwapNotificationType(rawValue: typeString) else {
            return
        }

        let swapId = userInfo["swap_id"] as? String

        // Set pending notification for navigation
        pendingNotification = SwapNotificationData(
            type: type,
            swapId: swapId != nil ? UUID(uuidString: swapId!) : nil,
            message: response.notification.request.content.body
        )

        // Post notification for navigation
        NotificationCenter.default.post(
            name: .swapNotificationTapped,
            object: nil,
            userInfo: ["notification": pendingNotification as Any]
        )
    }

    // MARK: - Swap Notification Triggers

    /// Notify when a new match is found
    func notifyMatchFound(swapId: UUID, billAmount: Double) async {
        let message = "A $\(Int(billAmount)) swap is available. Tap to view details."

        // Add to notification history
        addNotification(type: .matchFound, subtitle: message, swapId: swapId)

        await sendLocalNotification(
            type: .matchFound,
            message: message,
            swapId: swapId
        )

        // Also trigger push via Edge Function for the other user
        await triggerPushNotification(
            type: .matchFound,
            message: message,
            swapId: swapId
        )
    }

    /// Notify when partner has committed to the swap
    func notifyPartnerCommitted(swap: BillSwapTransaction, currentUserId: UUID) async {
        let partnerId = swap.isUserA(userId: currentUserId) ? swap.userBId : swap.userAId
        let message = "Your partner committed! Chat is now unlocked."

        // Send push to the partner
        await triggerPushNotificationToUser(
            userId: partnerId,
            type: .partnerCommitted,
            message: message,
            swapId: swap.id
        )
    }

    /// Notify both users when both have committed
    func notifyBothCommitted(swap: BillSwapTransaction) async {
        let message = "Both partners committed! Chat is now unlocked."

        // Notify User A
        await triggerPushNotificationToUser(
            userId: swap.userAId,
            type: .chatUnlocked,
            message: message,
            swapId: swap.id
        )

        // Notify User B
        await triggerPushNotificationToUser(
            userId: swap.userBId,
            type: .chatUnlocked,
            message: message,
            swapId: swap.id
        )
    }

    /// Notify when partner has paid your bill
    func notifyBillPaid(swap: BillSwapTransaction, paidByUserId: UUID, amount: Double) async {
        let recipientId = paidByUserId == swap.userAId ? swap.userBId : swap.userAId
        let message = "Your partner paid your $\(Int(amount)) bill!"

        await triggerPushNotificationToUser(
            userId: recipientId,
            type: .billPaid,
            message: message,
            swapId: swap.id
        )
    }

    /// Notify both users when swap is complete
    func notifySwapComplete(swap: BillSwapTransaction) async {
        let message = "Swap complete! You both saved money."

        // Notify User A
        await triggerPushNotificationToUser(
            userId: swap.userAId,
            type: .swapComplete,
            message: message,
            swapId: swap.id
        )

        // Notify User B
        await triggerPushNotificationToUser(
            userId: swap.userBId,
            type: .swapComplete,
            message: message,
            swapId: swap.id
        )
    }

    // MARK: - Local Notifications

    /// Send a local notification (for immediate display)
    private func sendLocalNotification(type: SwapNotificationType, message: String, swapId: UUID) async {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = message
        content.sound = .default
        content.userInfo = [
            "type": type.rawValue,
            "swap_id": swapId.uuidString
        ]

        let request = UNNotificationRequest(
            identifier: "\(type.rawValue)_\(swapId.uuidString)",
            content: content,
            trigger: nil  // Deliver immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send local notification: \(error)")
        }
    }

    // MARK: - Push Notification Triggers (via Edge Function)

    /// Trigger a push notification via Supabase Edge Function
    private func triggerPushNotification(type: SwapNotificationType, message: String, swapId: UUID) async {
        guard let userId = AuthService.shared.currentUser?.id else { return }

        await triggerPushNotificationToUser(
            userId: userId,
            type: type,
            message: message,
            swapId: swapId
        )
    }

    /// Send push notification to a specific user via Edge Function
    private func triggerPushNotificationToUser(userId: UUID, type: SwapNotificationType, message: String, swapId: UUID) async {
        do {
            let request = PushNotificationRequest(
                userId: userId,
                title: type.title,
                body: message,
                data: PushNotificationData(
                    type: type.rawValue,
                    swapId: swapId.uuidString
                )
            )

            try await supabase.functions.invoke(
                "send-push-notification",
                options: FunctionInvokeOptions(body: request)
            )
        } catch {
            print("Failed to trigger push notification: \(error)")
        }
    }

    // MARK: - In-App Toast

    /// Show an in-app toast notification and add to notification history
    func showInAppToast(type: SwapNotificationType, message: String, swapId: UUID? = nil) {
        pendingNotification = SwapNotificationData(
            type: type,
            swapId: swapId,
            message: message
        )

        // Add to notification history for the bell
        if let appType = AppNotificationType(rawValue: type.rawValue) {
            addNotification(type: appType, subtitle: message, swapId: swapId)
        }

        // Auto-dismiss after 4 seconds
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await MainActor.run {
                if self.pendingNotification?.type == type {
                    self.pendingNotification = nil
                }
            }
        }
    }

    /// Clear pending notification
    func clearPendingNotification() {
        pendingNotification = nil
    }

    // MARK: - Notification History Management

    /// Add a notification to the history (shown in notification bell)
    func addNotification(_ item: AppNotificationItem) {
        notifications.insert(item, at: 0)

        // Keep max 50 notifications
        if notifications.count > 50 {
            notifications = Array(notifications.prefix(50))
        }
    }

    /// Add a notification from swap notification type
    func addNotification(type: AppNotificationType, subtitle: String, swapId: UUID? = nil) {
        let item = AppNotificationItem(
            type: type,
            subtitle: subtitle,
            swapId: swapId
        )
        addNotification(item)
    }

    /// Mark all notifications as read
    func markAllRead() {
        for i in notifications.indices {
            notifications[i].isUnread = false
        }
    }

    /// Mark a specific notification as read
    func markRead(id: UUID) {
        if let idx = notifications.firstIndex(where: { $0.id == id }) {
            notifications[idx].isUnread = false
        }
    }

    /// Clear all notifications
    func clearAllNotifications() {
        notifications.removeAll()
    }
}

// MARK: - Supporting Types

struct SwapNotificationData: Equatable {
    let type: SwapNotificationType
    let swapId: UUID?
    let message: String
}

private struct DeviceTokenRecord: Encodable {
    let userId: UUID
    let apnsToken: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case apnsToken = "apns_token"
    }
}

private struct PushNotificationRequest: Encodable {
    let userId: UUID
    let title: String
    let body: String
    let data: PushNotificationData

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
        case body
        case data
    }
}

private struct PushNotificationData: Encodable {
    let type: String
    let swapId: String

    enum CodingKeys: String, CodingKey {
        case type
        case swapId = "swap_id"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let swapNotificationTapped = Notification.Name("swapNotificationTapped")
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            handleNotificationResponse(response)
        }
        completionHandler()
    }
}
