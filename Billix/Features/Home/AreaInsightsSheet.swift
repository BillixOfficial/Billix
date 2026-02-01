//
//  AreaInsightsSheet.swift
//  Billix
//
//  Local area insights - providers, averages, deals
//

import SwiftUI

struct AreaInsightsSheet: View {
    let city: String
    let state: String
    let zipCode: String

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Location Header
                    locationHeader

                    // Local Providers
                    providersSection

                    // Area Averages
                    averagesSection

                    // Local Deals
                    dealsSection
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Area Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                // Simulate loading
                try? await Task.sleep(nanoseconds: 500_000_000)
                isLoading = false
            }
        }
    }

    // MARK: - Location Header

    private var locationHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.fill")
                .font(.title2)
                .foregroundStyle(Color.billixDarkTeal)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(city), \(state)")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(zipCode)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                // TODO: Allow changing location
            } label: {
                Text("Change")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.billixDarkTeal)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Providers Section

    private var providersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            InsightsSectionHeader(title: "Local Utility Providers", icon: "building.2.fill")

            VStack(spacing: 0) {
                ForEach(localProviders, id: \.name) { provider in
                    ProviderRow(provider: provider)

                    if provider.name != localProviders.last?.name {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var localProviders: [LocalProvider] {
        // Mock data based on NJ ZIP codes - would fetch from backend
        [
            LocalProvider(name: "PSE&G", type: "Electric & Gas", icon: "bolt.fill", color: .yellow),
            LocalProvider(name: "New Jersey American Water", type: "Water", icon: "drop.fill", color: .blue),
            LocalProvider(name: "Elizabethtown Gas", type: "Natural Gas", icon: "flame.fill", color: .orange)
        ]
    }

    // MARK: - Averages Section

    private var averagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            InsightsSectionHeader(title: "Area Bill Averages", icon: "chart.bar.fill")

            VStack(spacing: 12) {
                AverageRow(
                    category: "Electric",
                    areaAverage: 142,
                    yourBill: 128,
                    icon: "bolt.fill",
                    color: .yellow
                )

                AverageRow(
                    category: "Gas",
                    areaAverage: 89,
                    yourBill: 95,
                    icon: "flame.fill",
                    color: .orange
                )

                AverageRow(
                    category: "Water",
                    areaAverage: 65,
                    yourBill: 58,
                    icon: "drop.fill",
                    color: .blue
                )

                AverageRow(
                    category: "Internet",
                    areaAverage: 78,
                    yourBill: 85,
                    icon: "wifi",
                    color: .green
                )
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Deals Section

    private var dealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            InsightsSectionHeader(title: "Local Deals & Savings", icon: "tag.fill")

            VStack(spacing: 0) {
                ForEach(localDeals, id: \.title) { deal in
                    DealRow(deal: deal)

                    if deal.title != localDeals.last?.title {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var localDeals: [LocalDeal] {
        [
            LocalDeal(
                title: "PSE&G Rebate Program",
                description: "Up to $500 off energy-efficient appliances",
                savings: "Save up to $500",
                expiresIn: "Ends Dec 31"
            ),
            LocalDeal(
                title: "Community Solar",
                description: "Join a local solar program - no installation",
                savings: "Save 10-15%",
                expiresIn: "Limited spots"
            ),
            LocalDeal(
                title: "Budget Billing",
                description: "Spread costs evenly throughout the year",
                savings: "Predictable bills",
                expiresIn: "Always available"
            )
        ]
    }
}

// MARK: - Insights Section Header

private struct InsightsSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.billixDarkTeal)

            Text(title)
                .font(.headline)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Provider Row

private struct LocalProvider {
    let name: String
    let type: String
    let icon: String
    let color: Color
}

private struct ProviderRow: View {
    let provider: LocalProvider

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(provider.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: provider.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(provider.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(provider.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(provider.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

// MARK: - Average Row

private struct AverageRow: View {
    let category: String
    let areaAverage: Int
    let yourBill: Int
    let icon: String
    let color: Color

    private var difference: Int {
        areaAverage - yourBill
    }

    private var isBelow: Bool {
        yourBill < areaAverage
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(category)
                .font(.subheadline)
                .frame(width: 70, alignment: .leading)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Area: $\(areaAverage)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("You: $\(yourBill)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Comparison badge
            HStack(spacing: 4) {
                Image(systemName: isBelow ? "arrow.down" : "arrow.up")
                    .font(.caption2)

                Text("$\(abs(difference))")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isBelow ? Color.billixMoneyGreen : Color.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (isBelow ? Color.billixMoneyGreen : Color.red).opacity(0.1)
            )
            .clipShape(Capsule())
        }
    }
}

// MARK: - Deal Row

private struct LocalDeal {
    let title: String
    let description: String
    let savings: String
    let expiresIn: String
}

private struct DealRow: View {
    let deal: LocalDeal

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.billixMoneyGreen.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "tag.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.billixMoneyGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(deal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(deal.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(deal.savings)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.billixMoneyGreen)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text(deal.expiresIn)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    AreaInsightsSheet(city: "Plainfield", state: "NJ", zipCode: "07060")
}
