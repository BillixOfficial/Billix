//
//  BillTickerZone.swift
//  Billix
//

import SwiftUI

// MARK: - Ticker Item Model

struct TickerItem: Identifiable {
    let id = UUID()
    let icon: String
    let category: String
    let value: String
    let change: String
    let isUp: Bool
}

// MARK: - Bill Ticker Zone

struct BillTickerZone: View {
    let zipCode: String

    @ObservedObject private var openAIService = OpenAIService.shared
    @State private var averages: [BillAverage] = []
    @State private var isLoading = true

    private var displayItems: [TickerItem] {
        if averages.isEmpty {
            return [
                TickerItem(icon: "bolt.fill", category: "Electric", value: "$142", change: "avg", isUp: false),
                TickerItem(icon: "wifi", category: "Internet", value: "$65", change: "avg", isUp: false),
                TickerItem(icon: "flame.fill", category: "Gas", value: "$78", change: "avg", isUp: false),
                TickerItem(icon: "iphone", category: "Phone", value: "$85", change: "avg", isUp: false),
            ]
        }

        return averages.map { avg in
            let icon: String
            switch avg.billType.lowercased() {
            case "electric": icon = "bolt.fill"
            case "internet": icon = "wifi"
            case "gas": icon = "flame.fill"
            case "phone": icon = "iphone"
            default: icon = "dollarsign.circle.fill"
            }

            return TickerItem(
                icon: icon,
                category: avg.billType,
                value: "$\(Int(avg.average))",
                change: "avg",
                isUp: false
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: HomeTheme.iconSmall))
                        .foregroundColor(HomeTheme.info)
                    Text("National Averages")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(HomeTheme.secondaryText)
                }

                Spacer()

                if !zipCode.isEmpty {
                    Text("for \(zipCode)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(HomeTheme.accent)
                }
            }
            .padding(.horizontal, HomeTheme.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(displayItems) { item in
                        NationalAverageCard(item: item, isLoading: isLoading && averages.isEmpty)
                    }
                }
                .padding(.horizontal, HomeTheme.horizontalPadding)
            }
        }
        .task {
            guard !zipCode.isEmpty else { return }
            do {
                averages = try await openAIService.getNationalAverages(zipCode: zipCode)
                isLoading = false
            } catch {
                print("❌ Error: Failed to load national averages: \(error)")
                isLoading = false
            }
        }
    }
}

// MARK: - National Average Card

struct NationalAverageCard: View {
    let item: TickerItem
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HomeTheme.accent)
                    .frame(width: 32, height: 32)
                    .background(HomeTheme.accentLight)
                    .cornerRadius(8)

                Text(item.category)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HomeTheme.primaryText)
            }

            VStack(alignment: .leading, spacing: 2) {
                if isLoading {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(HomeTheme.secondaryText.opacity(0.2))
                        .frame(width: 60, height: 20)
                } else {
                    Text(item.value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(HomeTheme.primaryText)
                }

                Text("/month")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(HomeTheme.secondaryText)
            }

            HStack(spacing: 4) {
                Text("You: ---")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(HomeTheme.secondaryText)
            }
        }
        .frame(width: 110)
        .padding(12)
        .background(HomeTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: HomeTheme.shadowColor, radius: HomeTheme.shadowRadius, x: 0, y: 2)
    }
}

// MARK: - Ticker Card

struct TickerCard: View {
    let item: TickerItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(HomeTheme.accent)
                .frame(width: 32, height: 32)
                .background(HomeTheme.accentLight)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(HomeTheme.secondaryText)
                HStack(spacing: 4) {
                    Text(item.value)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(HomeTheme.primaryText)
                    Text(item.change)
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: item.isUp ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(item.isUp ? HomeTheme.danger : HomeTheme.success)
            }
        }
        .padding(12)
        .background(HomeTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: HomeTheme.shadowColor, radius: HomeTheme.shadowRadius, x: 0, y: 2)
    }
}
