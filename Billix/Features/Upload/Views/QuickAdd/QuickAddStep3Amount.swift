//
//  QuickAddStep3Amount.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct QuickAddStep3Amount: View {
    @ObservedObject var viewModel: QuickAddViewModel
    var namespace: Namespace.ID

    @State private var appeared = false
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("How much is your bill?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)

                    if let billType = viewModel.selectedBillType {
                        HStack(spacing: 6) {
                            Image(systemName: billType.icon)
                                .font(.system(size: 12))
                            Text(billType.name)
                                .font(.system(size: 14, weight: .medium))
                            Text("•")
                            if let provider = viewModel.selectedProvider {
                                Text(provider.name)
                                    .font(.system(size: 14))
                            }
                        }
                        .foregroundColor(.billixMediumGreen)
                    }
                }
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                // Amount Input Card
                amountInputSection
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

                // Frequency Section
                frequencySection
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)

                Spacer(minLength: 20)

                // Submit Button
                submitButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: appeared)
            }
            .padding(.top, 8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - Amount Input Section

    private var amountInputSection: some View {
        SolidCard(cornerRadius: 24, padding: 24, shadowRadius: 15) {
            VStack(spacing: 20) {
                // Large currency display
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$")
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundColor(.billixMediumGreen)

                    TextField("0", text: $viewModel.amount)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)
                        .keyboardType(.decimalPad)
                        .focused($isAmountFocused)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isAmountFocused = false
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.billixChartBlue)
                            }
                        }
                }
                .padding(.vertical, 16)

                // Solid color underline
                Rectangle()
                    .fill(Color.billixMoneyGreen)
                    .frame(height: 3)
                    .cornerRadius(1.5)

                // Helper text
                Text("Enter your last bill amount")
                    .font(.system(size: 13))
                    .foregroundColor(.billixMediumGreen)
            }
        }
    }

    // MARK: - Frequency Section

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How often do you pay?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            SegmentedSelector(
                options: BillingFrequency.allCases,
                selection: $viewModel.frequency,
                label: { $0.displayName },
                height: 52
            )
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        VStack(spacing: 0) {
            Button(action: submitForm) {
                HStack(spacing: 12) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Text("See How You Compare")
                            .font(.system(size: 17, weight: .semibold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(viewModel.canProceed ? Color.billixMoneyGreen : Color.gray)
                )
                .shadow(color: viewModel.canProceed ? Color.billixMoneyGreen.opacity(0.35) : Color.clear, radius: 12, y: 6)
            }
            .disabled(!viewModel.canProceed || viewModel.isLoading)
            .buttonStyle(ScaleButtonStyle(scale: 0.98))

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Actions

    private func submitForm() {
        guard viewModel.canProceed else { return }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Hide keyboard
        isAmountFocused = false

        Task {
            await viewModel.submitQuickAdd()
        }
    }
}

// MARK: - Custom Amount Input Field

struct CurrencyInputField: View {
    @Binding var amount: String
    @FocusState.Binding var isFocused: Bool

    @State private var cursorOpacity: Double = 1

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("$")
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundColor(.billixMediumGreen)

            ZStack(alignment: .leading) {
                if amount.isEmpty {
                    Text("0.00")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.billixMediumGreen.opacity(0.3))
                }

                HStack(spacing: 0) {
                    Text(formattedAmount)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)

                    if isFocused {
                        Rectangle()
                            .fill(Color.billixMoneyGreen)
                            .frame(width: 3, height: 48)
                            .opacity(cursorOpacity)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                    cursorOpacity = 0
                                }
                            }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .background(
            TextField("", text: $amount)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .opacity(0)
        )
    }

    private var formattedAmount: String {
        guard !amount.isEmpty else { return "" }
        return amount
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var viewModel = QuickAddViewModel()
        @Namespace private var namespace

        var body: some View {
            ZStack {
                Color.billixLightGreen.ignoresSafeArea()
                QuickAddStep3Amount(viewModel: viewModel, namespace: namespace)
            }
            .onAppear {
                viewModel.onAppear()
                // Simulate having selected bill type and provider
                Task {
                    await viewModel.loadBillTypes()
                    if let first = viewModel.billTypes.first {
                        viewModel.selectBillType(first)
                    }
                }
            }
        }
    }

    return PreviewWrapper()
}
