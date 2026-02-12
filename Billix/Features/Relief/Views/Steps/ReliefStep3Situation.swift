//
//  ReliefStep3Situation.swift
//  Billix
//
//  Step 3: Household Situation
//

import SwiftUI

struct ReliefStep3Situation: View {
    @ObservedObject var viewModel: ReliefFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Help us understand your situation")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("This information helps us match you with appropriate assistance programs.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            // Form Fields
            VStack(spacing: 24) {
                // Income Level
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Annual Household Income")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                        Text("*")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    }

                    VStack(spacing: 8) {
                        ForEach(ReliefIncomeLevel.allCases) { level in
                            IncomeLevelOption(
                                level: level,
                                isSelected: viewModel.incomeLevel == level
                            ) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.incomeLevel = level
                            }
                        }
                    }
                }

                // Household Size
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Household Size")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                        Text("*")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    }

                    HStack(spacing: 16) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if viewModel.householdSize > 1 {
                                viewModel.householdSize -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(viewModel.householdSize > 1 ? .red : Color.gray.opacity(0.3))
                        }
                        .disabled(viewModel.householdSize <= 1)

                        VStack(spacing: 4) {
                            Text("\(viewModel.householdSize)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#2D3B35"))

                            Text(viewModel.householdSize == 1 ? "person" : "people")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#8B9A94"))
                        }
                        .frame(width: 80)

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if viewModel.householdSize < 20 {
                                viewModel.householdSize += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(viewModel.householdSize < 20 ? .red : Color.gray.opacity(0.3))
                        }
                        .disabled(viewModel.householdSize >= 20)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }

                // Employment Status
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Employment Status")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                        Text("*")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(ReliefEmploymentStatus.allCases) { status in
                            EmploymentStatusOption(
                                status: status,
                                isSelected: viewModel.employmentStatus == status
                            ) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.employmentStatus = status
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Income Level Option

struct IncomeLevelOption: View {
    let level: ReliefIncomeLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.red : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                    }
                }

                Text(level.displayName)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? Color.red.opacity(0.06) : Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.red.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Employment Status Option

struct EmploymentStatusOption: View {
    let status: ReliefEmploymentStatus
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(status.displayName)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "#2D3B35"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.red : Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.red : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReliefStep3Situation_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
        ReliefStep3Situation(viewModel: ReliefFlowViewModel())
        .padding()
        }
        .background(Color(hex: "#F7F9F8"))
    }
}
