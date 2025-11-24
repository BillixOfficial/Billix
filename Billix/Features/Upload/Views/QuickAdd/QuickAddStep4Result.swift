//
//  QuickAddStep4Result.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct QuickAddStep4Result: View {
    @ObservedObject var viewModel: QuickAddViewModel
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            if let result = viewModel.result {
                VStack(spacing: 24) {
                    // Status Icon
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: result.statusIcon)
                                .font(.system(size: 48))
                                .foregroundColor(statusColor)
                        )
                        .padding(.top, 20)

                    // Message
                    Text(result.message)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    // Comparison Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Bill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(String(format: "$%.2f", result.amount))
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Area Average")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(String(format: "$%.2f", result.areaAverage))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let savings = result.potentialSavings {
                            Divider()

                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)

                                Text("Potential savings: ")
                                    .font(.subheadline)
                                    + Text(String(format: "$%.2f/month", savings))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.billixMoneyGreen)

                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )

                    // CTA
                    if let ctaMessage = result.ctaMessage {
                        VStack(spacing: 16) {
                            Text(ctaMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Button(action: {
                                // TODO: Navigate to scan/upload
                                onComplete()
                            }) {
                                Text("Scan Your Bill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.blue)
                                    )
                            }
                        }
                    }

                    // Done Button
                    Button(action: onComplete) {
                        Text(result.ctaMessage != nil ? "Maybe Later" : "Done")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                }
                .padding()
            }
        }
    }

    private var statusColor: Color {
        guard let result = viewModel.result else { return .gray }

        switch result.status {
        case .overpaying:
            return .red
        case .underpaying:
            return .green
        case .average:
            return .blue
        }
    }
}
