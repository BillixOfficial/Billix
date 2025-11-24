//
//  QuickAddStep3Amount.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct QuickAddStep3Amount: View {
    @ObservedObject var viewModel: QuickAddViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("How much do you pay?")
                    .font(.title2)
                    .fontWeight(.bold)

                // Amount Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bill Amount")
                        .font(.headline)

                    HStack {
                        Text("$")
                            .font(.title)
                            .foregroundColor(.secondary)

                        TextField("0.00", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                            .font(.title)
                            .textFieldStyle(.plain)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }

                // Frequency Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Billing Frequency")
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach(BillingFrequency.allCases, id: \.self) { frequency in
                            FrequencyButton(
                                frequency: frequency,
                                isSelected: viewModel.frequency == frequency
                            ) {
                                viewModel.frequency = frequency
                            }
                        }
                    }
                }

                Spacer()

                // Continue Button
                Button(action: {
                    Task {
                        await viewModel.submitQuickAdd()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    } else {
                        Text("See Results")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(viewModel.canProceed ? Color.billixMoneyGreen : Color.gray)
                            )
                    }
                }
                .disabled(!viewModel.canProceed || viewModel.isLoading)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
    }
}

struct FrequencyButton: View {
    let frequency: BillingFrequency
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(frequency.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.billixMoneyGreen : Color(.systemGray6))
                )
        }
    }
}
