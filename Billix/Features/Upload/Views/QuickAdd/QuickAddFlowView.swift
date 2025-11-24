//
//  QuickAddFlowView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

/// Container for the 4-step Quick Add flow
struct QuickAddFlowView: View {
    @StateObject private var viewModel = QuickAddViewModel()
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Bar
                ProgressView(value: viewModel.progressPercentage)
                    .tint(.billixMoneyGreen)
                    .padding()

                // Current Step
                ZStack {
                    switch viewModel.currentStep {
                    case .billType:
                        QuickAddStep1BillType(viewModel: viewModel)
                    case .provider:
                        QuickAddStep2Provider(viewModel: viewModel)
                    case .amount:
                        QuickAddStep3Amount(viewModel: viewModel)
                    case .result:
                        QuickAddStep4Result(viewModel: viewModel, onComplete: {
                            onComplete()
                            dismiss()
                        })
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.currentStep != .billType {
                        Button("Back") {
                            viewModel.previousStep()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.onAppear()
            }
        }
    }
}
