//
//  BillPortfolioService.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Service for managing user bill portfolio and payday schedule
//

import Foundation
import Supabase

// MARK: - Codable Structs for Supabase

private struct BillInsert: Codable {
    let userId: String
    let billCategory: String
    let providerName: String
    let typicalAmount: Double
    let dueDay: Int
    let isActive: Bool
    let paymentUrl: String?
    let accountIdentifier: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case billCategory = "bill_category"
        case providerName = "provider_name"
        case typicalAmount = "typical_amount"
        case dueDay = "due_day"
        case isActive = "is_active"
        case paymentUrl = "payment_url"
        case accountIdentifier = "account_identifier"
    }
}

private struct BillUpdate: Codable {
    let providerName: String?
    let typicalAmount: Double?
    let dueDay: Int?
    let paymentUrl: String?
    let accountIdentifier: String?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case providerName = "provider_name"
        case typicalAmount = "typical_amount"
        case dueDay = "due_day"
        case paymentUrl = "payment_url"
        case accountIdentifier = "account_identifier"
        case updatedAt = "updated_at"
    }
}

private struct BillDeleteUpdate: Codable {
    let isActive: Bool
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
        case updatedAt = "updated_at"
    }
}

private struct PaydayUpsert: Codable {
    let userId: String
    let paydayType: String
    let paydayDays: [Int]
    let nextPayday: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case paydayType = "payday_type"
        case paydayDays = "payday_days"
        case nextPayday = "next_payday"
    }
}

// MARK: - Errors

enum BillPortfolioError: LocalizedError {
    case notAuthenticated
    case billNotFound
    case paydayNotFound
    case duplicateBill
    case invalidAmount
    case invalidDueDay
    case categoryNotAllowed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .billNotFound:
            return "Bill not found"
        case .paydayNotFound:
            return "Payday schedule not found"
        case .duplicateBill:
            return "This bill already exists in your portfolio"
        case .invalidAmount:
            return "Please enter a valid amount"
        case .invalidDueDay:
            return "Due day must be between 1 and 31"
        case .categoryNotAllowed:
            return "This bill category is locked. Complete more swaps to unlock."
        }
    }
}

// MARK: - Bill Portfolio Service

@MainActor
class BillPortfolioService: ObservableObject {

    // MARK: - Singleton
    static let shared = BillPortfolioService()

    // MARK: - Published Properties
    @Published var userBills: [UserBill] = []
    @Published var paydaySchedule: PaydaySchedule?
    @Published var isLoading = false
    @Published var error: BillPortfolioError?

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Fetch Bills

    /// Fetches all active bills for the current user
    func fetchUserBills() async throws -> [UserBill] {
        guard let session = try? await supabase.auth.session else {
            throw BillPortfolioError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let bills: [UserBill] = try await supabase
            .from("user_bill_portfolio")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .eq("is_active", value: true)
            .order("due_day")
            .execute()
            .value

        self.userBills = bills
        return bills
    }

    /// Fetches a specific bill by ID
    func fetchBill(id: UUID) async throws -> UserBill {
        guard let session = try? await supabase.auth.session else {
            throw BillPortfolioError.notAuthenticated
        }

        let bill: UserBill = try await supabase
            .from("user_bill_portfolio")
            .select()
            .eq("id", value: id.uuidString)
            .eq("user_id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value

        return bill
    }

    // MARK: - Add Bill

    /// Adds a new bill to the user's portfolio
    func addBill(
        category: SwapBillCategory,
        providerName: String,
        typicalAmount: Double,
        dueDay: Int,
        paymentUrl: String? = nil,
        accountIdentifier: String? = nil
    ) async throws -> UserBill {
        guard let session = try? await supabase.auth.session else {
            throw BillPortfolioError.notAuthenticated
        }

        // Validate inputs
        guard typicalAmount > 0 else {
            throw BillPortfolioError.invalidAmount
        }

        guard dueDay >= 1 && dueDay <= 31 else {
            throw BillPortfolioError.invalidDueDay
        }

        // Check if category is allowed for user's tier
        if !TrustLadderService.shared.canSwapCategory(category) {
            throw BillPortfolioError.categoryNotAllowed
        }

        isLoading = true
        defer { isLoading = false }

        let insertData = BillInsert(
            userId: session.user.id.uuidString,
            billCategory: category.rawValue,
            providerName: providerName,
            typicalAmount: typicalAmount,
            dueDay: dueDay,
            isActive: true,
            paymentUrl: paymentUrl,
            accountIdentifier: accountIdentifier
        )

        let bill: UserBill = try await supabase
            .from("user_bill_portfolio")
            .insert(insertData)
            .select()
            .single()
            .execute()
            .value

        // Refresh bills list
        _ = try await fetchUserBills()

        return bill
    }

    // MARK: - Update Bill

    /// Updates an existing bill
    func updateBill(
        id: UUID,
        providerName: String? = nil,
        typicalAmount: Double? = nil,
        dueDay: Int? = nil,
        paymentUrl: String? = nil,
        accountIdentifier: String? = nil
    ) async throws {
        guard let session = try? await supabase.auth.session else {
            throw BillPortfolioError.notAuthenticated
        }

        // Validate inputs if provided
        if let amount = typicalAmount, amount <= 0 {
            throw BillPortfolioError.invalidAmount
        }

        if let day = dueDay, day < 1 || day > 31 {
            throw BillPortfolioError.invalidDueDay
        }

        let updateData = BillUpdate(
            providerName: providerName,
            typicalAmount: typicalAmount,
            dueDay: dueDay,
            paymentUrl: paymentUrl,
            accountIdentifier: accountIdentifier,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("user_bill_portfolio")
            .update(updateData)
            .eq("id", value: id.uuidString)
            .eq("user_id", value: session.user.id.uuidString)
            .execute()

        // Refresh bills list
        _ = try await fetchUserBills()
    }

    // MARK: - Delete Bill

    /// Soft deletes a bill by marking it inactive
    func deleteBill(id: UUID) async throws {
        guard let session = try? await supabase.auth.session else {
            throw BillPortfolioError.notAuthenticated
        }

        let updateData = BillDeleteUpdate(
            isActive: false,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase
            .from("user_bill_portfolio")
            .update(updateData)
            .eq("id", value: id.uuidString)
            .eq("user_id", value: session.user.id.uuidString)
            .execute()

        // Refresh bills list
        _ = try await fetchUserBills()
    }

    // MARK: - Payday Schedule

    /// Fetches the user's payday schedule
    func fetchPaydaySchedule() async throws -> PaydaySchedule? {
        guard let session = try? await supabase.auth.session else {
            throw BillPortfolioError.notAuthenticated
        }

        do {
            let schedule: PaydaySchedule = try await supabase
                .from("user_payday_schedule")
                .select()
                .eq("user_id", value: session.user.id.uuidString)
                .single()
                .execute()
                .value

            self.paydaySchedule = schedule
            return schedule
        } catch {
            // No schedule found
            self.paydaySchedule = nil
            return nil
        }
    }

    /// Creates or updates the user's payday schedule
    func setPaydaySchedule(
        type: PaydayType,
        days: [Int]
    ) async throws -> PaydaySchedule {
        guard let session = try? await supabase.auth.session else {
            throw BillPortfolioError.notAuthenticated
        }

        // Validate days
        for day in days {
            if type == .weekly || type == .biweekly {
                guard day >= 1 && day <= 7 else {
                    throw BillPortfolioError.invalidDueDay
                }
            } else {
                guard day >= 1 && day <= 31 else {
                    throw BillPortfolioError.invalidDueDay
                }
            }
        }

        // Calculate next payday
        let nextPayday = calculateNextPayday(type: type, days: days)

        let upsertData = PaydayUpsert(
            userId: session.user.id.uuidString,
            paydayType: type.rawValue,
            paydayDays: days,
            nextPayday: nextPayday.map { ISO8601DateFormatter().string(from: $0) }
        )

        // Upsert (insert or update)
        let schedule: PaydaySchedule = try await supabase
            .from("user_payday_schedule")
            .upsert(upsertData, onConflict: "user_id")
            .select()
            .single()
            .execute()
            .value

        self.paydaySchedule = schedule
        return schedule
    }

    /// Calculates the next payday based on schedule type
    private func calculateNextPayday(type: PaydayType, days: [Int]) -> Date? {
        let calendar = Calendar.current
        let today = Date()

        switch type {
        case .weekly, .biweekly:
            // days contains weekday (1 = Sunday, 2 = Monday, etc.)
            guard let targetWeekday = days.first else { return nil }
            let currentWeekday = calendar.component(.weekday, from: today)

            var daysToAdd = targetWeekday - currentWeekday
            if daysToAdd <= 0 {
                daysToAdd += (type == .biweekly ? 14 : 7)
            }

            return calendar.date(byAdding: .day, value: daysToAdd, to: today)

        case .semiMonthly, .monthly:
            // days contains day of month
            let currentDay = calendar.component(.day, from: today)
            let sortedDays = days.sorted()

            for day in sortedDays {
                if day > currentDay {
                    var components = calendar.dateComponents([.year, .month], from: today)
                    components.day = day
                    return calendar.date(from: components)
                }
            }

            // Next month
            if let firstDay = sortedDays.first,
               let nextMonth = calendar.date(byAdding: .month, value: 1, to: today) {
                var components = calendar.dateComponents([.year, .month], from: nextMonth)
                components.day = firstDay
                return calendar.date(from: components)
            }

            return nil
        }
    }

    // MARK: - Portfolio Status

    /// Checks if the user has set up their portfolio (at least one bill and payday)
    var isPortfolioComplete: Bool {
        !userBills.isEmpty && paydaySchedule != nil
    }

    /// Returns bills grouped by category
    var billsByCategory: [SwapBillCategory: [UserBill]] {
        Dictionary(grouping: userBills) { bill in
            bill.category ?? .netflix
        }
    }

    /// Returns bills grouped by tier
    var billsByTier: [TrustTier: [UserBill]] {
        Dictionary(grouping: userBills) { bill in
            bill.category?.tier ?? .streamer
        }
    }

    /// Returns total monthly bill amount
    var totalMonthlyAmount: Double {
        userBills.reduce(0) { $0 + $1.typicalAmount }
    }

    /// Returns bills due in the next N days
    func billsDueSoon(withinDays days: Int = 7) -> [UserBill] {
        let today = Calendar.current.component(.day, from: Date())
        let targetDay = (today + days - 1) % 31 + 1

        return userBills.filter { bill in
            if today <= targetDay {
                return bill.dueDay >= today && bill.dueDay <= targetDay
            } else {
                // Wraps around month end
                return bill.dueDay >= today || bill.dueDay <= targetDay
            }
        }
    }

    // MARK: - Load All Data

    /// Loads both bills and payday schedule
    func loadPortfolio() async throws {
        isLoading = true
        defer { isLoading = false }

        async let billsTask = fetchUserBills()
        async let paydayTask = fetchPaydaySchedule()

        _ = try await billsTask
        _ = try? await paydayTask
    }
}
