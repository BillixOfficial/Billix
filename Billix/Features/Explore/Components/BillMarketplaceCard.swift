import SwiftUI

/// Individual marketplace bill card with pricing statistics and provider info
struct BillMarketplaceCard: View {
    let data: MarketplaceData
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Provider icon and name
            HStack(spacing: 10) {
                // Provider icon
                Text(data.provider?.icon ?? "📄")
                    .font(.system(size: 32))
                    .frame(width: 50, height: 50)
                    .background(Color.billixGoldenAmber.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(data.provider?.name ?? "Unknown")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.billixNavyBlue)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        // Category badge
                        Text(data.provider?.category ?? "")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.billixMoneyGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.billixMoneyGreen.opacity(0.15))
                            .clipShape(Capsule())

                        // New badge
                        if data.isNew {
                            Text("NEW")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.billixGold)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()
            }

            Divider()
                .background(Color.billixDarkTeal.opacity(0.2))

            // Pricing Statistics
            VStack(spacing: 10) {
                // Average price (large)
                HStack {
                    Text("Avg:")
                        .font(.subheadline)
                        .foregroundColor(.billixDarkTeal)

                    Spacer()

                    Text(data.formattedAverage)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)
                }

                // Price range
                HStack {
                    Text("Range:")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal.opacity(0.8))

                    Spacer()

                    Text(data.priceRange)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.billixDarkGray)
                }

                // Percentile bar visualization
                PercentileBar(
                    min: data.minAmount,
                    p25: data.percentile25,
                    median: data.medianAmount,
                    p75: data.percentile75,
                    max: data.maxAmount
                )
            }

            Divider()
                .background(Color.billixDarkTeal.opacity(0.2))

            // Bottom: Sample size and usage
            HStack {
                // Sample size with icon
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.fill")
                        .font(.caption)
                        .foregroundColor(.billixMoneyGreen)

                    Text("\(data.sampleSize) bills")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                }

                Spacer()

                // Usage metrics if available
                if let avgUsage = data.avgUsage {
                    Text(formatUsage(avgUsage, category: data.provider?.category))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.billixNavyBlue)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: Color.billixNavyBlue.opacity(isPressed ? 0.15 : 0.08),
                    radius: isPressed ? 4 : 8,
                    x: 0,
                    y: isPressed ? 2 : 4
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }

    // MARK: - Helper Methods

    private func formatUsage(_ usage: Double, category: String?) -> String {
        guard let category = category?.lowercased() else {
            return "\(Int(usage))"
        }

        switch category {
        case "electric", "electricity":
            return "\(Int(usage)) kWh"
        case "internet", "broadband":
            return "\(Int(usage)) Mbps"
        case "water":
            return "\(Int(usage)) gal"
        case "gas", "natural gas":
            return "\(Int(usage)) therms"
        default:
            return "\(Int(usage))"
        }
    }
}

// MARK: - Percentile Bar

struct PercentileBar: View {
    let min: Double
    let p25: Double
    let median: Double
    let p75: Double
    let max: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Bar visualization
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.billixDarkTeal.opacity(0.1))
                        .frame(height: 8)

                    // Range from p25 to p75 (interquartile range)
                    let range = max - min
                    let p25Position = range > 0 ? (p25 - min) / range : 0
                    let p75Position = range > 0 ? (p75 - min) / range : 1
                    let iqrWidth = p75Position - p25Position

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.billixMoneyGreen.opacity(0.6), Color.billixMoneyGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * iqrWidth,
                            height: 8
                        )
                        .offset(x: geometry.size.width * p25Position)

                    // Median marker
                    let medianPosition = range > 0 ? (median - min) / range : 0.5
                    Circle()
                        .fill(Color.billixGold)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: geometry.size.width * medianPosition - 6)
                }
            }
            .frame(height: 12)

            // Labels
            HStack {
                Text("Low")
                    .font(.caption2)
                    .foregroundColor(.billixDarkTeal.opacity(0.6))

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.billixGold)
                        .frame(width: 6, height: 6)

                    Text("Median: \(formatPrice(median))")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.billixNavyBlue)
                }

                Spacer()

                Text("High")
                    .font(.caption2)
                    .foregroundColor(.billixDarkTeal.opacity(0.6))
            }
        }
    }

    private func formatPrice(_ price: Double) -> String {
        "$\(Int(price))"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        BillMarketplaceCard(
            data: MarketplaceData(
                id: "1",
                providerId: "pge",
                zipPrefix: "941",
                monthYear: "2025-11",
                avgAmount: 120.50,
                medianAmount: 115.00,
                minAmount: 65.00,
                maxAmount: 210.00,
                percentile25: 95.00,
                percentile75: 145.00,
                sampleSize: 127,
                avgUsage: 450,
                medianUsage: 425,
                subcategory: "Residential",
                provider: Provider(
                    id: "pge",
                    name: "PG&E",
                    category: "Electric"
                )
            )
        )

        BillMarketplaceCard(
            data: MarketplaceData(
                id: "2",
                providerId: "comcast",
                zipPrefix: "941",
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
    }
    .padding()
    .background(Color.billixCreamBeige.opacity(0.3))
}
