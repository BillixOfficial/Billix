import SwiftUI

struct SavingsOpportunityCard: View {
    let opportunity: SavingsOpportunity
    let onViewInsight: () -> Void
    let onCompare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: opportunity.category.icon)
                    .foregroundColor(opportunity.category.color)
                    .imageScale(.medium)

                Text(opportunity.billName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(Int(opportunity.savingsPercentage))% savings")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.green))
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(opportunity.currentProvider)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("$\(String(format: "%.0f", opportunity.currentPrice))/mo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                    .imageScale(.small)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(opportunity.recommendedProvider)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("$\(String(format: "%.0f", opportunity.currentPrice - opportunity.potentialSavings))/mo")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("TruePrice™")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("$\(String(format: "%.0f", opportunity.truePriceAverage)) avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * opportunity.truePriceProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }

            HStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.green)
                    .imageScale(.large)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Save $\(String(format: "%.0f", opportunity.potentialSavings))/month")
                        .font(.headline)
                        .foregroundColor(.green)

                    Text("$\(String(format: "%.0f", opportunity.potentialSavings * 12))/year in total savings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: onViewInsight) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("View Insight")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
                }

                Button(action: onCompare) {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("Compare")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 1.5))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}
