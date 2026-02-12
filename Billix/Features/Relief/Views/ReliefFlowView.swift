//
//  ReliefFlowView.swift
//  Billix
//
//  Multi-step form container for relief requests
//

import SwiftUI

struct ReliefFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReliefFlowViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F7F9F8").ignoresSafeArea()

                if viewModel.submittedRequest != nil {
                    ReliefSuccessView(
                        request: viewModel.submittedRequest!,
                        onDone: { dismiss() },
                        onViewHistory: {
                            // TODO: Navigate to history
                            dismiss()
                        }
                    )
                } else {
                    VStack(spacing: 0) {
                        // Progress Header
                        progressHeader

                        // Step Content
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 24) {
                                stepContent
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)

                                Spacer().frame(height: 100)
                            }
                        }

                        // Bottom Navigation
                        bottomNavigation
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Get Help")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .task {
                await viewModel.prefillUserInfo()
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Step indicators
            HStack(spacing: 8) {
                ForEach(ReliefFlowViewModel.Step.allCases, id: \.rawValue) { step in
                    stepIndicator(for: step)
                }
            }
            .padding(.horizontal, 20)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.red)
                        .frame(width: geo.size.width * viewModel.progressPercentage, height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.progressPercentage)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)

            // Step title
            HStack {
                Image(systemName: viewModel.currentStep.icon)
                    .font(.system(size: 14))
                    .foregroundColor(.red)

                Text(viewModel.currentStep.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Spacer()

                Text("Step \(viewModel.currentStep.rawValue) of 5")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color.white)
    }

    private func stepIndicator(for step: ReliefFlowViewModel.Step) -> some View {
        let isCompleted = step.rawValue < viewModel.currentStep.rawValue
        let isCurrent = step == viewModel.currentStep

        return Button {
            viewModel.goToStep(step)
        } label: {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.red : (isCurrent ? Color.red.opacity(0.15) : Color.gray.opacity(0.1)))
                    .frame(width: 28, height: 28)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(step.rawValue)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isCurrent ? .red : Color(hex: "#8B9A94"))
                }
            }
        }
        .disabled(step.rawValue >= viewModel.currentStep.rawValue)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .personalInfo:
            ReliefStep1PersonalInfo(viewModel: viewModel)
        case .billInfo:
            ReliefStep2BillInfo(viewModel: viewModel)
        case .situation:
            ReliefStep3Situation(viewModel: viewModel)
        case .urgency:
            ReliefStep4Urgency(viewModel: viewModel)
        case .review:
            ReliefStep5Review(viewModel: viewModel)
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                // Back button
                if !viewModel.isFirstStep {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.previousStep()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "#2D3B35"))
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }

                // Next/Submit button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if viewModel.isLastStep {
                        Task {
                            await viewModel.submitRequest()
                        }
                    } else {
                        viewModel.nextStep()
                    }
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(viewModel.isLastStep ? "Submit Request" : "Continue")
                                .font(.system(size: 15, weight: .bold))
                            if !viewModel.isLastStep {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(viewModel.canProceed || viewModel.isLastStep ? Color.red : Color.gray.opacity(0.4))
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoading || (!viewModel.canProceed && !viewModel.isLastStep))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }
}

// MARK: - Preview

struct ReliefFlowView_Previews: PreviewProvider {
    static var previews: some View {
        ReliefFlowView()
    }
}
