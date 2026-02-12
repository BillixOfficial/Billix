//
//  BillMarketplaceCard.swift
//  Billix
//
//  Redesigned as StockX-style trading card with blur interaction
//

import SwiftUI

/// Trading card style bill marketplace card with privacy-first blur interaction
struct BillMarketplaceCard: View {
    let data: MarketplaceData
    @State private var isPressed = false

    // MARK: - Computed Properties

    private var usageLevel: UsageLevel {
        guard let usage = data.avgUsage else { return .medium }

        // Determine usage level based on category
        switch data.provider?.category.lowercased() {
        case "electric", "electricity":
            if usage < 400 { return .low }
            else if usage < 700 { return .medium }
            else { return .high }
        case "water":
            if usage < 3000 { return .low }
            else if usage < 6000 { return .medium }
            else { return .high }
        case "gas", "natural gas":
            if usage < 30 { return .low }
            else if usage < 60 { return .medium }
            else { return .high }
        case "internet", "broadband":
            if usage < 300 { return .low }
            else if usage < 600 { return .medium }
            else { return .high }
        default:
            return .medium
        }
    }

    private var verdict: String {
        let avgVsMedian = (data.avgAmount - data.medianAmount) / data.medianAmount * 100

        if avgVsMedian < -10 {
            return "\(Int(abs(avgVsMedian)))% lower than Billix average"
        } else if avgVsMedian > 10 {
            return "\(Int(avgVsMedian))% higher than Billix average"
        } else {
            return "Right at Billix average"
        }
    }

    private var verdictColor: Color {
        let avgVsMedian = (data.avgAmount - data.medianAmount) / data.medianAmount * 100

        if avgVsMedian < -10 {
            return .billixMoneyGreen
        } else if avgVsMedian > 10 {
            return .billixStreakOrange
        } else {
            return .billixGoldenAmber
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Provider logo + Cluster badge
            header

            // Fuzzy Range Bar with blur interaction
            fuzzyRangeSection

            // Usage Context Meter
            usageSection

            // Flags row
            flagsSection

            // Verdict
            verdictSection
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(
                    color: Color.black.opacity(isPressed ? 0.12 : 0.06),
                    radius: isPressed ? 6 : 12,
                    x: 0,
                    y: isPressed ? 3 : 6
                )
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            // Provider icon/logo
            Text(data.provider?.icon ?? "📄")
                .font(.system(size: 36))
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.billixDarkTeal.opacity(0.08))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(data.provider?.name ?? "Unknown")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(data.provider?.category ?? "Utility")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Cluster badge
            ClusterBadge(count: data.sampleSize, variant: .compact)
        }
    }

    // MARK: - Fuzzy Range Section

    private var fuzzyRangeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.billixDarkTeal)

                Text("Price Range")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.billixDarkTeal)
            }

            FuzzyRangeBar(
                minPrice: data.minAmount,
                maxPrice: data.maxAmount,
                highlightMin: data.percentile25,
                highlightMax: data.percentile75,
                totalRange: (data.minAmount * 0.8)...(data.maxAmount * 1.2)
            )
        }
    }

    // MARK: - Usage Section

    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gauge.medium")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Text("Usage Level")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            UsageContextMeter(level: usageLevel)
        }
    }

    // MARK: - Flags Section

    private var flagsSection: some View {
        HStack(spacing: 8) {
            // Mock flags based on data
            if data.sampleSize > 50 {
                FlagChip(icon: "checkmark.circle.fill", text: "Verified", color: .billixMoneyGreen)
            }

            if data.avgAmount > data.medianAmount * 1.15 {
                FlagChip(icon: "exclamationmark.triangle.fill", text: "Above Avg", color: .billixStreakOrange)
            }

            if data.provider?.category.lowercased().contains("electric") == true {
                FlagChip(icon: "leaf.fill", text: "Green Plan", color: .billixMoneyGreen)
            }
        }
    }

    // MARK: - Verdict Section

    private var verdictSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(verdictColor)

            Text(verdict)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(verdictColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(verdictColor.opacity(0.12))
        )
    }
}

// MARK: - Flag Chip

struct FlagChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))

            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }
}

// MARK: - Preview

#Preview("Bill Trading Cards") {
    ScrollView {
        LazyVStack(spacing: 20) {
            // Electric bill
            BillMarketplaceCard(
                data: MarketplaceData(
                    id: "1",
                    providerId: "dte",
                    zipPrefix: "482",
                    monthYear: "2025-11",
                    avgAmount: 145.00,
                    medianAmount: 160.00,
                    minAmount: 100.00,
                    maxAmount: 220.00,
                    percentile25: 130.00,
                    percentile75: 180.00,
                    sampleSize: 67,
                    avgUsage: 550,
                    medianUsage: 525,
                    subcategory: "Residential",
                    provider: Provider(
                        id: "dte",
                        name: "DTE Energy",
                        category: "Electric"
                    )
                )
            )

            // Internet bill
            BillMarketplaceCard(
                data: MarketplaceData(
                    id: "2",
                    providerId: "comcast",
                    zipPrefix: "482",
                    monthYear: "2025-11",
                    avgAmount: 89.99,
                    medianAmount: 85.00,
                    minAmount: 49.99,
                    maxAmount: 150.00,
                    percentile25: 70.00,
                    percentile75: 110.00,
                    sampleSize: 89,
                    avgUsage: 500,
                    medianUsage: 450,
                    subcategory: nil,
                    provider: Provider(
                        id: "comcast",
                        name: "Comcast Xfinity",
                        category: "Internet"
                    )
                )
            )

            // Water bill
            BillMarketplaceCard(
                data: MarketplaceData(
                    id: "3",
                    providerId: "water",
                    zipPrefix: "482",
                    monthYear: "2025-11",
                    avgAmount: 65.00,
                    medianAmount: 62.00,
                    minAmount: 40.00,
                    maxAmount: 95.00,
                    percentile25: 55.00,
                    percentile75: 75.00,
                    sampleSize: 124,
                    avgUsage: 4500,
                    medianUsage: 4200,
                    subcategory: "Residential",
                    provider: Provider(
                        id: "water",
                        name: "Detroit Water",
                        category: "Water"
                    )
                )
            )
        }
        .padding()
    }
    .background(Color.billixCreamBeige)
}

#Preview("Single Card Detail") {
    BillMarketplaceCard(
        data: MarketplaceData(
            id: "1",
            providerId: "dte",
            zipPrefix: "482",
            monthYear: "2025-11",
            avgAmount: 145.00,
            medianAmount: 160.00,
            minAmount: 100.00,
            maxAmount: 220.00,
            percentile25: 140.00,
            percentile75: 165.00,
            sampleSize: 67,
            avgUsage: 550,
            medianUsage: 525,
            subcategory: "Residential",
            provider: Provider(
                id: "dte",
                name: "DTE Energy",
                category: "Electric"
            )
        )
    )
    .padding()
    .background(Color.billixCreamBeige)
}
