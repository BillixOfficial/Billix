//
//  CreditHistoryView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Full credit transaction history view
//

import SwiftUI

struct CreditHistoryView: View {
    @ObservedObject private var creditsService = UnlockCreditsService.shared

    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText = ""

    // Theme colors
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case earned = "Earned"
        case spent = "Spent"
    }

    private var filteredTransactions: [UnlockCreditTransaction] {
        var transactions = creditsService.recentTransactions

        switch selectedFilter {
        case .earned:
            transactions = transactions.filter { $0.isPositive }
        case .spent:
            transactions = transactions.filter { !$0.isPositive }
        case .all:
            break
        }

        if !searchText.isEmpty {
            transactions = transactions.filter {
                $0.description?.lowercased().contains(searchText.lowercased()) ?? false ||
                $0.type?.displayName.lowercased().contains(searchText.lowercased()) ?? false
            }
        }

        return transactions
    }

    private var groupedTransactions: [(String, [UnlockCreditTransaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction -> String in
            let calendar = Calendar.current
            if calendar.isDateInToday(transaction.createdAt) {
                return "Today"
            } else if calendar.isDateInYesterday(transaction.createdAt) {
                return "Yesterday"
            } else if calendar.isDate(transaction.createdAt, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else if calendar.isDate(transaction.createdAt, equalTo: Date(), toGranularity: .month) {
                return "This Month"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: transaction.createdAt)
            }
        }

        let sortOrder = ["Today", "Yesterday", "This Week", "This Month"]

        return grouped.sorted { first, second in
            let firstIndex = sortOrder.firstIndex(of: first.key) ?? Int.max
            let secondIndex = sortOrder.firstIndex(of: second.key) ?? Int.max

            if firstIndex != Int.max || secondIndex != Int.max {
                return firstIndex < secondIndex
            }

            // For month names, sort by date descending
            return first.value.first?.createdAt ?? Date() > second.value.first?.createdAt ?? Date()
        }
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Summary header
                summaryHeader

                // Filter tabs
                filterTabs

                // Search bar
                searchBar

                // Transactions list
                if filteredTransactions.isEmpty {
                    emptyState
                } else {
                    transactionsList
                }
            }
        }
        .navigationTitle("Credit History")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await creditsService.loadCredits()
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                summaryItem(
                    value: "\(creditsService.balance)",
                    label: "Current Balance",
                    icon: "star.circle.fill",
                    color: .yellow
                )

                Divider()
                    .frame(height: 40)
                    .background(secondaryText.opacity(0.3))

                summaryItem(
                    value: "+\(creditsService.lifetimeEarned)",
                    label: "Total Earned",
                    icon: "arrow.up.circle.fill",
                    color: .green
                )

                Divider()
                    .frame(height: 40)
                    .background(secondaryText.opacity(0.3))

                summaryItem(
                    value: "-\(creditsService.lifetimeSpent)",
                    label: "Total Spent",
                    icon: "arrow.down.circle.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(cardBg)
    }

    private func summaryItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryText)
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(secondaryText)
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        HStack(spacing: 8) {
            ForEach(TransactionFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selectedFilter == filter ? .black : primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedFilter == filter ? accent : cardBg)
                        .cornerRadius(20)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(secondaryText)

            TextField("Search transactions", text: $searchText)
                .foregroundColor(primaryText)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(secondaryText)
                }
            }
        }
        .padding(12)
        .background(cardBg)
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Transactions List

    private var transactionsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedTransactions, id: \.0) { group, transactions in
                    VStack(alignment: .leading, spacing: 8) {
                        // Section header
                        Text(group)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(secondaryText)
                            .padding(.horizontal)

                        // Transactions
                        VStack(spacing: 1) {
                            ForEach(transactions) { transaction in
                                transactionRow(transaction)
                            }
                        }
                        .background(cardBg)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }

    private func transactionRow(_ transaction: UnlockCreditTransaction) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill((transaction.isPositive ? Color.green : Color.orange).opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: transactionIcon(transaction.type))
                    .font(.system(size: 16))
                    .foregroundColor(transaction.isPositive ? .green : .orange)
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description ?? transaction.type?.displayName ?? "Transaction")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(primaryText)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let type = transaction.type {
                        Text(type.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(secondaryText)
                    }

                    Text(transaction.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText.opacity(0.7))
                }
            }

            Spacer()

            // Amount
            Text(transaction.formattedAmount)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(transaction.isPositive ? .green : .orange)
        }
        .padding()
        .background(background)
    }

    private func transactionIcon(_ type: UnlockCreditType?) -> String {
        switch type {
        case .receiptUpload: return "doc.text.image"
        case .referral: return "person.badge.plus"
        case .dailyLogin: return "calendar"
        case .swapCompletion: return "arrow.left.arrow.right"
        case .featureUnlock: return "lock.open"
        case .promotion: return "gift"
        case .refund: return "arrow.uturn.backward"
        case .none: return "star.circle"
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundColor(secondaryText)

            Text("No transactions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            Text(selectedFilter == .all ? "Your credit history will appear here" : "No \(selectedFilter.rawValue.lowercased()) transactions found")
                .font(.system(size: 13))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Transaction Detail View

struct TransactionDetailView: View {
    let transaction: UnlockCreditTransaction

    @Environment(\.dismiss) private var dismiss

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 24) {
                // Amount display
                VStack(spacing: 8) {
                    Image(systemName: transaction.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(transaction.isPositive ? .green : .orange)

                    Text(transaction.formattedAmount)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(transaction.isPositive ? .green : .orange)

                    Text("credits")
                        .font(.system(size: 14))
                        .foregroundColor(secondaryText)
                }
                .padding(.top, 20)

                // Details card
                VStack(spacing: 16) {
                    detailRow("Type", value: transaction.type?.displayName ?? "Unknown")

                    if let description = transaction.description {
                        detailRow("Description", value: description)
                    }

                    detailRow("Date", value: transaction.createdAt.formatted(date: .long, time: .shortened))

                    detailRow("Transaction ID", value: transaction.id.uuidString.prefix(8) + "...")
                }
                .padding()
                .background(cardBg)
                .cornerRadius(16)

                Spacer()

                // Done button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accent)
                        .cornerRadius(14)
                }
            }
            .padding()
        }
        .navigationTitle("Transaction Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(primaryText)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        CreditHistoryView()
    }
    .preferredColorScheme(.dark)
}
