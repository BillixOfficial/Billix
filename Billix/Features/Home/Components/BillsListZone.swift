//
//  BillsListZone.swift
//  Billix
//

import SwiftUI

// MARK: - Bill Icon Helpers

func billIcon(for category: String) -> String {
    switch category.lowercased() {
    case "electric", "electricity": return "bolt.fill"
    case "gas", "natural gas": return "flame.fill"
    case "water": return "drop.fill"
    case "internet", "wifi": return "wifi"
    case "phone", "mobile", "cell": return "phone.fill"
    case "cable", "tv", "streaming": return "tv.fill"
    case "insurance": return "shield.fill"
    case "rent", "mortgage": return "house.fill"
    default: return "doc.text.fill"
    }
}

func billIconColor(for category: String) -> Color {
    switch category.lowercased() {
    case "electric", "electricity": return .yellow
    case "gas", "natural gas": return .orange
    case "water": return .blue
    case "internet", "wifi": return .purple
    case "phone", "mobile", "cell": return .green
    case "cable", "tv", "streaming": return .red
    case "insurance": return .indigo
    case "rent", "mortgage": return .brown
    default: return HomeTheme.accent
    }
}

func daysUntilDue(dueDay: Int) -> Int {
    let calendar = Calendar.current
    let today = Date()
    let currentDay = calendar.component(.day, from: today)

    if dueDay >= currentDay {
        return dueDay - currentDay
    } else {
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count else {
            return dueDay
        }
        return (daysInMonth - currentDay) + dueDay
    }
}

// MARK: - Bills List Zone

struct BillsListZone: View {
    @State private var bills: [UserBill] = []
    @State private var zipAverages: [BillAverage] = []
    @State private var isLoading = true
    @State private var hasNoBills = false

    private let openAIService = OpenAIService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(HomeTheme.accent)
                Text("Your Bills").sectionHeader()

                Spacer()

                if !hasNoBills && !bills.isEmpty {
                    Button {
                        haptic()
                        NotificationCenter.default.post(
                            name: .navigateToTab,
                            object: nil,
                            userInfo: ["tabIndex": 2]
                        )
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text("Add Bill")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(HomeTheme.accent)
                    }
                }
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 40)
                    Spacer()
                }
                .background(HomeTheme.cardBackground)
                .cornerRadius(HomeTheme.cornerRadius)
                .shadow(color: HomeTheme.shadowColor, radius: HomeTheme.shadowRadius, x: 0, y: 2)
            } else if hasNoBills || bills.isEmpty {
                BillsEmptyState()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(bills.enumerated()), id: \.element.id) { index, bill in
                        BillListRow(
                            bill: bill,
                            zipAverage: getZipAverage(for: bill.billCategory)
                        )

                        if index < bills.count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(HomeTheme.cardBackground)
                .cornerRadius(HomeTheme.cornerRadius)
                .shadow(color: HomeTheme.shadowColor, radius: HomeTheme.shadowRadius, x: 0, y: 2)
            }
        }
        .padding(.horizontal, HomeTheme.horizontalPadding)
        .task {
            await loadBills()
        }
    }

    private func getZipAverage(for category: String) -> BillAverage? {
        zipAverages.first { $0.billType.lowercased() == category.lowercased() }
    }

    @MainActor
    private func loadBills() async {
        isLoading = true
        bills = []
        hasNoBills = true

        do {
            zipAverages = try await openAIService.getNationalAverages(zipCode: "07060")
        } catch {
            print("Failed to load ZIP averages: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Bills Empty State

struct BillsEmptyState: View {
    var body: some View {
        Button {
            haptic()
            NotificationCenter.default.post(
                name: .navigateToTab,
                object: nil,
                userInfo: ["tabIndex": 2]
            )
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(HomeTheme.accent.opacity(0.12))
                        .frame(width: 64, height: 64)

                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 28))
                        .foregroundColor(HomeTheme.accent)
                }

                VStack(spacing: 6) {
                    Text("Upload your first bill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(HomeTheme.primaryText)

                    Text("Get insights, find savings,\nand track your spending")
                        .font(.system(size: 13))
                        .foregroundColor(HomeTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 6) {
                    Text("Upload Bill")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(HomeTheme.accent)
                .cornerRadius(12)
            }
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)
            .background(HomeTheme.cardBackground)
            .cornerRadius(HomeTheme.cornerRadius)
            .shadow(color: HomeTheme.shadowColor, radius: HomeTheme.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
}

// MARK: - Bill List Row

struct BillListRow: View {
    let bill: UserBill
    let zipAverage: BillAverage?

    private var iconName: String { billIcon(for: bill.billCategory) }
    private var iconColor: Color { billIconColor(for: bill.billCategory) }
    private var daysToDue: Int { daysUntilDue(dueDay: bill.dueDay) }

    var body: some View {
        Button {
            haptic()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: iconName)
                        .font(.system(size: HomeTheme.iconMedium))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(bill.providerName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(HomeTheme.primaryText)

                        if daysToDue <= 7 {
                            Text("Due in \(daysToDue)d")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HomeTheme.danger)
                                .cornerRadius(4)
                        }
                    }

                    HStack(spacing: 4) {
                        if let avg = zipAverage {
                            let diff = bill.typicalAmount - avg.average
                            if abs(diff) < 5 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 9))
                                Text("On par with ZIP average")
                                    .font(.system(size: 11, weight: .medium))
                            } else if diff > 0 {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 9))
                                Text("$\(Int(diff)) above ZIP avg")
                                    .font(.system(size: 11, weight: .medium))
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 9))
                                Text("$\(Int(abs(diff))) below ZIP avg")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                    }
                    .foregroundColor(zipComparisonColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", bill.typicalAmount))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(HomeTheme.primaryText)

                    Text("/mo")
                        .font(.system(size: 11))
                        .foregroundColor(HomeTheme.secondaryText)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HomeTheme.secondaryText.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var zipComparisonColor: Color {
        guard let avg = zipAverage else { return HomeTheme.secondaryText }
        let diff = bill.typicalAmount - avg.average
        if abs(diff) < 5 { return HomeTheme.success }
        else if diff > 0 { return HomeTheme.warning }
        else { return HomeTheme.success }
    }
}
