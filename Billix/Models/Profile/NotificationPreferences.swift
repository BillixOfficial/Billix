import Foundation

// MARK: - Notification Preferences Model

struct NotificationPreferences: Codable, Equatable {
    // Bill Alerts
    var billDueDates: Bool
    var promoExpiration: Bool
    var billSpikes: Bool

    // Savings Opportunities
    var savingsOpportunities: Bool
    var clusterOffers: Bool

    // App & Account
    var creditsRewards: Bool
    var productUpdates: Bool

    // Channel preferences
    var criticalAlertsSMS: Bool
    var emailNotifications: Bool
    var pushNotifications: Bool

    static let `default` = NotificationPreferences(
        billDueDates: true,
        promoExpiration: true,
        billSpikes: true,
        savingsOpportunities: true,
        clusterOffers: false,
        creditsRewards: true,
        productUpdates: false,
        criticalAlertsSMS: true,
        emailNotifications: true,
        pushNotifications: true
    )
}
