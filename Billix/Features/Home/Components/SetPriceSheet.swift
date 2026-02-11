//
//  SetPriceSheet.swift
//  Billix
//
//  Bottom sheet for setting a price target with provider info
//

import SwiftUI

struct SetPriceSheet: View {
    let billType: PriceBillType
    let regionalAverage: Double
    let existingTarget: PriceTarget?
    let onSave: (Double, String?, Double?, ContactPreference) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var targetPriceText: String = ""
    @State private var currentProvider: String = ""
    @State private var currentAmountText: String = ""
    @State private var contactPreference: ContactPreference = .email
    @FocusState private var focusedField: FocusField?

    enum FocusField {
        case targetPrice, currentProvider, currentAmount
    }

    init(billType: PriceBillType, regionalAverage: Double, existingTarget: PriceTarget? = nil, onSave: @escaping (Double, String?, Double?, ContactPreference) -> Void) {
        self.billType = billType
        self.regionalAverage = regionalAverage
        self.existingTarget = existingTarget
        self.onSave = onSave

        // Pre-fill from existing target if editing
        if let existing = existingTarget {
            _targetPriceText = State(initialValue: String(Int(existing.targetAmount)))
            _currentProvider = State(initialValue: existing.currentProvider ?? "")
            _currentAmountText = State(initialValue: existing.currentAmount.map { String(Int($0)) } ?? "")
            _contactPreference = State(initialValue: existing.contactPreference)
        }
    }

    private var targetAmount: Double? {
        Double(targetPriceText.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: ""))
    }

    private var currentAmount: Double? {
        guard !currentAmountText.isEmpty else { return nil }
        return Double(currentAmountText.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: ""))
    }

    private var isValidTarget: Bool {
        guard let amount = targetAmount else { return false }
        return amount > 0 && amount < 10000
    }

    private var potentialSavings: Double {
        guard let target = targetAmount else { return 0 }
        if let current = currentAmount {
            return max(0, current - target)
        }
        return max(0, regionalAverage - target)
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return isValidTarget
        case 1: return true // Provider info is optional
        default: return true
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator (2 steps)
                HStack(spacing: 8) {
                    ForEach(0..<2) { step in
                        Capsule()
                            .fill(step <= currentStep ? Color(hex: "#5B8A6B") : Color.gray.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 24) {
                        // Bill type header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(billType.color.opacity(0.15))
                                    .frame(width: 56, height: 56)

                                Image(systemName: billType.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(billType.color)
                            }

                            Text(stepTitle)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "#2D3B35"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 16)

                        // Step content (2 steps only - email is default)
                        switch currentStep {
                        case 0:
                            targetPriceStep
                        case 1:
                            providerInfoStep
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.bottom, 100)
                }

                // Bottom buttons
                VStack(spacing: 12) {
                    Button {
                        haptic()
                        if currentStep < 1 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            // Save and dismiss (default to email notification)
                            if let target = targetAmount {
                                onSave(
                                    target,
                                    currentProvider.isEmpty ? nil : currentProvider,
                                    currentAmount,
                                    .email // Always use email
                                )
                                dismiss()
                            }
                        }
                    } label: {
                        Text(currentStep < 1 ? "Continue" : "Set My Price")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canProceed ? Color(hex: "#5B8A6B") : Color.gray.opacity(0.4))
                            .cornerRadius(14)
                    }
                    .disabled(!canProceed)

                    if currentStep > 0 {
                        Button {
                            haptic()
                            withAnimation {
                                currentStep -= 1
                            }
                        } label: {
                            Text("Back")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "#5B8A6B"))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(Color.white)
            }
            .background(Color(hex: "#F7F9F8"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#5B8A6B"))
                }
            }
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0:
            return "What do you want to pay for \(billType.displayName.lowercased())?"
        case 1:
            return "Who's your current provider?"
        default:
            return ""
        }
    }

    // MARK: - Step 1: Target Price

    private var targetPriceStep: some View {
        VStack(spacing: 20) {
            // Price input
            HStack(alignment: .center, spacing: 4) {
                Text("$")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#2D3B35"))

                TextField("0", text: $targetPriceText)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#2D3B35"))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .targetPrice)
                    .frame(maxWidth: 160)

                Text("/mo")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            // Regional context
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#5B8A6B"))

                Text("Regional average:")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#8B9A94"))

                Text("$\(Int(regionalAverage))/mo")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))
            }

            // Savings preview
            if isValidTarget && potentialSavings > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#4CAF7A"))

                    Text("We can save you $\(Int(potentialSavings))/mo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#4CAF7A"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(hex: "#4CAF7A").opacity(0.12))
                .cornerRadius(10)
            }
        }
        .onAppear {
            focusedField = .targetPrice
        }
    }

    // MARK: - Step 2: Provider Info

    private var providerInfoStep: some View {
        VStack(spacing: 20) {
            // Current provider
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Provider (optional)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))

                TextField("e.g. PSE&G, Verizon, State Farm", text: $currentProvider)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#2D3B35"))
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#E5E9E7"), lineWidth: 1)
                    )
                    .focused($focusedField, equals: .currentProvider)
            }
            .padding(.horizontal, 20)

            // Current amount
            VStack(alignment: .leading, spacing: 8) {
                Text("What do you currently pay? (optional)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))

                HStack {
                    Text("$")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    TextField("0", text: $currentAmountText)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#2D3B35"))
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .currentAmount)

                    Text("/mo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "#E5E9E7"), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)

            // Why we ask
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                Text("This helps us find you better deals and negotiate on your behalf")
                    .font(.system(size: 12))
            }
            .foregroundColor(Color(hex: "#8B9A94"))
            .padding(.horizontal, 20)
        }
        .onAppear {
            focusedField = .currentProvider
        }
    }

}

#Preview {
    SetPriceSheet(
        billType: PriceBillType.electric,
        regionalAverage: 153,
        existingTarget: nil,
        onSave: { _, _, _, _ in }
    )
}
