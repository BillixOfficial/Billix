//
//  PriceTargetService.swift
//  Billix
//
//  Service for managing user price targets - "Name Your Price" feature
//

import SwiftUI
import Combine

// MARK: - Price Bill Type

enum PriceBillType: String, Codable, CaseIterable, Identifiable {
    case electric
    case internet
    case gas
    case phone
    case water
    case trash
    case autoInsurance = "auto_insurance"
    case homeInsurance = "home_insurance"
    case streaming
    case cable
    case rent

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .electric: return "bolt.fill"
        case .internet: return "wifi"
        case .gas: return "flame.fill"
        case .phone: return "iphone"
        case .water: return "drop.fill"
        case .trash: return "trash.fill"
        case .autoInsurance: return "car.fill"
        case .homeInsurance: return "house.fill"
        case .streaming: return "play.tv.fill"
        case .cable: return "tv.fill"
        case .rent: return "building.2.fill"
        }
    }

    var displayName: String {
        switch self {
        case .electric: return "Electric"
        case .internet: return "Internet"
        case .gas: return "Gas"
        case .phone: return "Phone"
        case .water: return "Water"
        case .trash: return "Trash"
        case .autoInsurance: return "Auto Insurance"
        case .homeInsurance: return "Home Insurance"
        case .streaming: return "Streaming"
        case .cable: return "Cable"
        case .rent: return "Rent"
        }
    }

    var color: Color {
        switch self {
        case .electric: return .yellow
        case .internet: return .purple
        case .gas: return .orange
        case .phone: return .green
        case .water: return .blue
        case .trash: return .brown
        case .autoInsurance: return .red
        case .homeInsurance: return .teal
        case .streaming: return .pink
        case .cable: return .indigo
        case .rent: return Color(hex: "#5B8A6B")
        }
    }

    // Default regional averages (fallback)
    var defaultAverage: Double {
        switch self {
        case .electric: return 153
        case .internet: return 75
        case .gas: return 95
        case .phone: return 85
        case .water: return 45
        case .trash: return 35
        case .autoInsurance: return 165
        case .homeInsurance: return 125
        case .streaming: return 45
        case .cable: return 95
        case .rent: return 1650
        }
    }

    // Categories for organizing in UI
    var category: PriceBillCategory {
        switch self {
        case .electric, .gas, .water, .trash:
            return .utilities
        case .internet, .phone, .cable, .streaming:
            return .telecom
        case .autoInsurance, .homeInsurance:
            return .insurance
        case .rent:
            return .housing
        }
    }
}

enum PriceBillCategory: String, CaseIterable {
    case utilities = "Utilities"
    case telecom = "Internet & Phone"
    case insurance = "Insurance"
    case housing = "Housing"

    var billTypes: [PriceBillType] {
        PriceBillType.allCases.filter { $0.category == self }
    }
}

// MARK: - Contact Preference

enum ContactPreference: String, Codable, CaseIterable {
    case email = "email"
    case push = "push"
    case sms = "sms"
    case none = "none"

    var displayName: String {
        switch self {
        case .email: return "Email"
        case .push: return "Push Notifications"
        case .sms: return "Text Message"
        case .none: return "No alerts"
        }
    }

    var icon: String {
        switch self {
        case .email: return "envelope.fill"
        case .push: return "bell.fill"
        case .sms: return "message.fill"
        case .none: return "bell.slash.fill"
        }
    }
}

// MARK: - Price Target Model

struct PriceTarget: Codable, Identifiable {
    let id: UUID
    let billType: PriceBillType
    var targetAmount: Double
    var currentProvider: String?
    var currentAmount: Double?
    var contactPreference: ContactPreference
    let createdAt: Date
    var updatedAt: Date

    // Computed property for actual savings based on current amount
    var actualSavings: Double? {
        guard let current = currentAmount else { return nil }
        return max(0, current - targetAmount)
    }

    init(
        billType: PriceBillType,
        targetAmount: Double,
        currentProvider: String? = nil,
        currentAmount: Double? = nil,
        contactPreference: ContactPreference = .push
    ) {
        self.id = UUID()
        self.billType = billType
        self.targetAmount = targetAmount
        self.currentProvider = currentProvider
        self.currentAmount = currentAmount
        self.contactPreference = contactPreference
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Supabase Price Target (for API read)

struct SupabasePriceTarget: Codable {
    let id: String
    let userId: String
    let billType: String
    let targetAmount: Double
    let currentProvider: String?
    let currentAmount: Double?
    let contactPreference: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case billType = "bill_type"
        case targetAmount = "target_amount"
        case currentProvider = "current_provider"
        case currentAmount = "current_amount"
        case contactPreference = "contact_preference"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Supabase Price Target Insert (for API write)

struct SupabasePriceTargetInsert: Encodable {
    let id: String
    let userId: String
    let billType: String
    let targetAmount: Double
    let currentProvider: String?
    let currentAmount: Double?
    let contactPreference: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case billType = "bill_type"
        case targetAmount = "target_amount"
        case currentProvider = "current_provider"
        case currentAmount = "current_amount"
        case contactPreference = "contact_preference"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Price Option (available deals/matches)

struct PriceOption: Identifiable {
    let id = UUID()
    let type: PriceOptionType
    let title: String
    let subtitle: String
    let action: PriceOptionAction
}

enum PriceOptionType {
    case betterRate
    case billConnection
    case negotiation
    case relief
    case expertCall

    var icon: String {
        switch self {
        case .betterRate: return "tag.fill"
        case .billConnection: return "person.2.fill"
        case .negotiation: return "text.bubble.fill"
        case .relief: return "heart.circle.fill"
        case .expertCall: return "phone.fill"
        }
    }

    var color: Color {
        switch self {
        case .betterRate: return Color(hex: "#5B8A6B")
        case .billConnection: return Color.billixDarkTeal
        case .negotiation: return Color(hex: "#5BA4D4")
        case .relief: return Color(hex: "#E07A6B")
        case .expertCall: return Color.billixPurple
        }
    }
}

enum PriceOptionAction {
    case viewRates
    case openBillConnection
    case showNegotiationScript
    case openRelief
    case bookExpert
}

// MARK: - Price Target Service

@MainActor
class PriceTargetService: ObservableObject {
    static let shared = PriceTargetService()

    @Published var priceTargets: [PriceTarget] = []
    @Published var isLoading = false
    @Published var isSyncing = false

    private let storageKey = "billix_price_targets"
    private let supabase = SupabaseService.shared.client

    init() {
        loadTargets()
    }

    // MARK: - CRUD Operations

    func setTarget(
        billType: PriceBillType,
        targetAmount: Double,
        currentProvider: String?,
        currentAmount: Double?,
        contactPreference: ContactPreference
    ) {
        // Check if target already exists for this bill type
        if let index = priceTargets.firstIndex(where: { $0.billType == billType }) {
            priceTargets[index].targetAmount = targetAmount
            priceTargets[index].currentProvider = currentProvider
            priceTargets[index].currentAmount = currentAmount
            priceTargets[index].contactPreference = contactPreference
            priceTargets[index].updatedAt = Date()
        } else {
            let newTarget = PriceTarget(
                billType: billType,
                targetAmount: targetAmount,
                currentProvider: currentProvider,
                currentAmount: currentAmount,
                contactPreference: contactPreference
            )
            priceTargets.append(newTarget)
        }
        saveTargets()

        // Sync to Supabase in background
        Task {
            await syncToSupabase(billType: billType)
        }
    }

    func removeTarget(billType: PriceBillType) {
        priceTargets.removeAll { $0.billType == billType }
        saveTargets()
    }

    func getTarget(for billType: PriceBillType) -> PriceTarget? {
        priceTargets.first { $0.billType == billType }
    }

    func hasTarget(for billType: PriceBillType) -> Bool {
        priceTargets.contains { $0.billType == billType }
    }

    // MARK: - Regional Averages

    func getRegionalAverage(for billType: PriceBillType, state: String) -> Double {
        // Get base average
        let baseAverage = billType.defaultAverage

        // Apply regional multiplier
        let multiplier = getRegionMultiplier(for: state)

        // Apply daily variation for dynamic feel
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let variation = sin(Double(dayOfYear) * 0.1) * 0.05
        let dailyMultiplier = 1.0 + variation

        return baseAverage * multiplier * dailyMultiplier
    }

    private func getRegionMultiplier(for state: String) -> Double {
        let stateUpper = state.uppercased()
        let northeast = ["CT", "ME", "MA", "NH", "NJ", "NY", "PA", "RI", "VT"]
        let southeast = ["AL", "AR", "FL", "GA", "KY", "LA", "MS", "NC", "SC", "TN", "VA", "WV"]
        let midwest = ["IL", "IN", "IA", "KS", "MI", "MN", "MO", "NE", "ND", "OH", "SD", "WI"]
        let southwest = ["AZ", "NM", "OK", "TX"]
        let west = ["AK", "CA", "CO", "HI", "ID", "MT", "NV", "OR", "UT", "WA", "WY"]

        if northeast.contains(stateUpper) { return 1.08 }
        if southeast.contains(stateUpper) { return 0.95 }
        if midwest.contains(stateUpper) { return 0.97 }
        if southwest.contains(stateUpper) { return 1.02 }
        if west.contains(stateUpper) { return 1.12 }
        return 1.0
    }

    // MARK: - Calculate Savings

    func calculateSavings(for target: PriceTarget, state: String) -> Double {
        let regionalAvg = getRegionalAverage(for: target.billType, state: state)
        return max(0, regionalAvg - target.targetAmount)
    }

    // MARK: - Generate Options

    func getOptions(for billType: PriceBillType, targetAmount: Double, state: String) -> [PriceOption] {
        var options: [PriceOption] = []
        let regionalAvg = getRegionalAverage(for: billType, state: state)

        // Better rates option
        options.append(PriceOption(
            type: .betterRate,
            title: "Better rates in your area",
            subtitle: "Compare plans and potentially save",
            action: .viewRates
        ))

        // Bill Connection option
        options.append(PriceOption(
            type: .billConnection,
            title: "Bill Connection matches",
            subtitle: "Community members who can help",
            action: .openBillConnection
        ))

        // Negotiation option
        options.append(PriceOption(
            type: .negotiation,
            title: "Negotiation scripts ready",
            subtitle: "Proven tactics that work",
            action: .showNegotiationScript
        ))

        // Relief option (only if target is significantly below average)
        if targetAmount < regionalAvg * 0.6 {
            options.append(PriceOption(
                type: .relief,
                title: "Relief programs available",
                subtitle: "You may qualify for assistance",
                action: .openRelief
            ))
        }

        // Expert call option - always available
        options.append(PriceOption(
            type: .expertCall,
            title: "Talk to a Billix Expert",
            subtitle: "Real human, step-by-step guidance",
            action: .bookExpert
        ))

        return options
    }

    // MARK: - Persistence (Local)

    private func loadTargets() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let targets = try? JSONDecoder().decode([PriceTarget].self, from: data) else {
            return
        }
        priceTargets = targets
    }

    private func saveTargets() {
        guard let data = try? JSONEncoder().encode(priceTargets) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    // MARK: - Supabase Sync

    private func syncToSupabase(billType: PriceBillType) async {
        guard let target = getTarget(for: billType),
              let userId = try? await supabase.auth.session.user.id.uuidString else {
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        let formatter = ISO8601DateFormatter()

        let supabaseTarget = SupabasePriceTargetInsert(
            id: target.id.uuidString,
            userId: userId,
            billType: target.billType.rawValue,
            targetAmount: target.targetAmount,
            currentProvider: target.currentProvider,
            currentAmount: target.currentAmount,
            contactPreference: target.contactPreference.rawValue,
            createdAt: formatter.string(from: target.createdAt),
            updatedAt: formatter.string(from: target.updatedAt)
        )

        do {
            try await supabase
                .from("price_targets")
                .upsert(supabaseTarget, onConflict: "user_id,bill_type")
                .execute()

            // Track in deal_interests for analytics
            await trackPriceTargetInterest(target: target, userId: userId)

            // Send confirmation email to user
            await sendConfirmationEmail(target: target)

        } catch {
            print("Failed to sync price target: \(error)")
        }
    }

    // MARK: - Track Price Target Interest

    private func trackPriceTargetInterest(target: PriceTarget, userId: String) async {
        // Get user info from session
        let userEmail = try? await supabase.auth.session.user.email
        let zipCode = UserDefaults.standard.string(forKey: "user_zip_code") ?? ""
        let city = UserDefaults.standard.string(forKey: "user_city") ?? ""
        let state = UserDefaults.standard.string(forKey: "user_state") ?? ""

        struct PriceTargetInterestInsert: Encodable {
            let user_id: String?
            let deal_title: String
            let deal_description: String
            let deal_category: String
            let zip_code: String
            let city: String
            let state: String
            let user_email: String?
            let user_name: String?
            let request_type: String
        }

        let description = target.currentProvider != nil
            ? "Target: $\(Int(target.targetAmount))/mo, Provider: \(target.currentProvider!)"
            : "Target: $\(Int(target.targetAmount))/mo"

        let insert = PriceTargetInterestInsert(
            user_id: userId,
            deal_title: "\(target.billType.displayName) Price Target: $\(Int(target.targetAmount))/mo",
            deal_description: description,
            deal_category: "price_target",
            zip_code: zipCode,
            city: city,
            state: state,
            user_email: userEmail,
            user_name: nil,
            request_type: "price_target"
        )

        do {
            try await supabase
                .from("deal_interests")
                .insert(insert)
                .execute()
            print("✅ Price target tracked in deal_interests")
        } catch {
            print("⚠️ Failed to track price target interest: \(error)")
        }
    }

    // MARK: - Send Confirmation Email

    private func sendConfirmationEmail(target: PriceTarget) async {
        guard let userEmail = try? await supabase.auth.session.user.email else {
            print("⚠️ No user email for confirmation")
            return
        }

        struct EmailRequest: Encodable {
            let billType: String
            let targetAmount: Double
            let currentProvider: String?
            let currentAmount: Double?
            let userEmail: String
            let userName: String?
        }

        let request = EmailRequest(
            billType: target.billType.displayName,
            targetAmount: target.targetAmount,
            currentProvider: target.currentProvider,
            currentAmount: target.currentAmount,
            userEmail: userEmail,
            userName: nil
        )

        do {
            try await supabase.functions
                .invoke("notify-price-target", options: .init(body: request))
            print("✅ Price target confirmation email sent")
        } catch {
            print("⚠️ Failed to send confirmation email: \(error)")
        }
    }

    func syncAllToSupabase() async {
        for target in priceTargets {
            await syncToSupabase(billType: target.billType)
        }
    }

    func loadFromSupabase() async {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response: [SupabasePriceTarget] = try await supabase
                .from("price_targets")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            let formatter = ISO8601DateFormatter()

            // Convert Supabase targets to local targets
            var newTargets: [PriceTarget] = []
            for supaTarget in response {
                guard let billType = PriceBillType(rawValue: supaTarget.billType),
                      let createdAt = formatter.date(from: supaTarget.createdAt),
                      let updatedAt = formatter.date(from: supaTarget.updatedAt) else {
                    continue
                }

                var target = PriceTarget(
                    billType: billType,
                    targetAmount: supaTarget.targetAmount,
                    currentProvider: supaTarget.currentProvider,
                    currentAmount: supaTarget.currentAmount,
                    contactPreference: ContactPreference(rawValue: supaTarget.contactPreference) ?? .push
                )
                // Override the auto-generated dates
                newTargets.append(target)
            }

            // Merge with local targets (local takes precedence if more recent)
            for newTarget in newTargets {
                if let existingIndex = priceTargets.firstIndex(where: { $0.billType == newTarget.billType }) {
                    if newTarget.updatedAt > priceTargets[existingIndex].updatedAt {
                        priceTargets[existingIndex] = newTarget
                    }
                } else {
                    priceTargets.append(newTarget)
                }
            }

            saveTargets()
        } catch {
            print("Failed to load price targets from Supabase: \(error)")
        }
    }
}
