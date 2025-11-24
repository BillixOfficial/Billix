//
//  QuickAddStep2Provider.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct QuickAddStep2Provider: View {
    @ObservedObject var viewModel: QuickAddViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Enter your ZIP code and select your provider")
                    .font(.title2)
                    .fontWeight(.bold)

                // ZIP Code Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("ZIP Code")
                        .font(.headline)

                    TextField("Enter 5-digit ZIP", text: $viewModel.zipCode)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.zipCode) { _, newValue in
                            if newValue.count == 5 {
                                Task {
                                    await viewModel.loadProviders()
                                }
                            }
                        }
                }

                if viewModel.isLoading {
                    ProgressView("Loading providers...")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                } else if !viewModel.providers.isEmpty {
                    // Provider List
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Provider")
                            .font(.headline)

                        ForEach(viewModel.providers) { provider in
                            ProviderRow(provider: provider, isSelected: viewModel.selectedProvider?.id == provider.id)
                                .onTapGesture {
                                    viewModel.selectProvider(provider)
                                }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct ProviderRow: View {
    let provider: BillProvider
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(provider.name)
                    .font(.headline)

                Text(provider.serviceArea)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.billixMoneyGreen)
                    .font(.title3)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.billixMoneyGreen.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.billixMoneyGreen : Color.clear, lineWidth: 2)
        )
    }
}
