//
//  DonationSheet.swift
//  Billix
//
//  Bottom sheet modal for collecting donor information
//  Features auto-filled name, email collection, and optional dedication
//

import SwiftUI

struct DonationSheet: View {
    let donation: Donation
    let userPoints: Int
    let userName: String // Auto-filled from user profile
    let userEmail: String // Auto-filled from user profile
    let onConfirm: (String, String, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var donorName: String
    @State private var donorEmail: String
    @State private var dedication: String = ""
    @State private var isValidEmail: Bool = true
    @FocusState private var focusedField: Field?

    enum Field {
        case name, email, dedication
    }

    init(
        donation: Donation,
        userPoints: Int,
        userName: String,
        userEmail: String,
        onConfirm: @escaping (String, String, String?) -> Void
    ) {
        self.donation = donation
        self.userPoints = userPoints
        self.userName = userName
        self.userEmail = userEmail
        self.onConfirm = onConfirm

        // Auto-fill with user data
        _donorName = State(initialValue: userName)
        _donorEmail = State(initialValue: userEmail)
    }

    private var canAfford: Bool {
        userPoints >= donation.pointsCost
    }

    private var accentColor: Color {
        Color(hex: donation.accentColor)
    }

    private var canSubmit: Bool {
        canAfford && !donorName.isEmpty && !donorEmail.isEmpty && isValidEmail
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 12) {
                        // Charity icon
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: donation.logoName)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(accentColor)
                        }

                        Text("Donate to")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.billixMediumGreen)

                        Text(donation.charityName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.billixDarkGreen)
                            .multilineTextAlignment(.center)

                        // Impact highlight
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(accentColor)

                            Text(donation.impactTitle)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(accentColor)

                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(accentColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.1))
                        )
                    }

                    // Form Section - "On Behalf Of"
                    VStack(alignment: .leading, spacing: 20) {
                        Text("DONATION DETAILS")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.billixMediumGreen)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        // Donor Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.billixDarkGreen)

                            TextField("Enter your name", text: $donorName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.billixDarkGreen)
                                .autocapitalization(.words)
                                .focused($focusedField, equals: .name)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            focusedField == .name ? accentColor : Color.billixBorderGreen,
                                            lineWidth: focusedField == .name ? 2 : 1
                                        )
                                )
                        }

                        // Donor Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email for Receipt")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.billixDarkGreen)

                            TextField("your.email@example.com", text: $donorEmail)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.billixDarkGreen)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            emailBorderColor,
                                            lineWidth: focusedField == .email ? 2 : 1
                                        )
                                )
                                .onChange(of: donorEmail) { oldValue, newValue in
                                    validateEmail(newValue)
                                }

                            if !donorEmail.isEmpty && !isValidEmail {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)

                                    Text("Please enter a valid email address")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        // Optional Dedication
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Dedication (Optional)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.billixDarkGreen)

                                Spacer()

                                Text("\(dedication.count)/100")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.billixMediumGreen)
                            }

                            TextField("In honor of...", text: $dedication, axis: .vertical)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.billixDarkGreen)
                                .lineLimit(3, reservesSpace: true)
                                .focused($focusedField, equals: .dedication)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            focusedField == .dedication ? accentColor : Color.billixBorderGreen,
                                            lineWidth: focusedField == .dedication ? 2 : 1
                                        )
                                )
                                .onChange(of: dedication) { oldValue, newValue in
                                    if newValue.count > 100 {
                                        dedication = String(newValue.prefix(100))
                                    }
                                }
                        }
                    }

                    // Confirmation Section
                    VStack(spacing: 16) {
                        // Info box
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(accentColor)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("We will make a donation of")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.billixMediumGreen)

                                Text("$\(String(format: "%.2f", donation.dollarValue)) in your name")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.billixDarkGreen)
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentColor.opacity(0.08))
                        )

                        // Affordability warning (if needed)
                        if !canAfford {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Not Enough Points")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.billixDarkGreen)

                                    Text("You need \(donation.pointsCost - userPoints) more points")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.billixMediumGreen)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    }

                    Spacer(minLength: 20)

                    // Confirm Button
                    Button {
                        let dedicationText = dedication.isEmpty ? nil : dedication
                        onConfirm(donorName, donorEmail, dedicationText)
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16, weight: .semibold))

                            Text(canAfford ? "Confirm Donation (\(donation.pointsCost) Pts)" : "Not Enough Points")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: canSubmit ?
                                    [accentColor, accentColor.opacity(0.8)] :
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

    // MARK: - Helpers

    private var emailBorderColor: Color {
        if focusedField == .email {
            return isValidEmail ? accentColor : .red
        } else if !donorEmail.isEmpty && !isValidEmail {
            return .red
        } else {
            return .billixBorderGreen
        }
    }

    private func validateEmail(_ email: String) {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        isValidEmail = emailPredicate.evaluate(with: email)
    }
}

// MARK: - Preview

#Preview {
    DonationSheet(
        donation: Donation.previewDonations[0],
        userPoints: 2000,
        userName: "John Doe",
        userEmail: "john@example.com",
        onConfirm: { name, email, dedication in
            print("Confirm donation: \(name), \(email), \(dedication ?? "nil")")
        }
    )
}
