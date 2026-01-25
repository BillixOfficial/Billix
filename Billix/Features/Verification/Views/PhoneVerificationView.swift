//
//  PhoneVerificationView.swift
//  Billix
//
//  View for phone number verification via SMS
//

import SwiftUI

struct PhoneVerificationView: View {
    @StateObject private var verificationService = PhoneVerificationService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var phoneNumber: String = ""
    @State private var verificationCode: String = ""
    @State private var showCodeEntry = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Callback when verification completes
    var onVerificationComplete: (() -> Void)?

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.billixCreamBeige.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        if !showCodeEntry {
                            // Phone number entry
                            phoneEntrySection
                        } else {
                            // Code entry
                            codeEntrySection
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Verify Phone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Phone Verified!", isPresented: $showSuccess) {
                Button("Done") {
                    onVerificationComplete?()
                    dismiss()
                }
            } message: {
                Text("Your phone number has been verified successfully.")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "phone.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.billixDarkTeal)

            Text("Verify Your Phone Number")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.billixDarkTeal)

            Text("We'll send you a verification code via SMS to confirm your phone number.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Phone Entry Section

    private var phoneEntrySection: some View {
        VStack(spacing: 20) {
            // Phone number field
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                HStack {
                    Text("+1")
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)

                    TextField("(555) 555-5555", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }

            // Send code button
            Button(action: sendCode) {
                HStack {
                    if verificationService.isSendingCode {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send Verification Code")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidPhoneNumber ? Color.billixDarkTeal : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isValidPhoneNumber || verificationService.isSendingCode)
        }
        .padding(.top)
    }

    // MARK: - Code Entry Section

    private var codeEntrySection: some View {
        VStack(spacing: 20) {
            // Info text
            Text("Enter the 6-digit code sent to\n+1 \(formattedPhoneNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Code field
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification Code")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                TextField("000000", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.title2.monospaced())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }

            // Verify button
            Button(action: verifyCode) {
                HStack {
                    if verificationService.isVerifying {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Verify")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidCode ? Color.billixDarkTeal : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isValidCode || verificationService.isVerifying)

            // Resend code button
            Button(action: sendCode) {
                Text("Resend Code")
                    .foregroundColor(.billixDarkTeal)
            }
            .disabled(verificationService.isSendingCode)

            // Change number button
            Button(action: {
                showCodeEntry = false
                verificationCode = ""
                verificationService.reset()
            }) {
                Text("Change Phone Number")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top)
    }

    // MARK: - Computed Properties

    private var isValidPhoneNumber: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count >= 10
    }

    private var isValidCode: Bool {
        let digits = verificationCode.filter { $0.isNumber }
        return digits.count >= 4
    }

    private var formattedPhoneNumber: String {
        let digits = phoneNumber.filter { $0.isNumber }
        if digits.count >= 10 {
            let areaCode = String(digits.prefix(3))
            let middle = String(digits.dropFirst(3).prefix(3))
            let last = String(digits.dropFirst(6).prefix(4))
            return "(\(areaCode)) \(middle)-\(last)"
        }
        return phoneNumber
    }

    // MARK: - Actions

    private func sendCode() {
        Task {
            do {
                let cleanedNumber = phoneNumber.filter { $0.isNumber }
                try await verificationService.sendVerificationCode(to: cleanedNumber)
                showCodeEntry = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func verifyCode() {
        Task {
            do {
                let cleanedNumber = phoneNumber.filter { $0.isNumber }
                let verified = try await verificationService.verifyCode(verificationCode, for: cleanedNumber)
                if verified {
                    showSuccess = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PhoneVerificationView()
}
