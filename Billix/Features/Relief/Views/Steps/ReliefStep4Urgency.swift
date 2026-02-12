//
//  ReliefStep4Urgency.swift
//  Billix
//
//  Step 4: Urgency Level
//

import SwiftUI

struct ReliefStep4Urgency: View {
    @ObservedObject var viewModel: ReliefFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("How urgent is your situation?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("This helps us prioritize requests and connect you with time-sensitive assistance.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            // Form Fields
            VStack(spacing: 24) {
                // Urgency Level
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Urgency Level")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                        Text("*")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    }

                    VStack(spacing: 10) {
                        ForEach(ReliefUrgencyLevel.allCases) { level in
                            UrgencyLevelOption(
                                level: level,
                                isSelected: viewModel.urgencyLevel == level
                            ) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.urgencyLevel = level
                            }
                        }
                    }
                }

                // Shutoff Date Toggle
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $viewModel.hasShutoffDate) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Do you have a utility shutoff date?")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#2D3B35"))

                            Text("If your service is scheduled to be disconnected")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#8B9A94"))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                    // Date Picker (shown when toggle is on)
                    if viewModel.hasShutoffDate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Shutoff Date")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#2D3B35"))

                            DatePicker(
                                "",
                                selection: $viewModel.utilityShutoffDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .accentColor(.red)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Info note for critical situations
                if viewModel.urgencyLevel == .critical || viewModel.hasShutoffDate {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Critical Situation")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red)

                            Text("We'll prioritize your request. You may also want to contact your utility provider directly to discuss payment options.")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#5D6D66"))
                        }
                    }
                    .padding(16)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
}

// MARK: - Urgency Level Option

struct UrgencyLevelOption: View {
    let level: ReliefUrgencyLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? level.color.opacity(0.15) : Color.gray.opacity(0.08))
                        .frame(width: 44, height: 44)

                    Image(systemName: level.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? level.color : Color(hex: "#8B9A94"))
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Text(level.description)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(level.color)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(14)
            .background(isSelected ? level.color.opacity(0.06) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? level.color.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReliefStep4Urgency_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
        ReliefStep4Urgency(viewModel: ReliefFlowViewModel())
        .padding()
        }
        .background(Color(hex: "#F7F9F8"))
    }
}
