//
//  CustomDonationRequestSheet.swift
//  Billix
//
//  Modal for submitting custom charity donation requests
//  Users specify organization, amount, and donor info
//

import SwiftUI

struct CustomDonationRequestSheet: View {
    let userPoints: Int
    let userName: String
    let userEmail: String
    let onSubmit: (String, String, DonationAmount, Bool, String?, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var organizationName: String = ""
    @State private var websiteOrLocation: String = ""
    @State private var selectedAmount: DonationAmount = .ten
    @State private var donateInMyName: Bool = true
    @FocusState private var focusedField: Field?

    enum Field {
        case organization, website
    }

    private var canSubmit: Bool {
        !organizationName.isEmpty && !websiteOrLocation.isEmpty && canAfford
    }

    private var canAfford: Bool {
        userPoints >= selectedAmount.pointsCost
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 28) {
                    // Header Section
                    VStack(spacing: 12) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "#0D9488"),
                                            Color(hex: "#059669")
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Image(systemName: "heart.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        Text("Make an Impact")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.billixDarkGreen)

                        Text("Choose your cause")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                    }

                    // SECTION A: The Charity Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("WHICH ORGANIZATION?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.billixMediumGreen)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        // Organization Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name of Charity")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.billixDarkGreen)

                            TextField("e.g. American Red Cross", text: $organizationName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.billixDarkGreen)
                                .autocapitalization(.words)
                                .focused($focusedField, equals: .organization)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            focusedField == .organization ? Color(hex: "#0D9488") : Color.billixBorderGreen,
                                            lineWidth: focusedField == .organization ? 2 : 1
                                        )
                                )
                        }

                        // Website or Location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Website or Location")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.billixDarkGreen)

                            TextField("redcross.org or Washington, DC", text: $websiteOrLocation)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.billixDarkGreen)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .website)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            focusedField == .website ? Color(hex: "#0D9488") : Color.billixBorderGreen,
                                            lineWidth: focusedField == .website ? 2 : 1
                                        )
                                )
                        }

                        // Helper text
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#0D9488"))

                            Text("We can only donate to registered non-profits")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.billixMediumGreen)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#0D9488").opacity(0.08))
                        )
                    }

                    // SECTION B: The Donation Amount
                    VStack(alignment: .leading, spacing: 16) {
                        Text("HOW MUCH?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.billixMediumGreen)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        // Amount chips (3 options)
                        HStack(spacing: 12) {
                            ForEach(DonationAmount.allCases, id: \.self) { amount in
                                DonationAmountChip(
                                    amount: amount,
                                    isSelected: selectedAmount == amount,
                                    canAfford: userPoints >= amount.pointsCost,
                                    onSelect: {
                                        selectedAmount = amount
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                                )
                            }
                        }

                        // Affordability warning
                        if !canAfford {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)

                                (Text("Need ")
                                    .font(.system(size: 13, weight: .medium))
                                + Text("\(selectedAmount.pointsCost - userPoints)")
                                    .font(.system(size: 13, weight: .bold))
                                + Text(" more points")
                                    .font(.system(size: 13, weight: .medium))
                                )
                                .foregroundColor(.billixMediumGreen)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    }

                    // SECTION C: The "On Behalf Of" Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DONOR INFORMATION")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.billixMediumGreen)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        // Toggle
                        Toggle(isOn: $donateInMyName) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Donate in my name")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.billixDarkGreen)

                                if donateInMyName {
                                    Text("We will use \(userName) and \(userEmail) for the receipt")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.billixMediumGreen)
                                } else {
                                    Text("We will make an anonymous donation")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.billixMediumGreen)
                                }
                            }
                        }
                        .tint(Color(hex: "#0D9488"))
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                    }

                    // FOOTER: Disclaimer (Info/Neutral - not success)
                    VStack(spacing: 16) {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#3B82F6")) // Blue for info

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Must be a registered 501(c)(3) organization")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.billixDarkGreen)

                                Text("We verify all charities before payment")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.billixMediumGreen)
                            }

                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#3B82F6").opacity(0.08)) // Blue background
                        )
                    }

                    Spacer(minLength: 20)

                    // Submit Button
                    Button {
                        let donorName = donateInMyName ? userName : nil
                        let donorEmail = donateInMyName ? userEmail : nil
                        onSubmit(organizationName, websiteOrLocation, selectedAmount, donateInMyName, donorName, donorEmail)
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))

                            Text(canAfford ? "Submit Donation Request" : "Not Enough Points")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: canSubmit ?
                                    [Color(hex: "#0D9488"), Color(hex: "#059669")] :
                                    [.gray.opacity(0.3), .gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }
                    .disabled(!canSubmit)
                    .buttonStyle(ScaleButtonStyle(scale: 0.97))
                }
                .padding(24)
            }
            .background(Color.billixLightGreen)

            // X Close Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white)
                    )
            }
            .padding(16)
        }
    }
}

// MARK: - Donation Amount Chip

struct DonationAmountChip: View {
    let amount: DonationAmount
    let isSelected: Bool
    let canAfford: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Dollar amount
                Text(amount.displayText)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(chipTextColor)

                // Points cost
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))

                    Text(amount.pointsText)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(chipSecondaryColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(chipBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(chipBorderColor, lineWidth: isSelected ? 3 : 1)
            )
            .opacity(canAfford ? 1.0 : 0.5)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var chipBackgroundColor: Color {
        if isSelected {
            return Color(hex: "#0D9488").opacity(0.15)
        } else {
            return Color.white
        }
    }

    private var chipBorderColor: Color {
        if isSelected {
            return Color(hex: "#0D9488")
        } else {
            return Color.billixBorderGreen
        }
    }

    private var chipTextColor: Color {
        if isSelected {
            return Color(hex: "#0D9488")
        } else {
            return .billixDarkGreen
        }
    }

    private var chipSecondaryColor: Color {
        if isSelected {
            return Color(hex: "#0D9488").opacity(0.8)
        } else {
            return .billixMediumGreen
        }
    }
}

// MARK: - Preview

#Preview {
    CustomDonationRequestSheet(
        userPoints: 50000,
        userName: "John Doe",
        userEmail: "john@example.com",
        onSubmit: { org, location, amount, inName, donorName, donorEmail in
            print("Submitted: \(org), \(location), \(amount.displayText), In Name: \(inName)")
        }
    )
}
