//
//  ReliefStep2BillInfo.swift
//  Billix
//
//  Step 2: Bill Information
//

import SwiftUI

struct ReliefStep2BillInfo: View {
    @ObservedObject var viewModel: ReliefFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Tell us about the bill you need help with")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("This helps us understand your situation and find the right assistance programs.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            // Form Fields
            VStack(spacing: 20) {
                // Bill Type Picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Bill Type")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                        Text("*")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ReliefBillType.allCases) { type in
                                BillTypeChip(
                                    type: type,
                                    isSelected: viewModel.billType == type
                                ) {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    viewModel.billType = type
                                }
                            }
                        }
                    }
                }

                // Provider Name
                ReliefFormField(
                    title: "Provider Name",
                    placeholder: "e.g., Verizon, ComEd, etc.",
                    text: $viewModel.billProvider,
                    icon: "building.2.fill",
                    isRequired: false
                )

                // Amount Owed
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Amount Owed")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                        Text("*")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    }

                    HStack(spacing: 12) {
                        Text("$")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        TextField("0.00", text: $viewModel.amountOwed)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                            .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Brief Description")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    TextEditor(text: $viewModel.description)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#2D3B35"))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(
                            Group {
                                if viewModel.description.isEmpty {
                                    Text("Tell us more about your situation (optional)")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "#8B9A94").opacity(0.6))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
            }
        }
    }
}

// MARK: - Bill Type Chip

struct BillTypeChip: View {
    let type: ReliefBillType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? type.color.opacity(0.15) : Color.gray.opacity(0.08))
                        .frame(width: 56, height: 56)

                    Image(systemName: type.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? type.color : Color(hex: "#8B9A94"))
                }

                Text(type.displayName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? type.color : Color(hex: "#8B9A94"))
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReliefStep2BillInfo_Previews: PreviewProvider {
    static var previews: some View {
        ReliefStep2BillInfo(viewModel: ReliefFlowViewModel())
        .padding()
        .background(Color(hex: "#F7F9F8"))
    }
}
