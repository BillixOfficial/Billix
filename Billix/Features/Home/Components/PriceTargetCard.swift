//
//  PriceTargetCard.swift
//  Billix
//
//  Card displaying an active price target with available options
//

import SwiftUI

struct PriceTargetCard: View {
    let target: PriceTarget
    let regionalAverage: Double
    let options: [PriceOption]
    let onEdit: () -> Void
    let onViewOptions: () -> Void
    let onDelete: () -> Void

    private var savings: Double {
        max(0, regionalAverage - target.targetAmount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(target.billType.color.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: target.billType.icon)
                            .font(.system(size: 18))
                            .foregroundColor(target.billType.color)
                    }

                    Text(target.billType.displayName.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3B35"))
                        .tracking(0.5)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        haptic()
                        onEdit()
                    } label: {
                        Text("Edit")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#5B8A6B"))
                    }

                    Button {
                        haptic()
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
            }

            // Price comparison row
            HStack(spacing: 0) {
                // User's target
                VStack(alignment: .leading, spacing: 4) {
                    Text("You want")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8B9A94"))

                    Text("$\(Int(target.targetAmount))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#2D3B35"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Regional average
                VStack(alignment: .leading, spacing: 4) {
                    Text("Regional Avg")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8B9A94"))

                    Text("$\(Int(regionalAverage))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Savings
                VStack(alignment: .leading, spacing: 4) {
                    Text("Savings")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8B9A94"))

                    Text("$\(Int(savings))/mo")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#4CAF7A"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Status section
            VStack(alignment: .leading, spacing: 10) {
                Text("We're working on it:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#8B9A94"))

                VStack(spacing: 8) {
                    ForEach(options.prefix(3)) { option in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#5B8A6B"))

                            Text(option.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#2D3B35"))

                            Spacer()

                            if let potentialSavings = option.potentialSavings {
                                Text("-$\(Int(potentialSavings))")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "#4CAF7A"))
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(hex: "#F7F9F8"))
                .cornerRadius(10)
            }

            // View Options button
            Button {
                haptic()
                onViewOptions()
            } label: {
                Text("View Options")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#5B8A6B"))
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    PriceTargetCard(
        target: PriceTarget(billType: PriceBillType.electric, targetAmount: 100),
        regionalAverage: 153,
        options: [
            PriceOption(type: .betterRate, title: "2 better rates found in your area", subtitle: "", potentialSavings: 20, action: .viewRates),
            PriceOption(type: .billConnection, title: "3 Bill Connection matches available", subtitle: "", potentialSavings: 15, action: .openBillConnection),
            PriceOption(type: .negotiation, title: "Negotiation scripts ready", subtitle: "", potentialSavings: 12, action: .showNegotiationScript)
        ],
        onEdit: {},
        onViewOptions: {},
        onDelete: {}
    )
    .padding()
    .background(Color(hex: "#F7F9F8"))
}
