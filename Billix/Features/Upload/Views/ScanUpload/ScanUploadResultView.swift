//
//  ScanUploadResultView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct ScanUploadResultView: View {
    let analysis: BillAnalysis
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Icon
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                    )
                    .padding(.top, 20)

                Text("Bill Analyzed!")
                    .font(.title2)
                    .fontWeight(.bold)

                // Bill Summary
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Provider")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(analysis.provider)
                                .font(.headline)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Amount")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(String(format: "$%.2f", analysis.amount))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }

                    Divider()

                    // Key Facts
                    if let keyFacts = analysis.keyFacts, !keyFacts.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(keyFacts, id: \.label) { fact in
                                HStack {
                                    Image(systemName: fact.icon ?? "info.circle")
                                        .foregroundColor(.billixMoneyGreen)

                                    Text(fact.label)
                                        .font(.subheadline)

                                    Spacer()

                                    Text(fact.value)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )

                // Insights
                if let insights = analysis.insights, !insights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Insights")
                            .font(.headline)

                        ForEach(insights, id: \.title) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                }

                // Done Button
                Button(action: onComplete) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.billixMoneyGreen)
                        )
                }
            }
            .padding()
        }
    }
}

struct InsightCard: View {
    let insight: BillAnalysis.Insight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insightIcon)
                .foregroundColor(insightColor)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)

                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(insightColor.opacity(0.1))
        )
    }

    private var insightIcon: String {
        switch insight.type {
        case .warning:
            return "exclamationmark.triangle.fill"
        case .savings:
            return "star.fill"
        case .info:
            return "info.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        }
    }

    private var insightColor: Color {
        switch insight.type {
        case .warning:
            return .orange
        case .savings:
            return .green
        case .info:
            return .blue
        case .success:
            return .green
        }
    }
}

struct ScanUploadErrorView: View {
    let error: UploadError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                )

            Text("Upload Failed")
                .font(.title2)
                .fontWeight(.bold)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                    )
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
