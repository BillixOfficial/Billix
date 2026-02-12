//
//  ReliefStep5Review.swift
//  Billix
//
//  Step 5: Review & Submit
//

import SwiftUI

struct ReliefStep5Review: View {
    @ObservedObject var viewModel: ReliefFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Review your request")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("Please review the information below before submitting. You can go back to any section to make changes.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            // Review Sections
            VStack(spacing: 16) {
                // Personal Info Section
                ReviewSection(
                    title: "Personal Information",
                    icon: "person.fill",
                    step: .personalInfo,
                    onEdit: { viewModel.goToStep(.personalInfo) }
                ) {
                    ReliefReviewRow(label: "Name", value: viewModel.fullName)
                    ReliefReviewRow(label: "Email", value: viewModel.email)
                    if !viewModel.phone.isEmpty {
                        ReliefReviewRow(label: "Phone", value: viewModel.phone)
                    }
                }

                // Bill Info Section
                ReviewSection(
                    title: "Bill Details",
                    icon: "doc.text.fill",
                    step: .billInfo,
                    onEdit: { viewModel.goToStep(.billInfo) }
                ) {
                    ReliefReviewRow(label: "Type", value: viewModel.billType.displayName, icon: viewModel.billType.icon, iconColor: viewModel.billType.color)
                    if !viewModel.billProvider.isEmpty {
                        ReliefReviewRow(label: "Provider", value: viewModel.billProvider)
                    }
                    ReliefReviewRow(label: "Amount", value: viewModel.formattedAmount ?? "$\(viewModel.amountOwed)", highlight: true)
                    if !viewModel.description.isEmpty {
                        ReliefReviewRow(label: "Description", value: viewModel.description)
                    }
                }

                // Situation Section
                ReviewSection(
                    title: "Your Situation",
                    icon: "house.fill",
                    step: .situation,
                    onEdit: { viewModel.goToStep(.situation) }
                ) {
                    ReliefReviewRow(label: "Income", value: viewModel.incomeLevel.displayName)
                    ReliefReviewRow(label: "Household", value: "\(viewModel.householdSize) \(viewModel.householdSize == 1 ? "person" : "people")")
                    ReliefReviewRow(label: "Employment", value: viewModel.employmentStatus.displayName)
                }

                // Urgency Section
                ReviewSection(
                    title: "Urgency",
                    icon: "exclamationmark.triangle.fill",
                    step: .urgency,
                    onEdit: { viewModel.goToStep(.urgency) }
                ) {
                    ReliefReviewRow(
                        label: "Level",
                        value: viewModel.urgencyLevel.displayName,
                        icon: viewModel.urgencyLevel.icon,
                        iconColor: viewModel.urgencyLevel.color
                    )
                    if viewModel.hasShutoffDate {
                        let formatter = DateFormatter()
                        let _ = formatter.dateStyle = .medium
                        ReliefReviewRow(label: "Shutoff Date", value: formatter.string(from: viewModel.utilityShutoffDate), highlight: true)
                    }
                }
            }

            // Agreement
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#5B8A6B"))

                    Text("By submitting this request, you confirm that the information provided is accurate. Your data will be handled securely and used only to process your relief request.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#5D6D66"))
                }
            }
            .padding(16)
            .background(Color(hex: "#5B8A6B").opacity(0.08))
            .cornerRadius(12)
        }
    }
}

// MARK: - Review Section

struct ReviewSection<Content: View>: View {
    let title: String
    let icon: String
    let step: ReliefFlowViewModel.Step
    let onEdit: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.red)

                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3B35"))
                }

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onEdit()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                        Text("Edit")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.red)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                content
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Relief Review Row

struct ReliefReviewRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var iconColor: Color = .gray
    var highlight: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#8B9A94"))
                .frame(width: 80, alignment: .leading)

            if let icon = icon {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(iconColor)
                    Text(value)
                        .font(.system(size: 13, weight: highlight ? .bold : .medium))
                        .foregroundColor(highlight ? .red : Color(hex: "#2D3B35"))
                }
            } else {
                Text(value)
                    .font(.system(size: 13, weight: highlight ? .bold : .medium))
                    .foregroundColor(highlight ? .red : Color(hex: "#2D3B35"))
            }

            Spacer()
        }
    }
}

struct ReliefStep5Review_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
        ReliefStep5Review(viewModel: {
        let vm = ReliefFlowViewModel()
        vm.fullName = "John Doe"
        vm.email = "john@example.com"
        vm.phone = "(555) 123-4567"
        vm.billType = .electric
        vm.billProvider = "DTE Energy"
        vm.amountOwed = "250.00"
        vm.description = "Behind on payments due to job loss"
        vm.incomeLevel = .from25kTo50k
        vm.householdSize = 3
        vm.employmentStatus = .unemployed
        vm.urgencyLevel = .high
        vm.hasShutoffDate = true
        return vm
        }())
        .padding()
        }
        .background(Color(hex: "#F7F9F8"))
    }
}
