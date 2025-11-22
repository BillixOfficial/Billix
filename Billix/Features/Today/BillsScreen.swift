import SwiftUI

/// Full bills management screen
/// TODO: Implement comprehensive bill tracking, editing, and management features
struct BillsScreen: View {
    @State private var bills: [Bill] = Bill.mockBills
    @State private var selectedFilter: BillFilter = .all

    enum BillFilter: String, CaseIterable {
        case all = "All"
        case upcoming = "Upcoming"
        case overdue = "Overdue"
        case paid = "Paid"
    }

    var filteredBills: [Bill] {
        switch selectedFilter {
        case .all:
            return bills
        case .upcoming:
            return bills.filter { $0.isDueSoon }
        case .overdue:
            return bills.filter { $0.isOverdue }
        case .paid:
            return bills.filter { $0.isPaid }
        }
    }

    var totalMonthly: Double {
        bills.filter { $0.isRecurring && $0.frequency == .monthly }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Monthly Total")
                        .font(.system(size: 15))
                        .foregroundColor(.billixMediumGreen)

                    Text("$\(Int(totalMonthly))")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)

                    HStack(spacing: 20) {
                        Stat(icon: "exclamationmark.circle.fill", label: "\(bills.filter { $0.isOverdue }.count) overdue", color: .red)
                        Stat(icon: "clock.fill", label: "\(bills.filter { $0.isDueSoon }.count) due soon", color: .billixPendingOrange)
                        Stat(icon: "checkmark.circle.fill", label: "\(bills.filter { $0.isPaid }.count) paid", color: .billixMoneyGreen)
                    }
                }
                .padding(20)
                .billixCard()
                .padding(.horizontal, 20)

                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(BillFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedFilter == filter ? .white : .billixDarkGreen)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedFilter == filter ? Color.billixLoginTeal : Color.white)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(selectedFilter == filter ? 0 : 0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Bills list
                VStack(spacing: 12) {
                    ForEach(filteredBills.sorted(by: { $0.dueDate < $1.dueDate })) { bill in
                        BillCard(bill: bill)
                    }
                }
                .padding(.horizontal, 20)

                if filteredBills.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.billixMediumGreen)

                        Text("No bills found")
                            .font(.system(size: 16))
                            .foregroundColor(.billixDarkGreen)

                        Text("Try selecting a different filter")
                            .font(.system(size: 14))
                            .foregroundColor(.billixMediumGreen)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }

                Spacer()
                    .frame(height: 32)
            }
            .padding(.top, 8)
        }
        .background(Color.billixLightGreen.opacity(0.3))
        .navigationTitle("Your Bills")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // TODO: Add new bill
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.billixLoginTeal)
                }
            }
        }
    }
}

struct Stat: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.billixMediumGreen)
        }
    }
}

struct BillCard: View {
    let bill: Bill

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: bill.categoryIcon)
                .font(.system(size: 20))
                .foregroundColor(bill.isOverdue ? .red : .billixLoginTeal)
                .frame(width: 48, height: 48)
                .background((bill.isOverdue ? Color.red : Color.billixLoginTeal).opacity(0.1))
                .cornerRadius(12)

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(bill.providerName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                HStack(spacing: 8) {
                    Text(bill.category)
                        .font(.system(size: 13))
                        .foregroundColor(.billixMediumGreen)

                    Text("•")
                        .foregroundColor(.billixMediumGreen.opacity(0.5))

                    if bill.isOverdue {
                        Text("Overdue by \(abs(bill.daysUntilDue))d")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                    } else if bill.isPaid {
                        Text("Paid")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.billixMoneyGreen)
                    } else {
                        Text("Due in \(bill.daysUntilDue)d")
                            .font(.system(size: 13))
                            .foregroundColor(.billixMediumGreen)
                    }
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(bill.amount))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                if let frequency = bill.frequency {
                    Text(frequency.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.billixMediumGreen)
                }
            }
        }
        .padding(16)
        .background(bill.isOverdue ? Color.red.opacity(0.05) : Color.white)
        .billixCard(cornerRadius: 16, borderColor: bill.isOverdue ? Color.red.opacity(0.3) : Color.gray.opacity(0.12))
    }
}

#Preview {
    NavigationView {
        BillsScreen()
    }
}
