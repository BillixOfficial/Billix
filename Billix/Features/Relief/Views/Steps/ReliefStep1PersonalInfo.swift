//
//  ReliefStep1PersonalInfo.swift
//  Billix
//
//  Step 1: Personal Information
//

import SwiftUI

struct ReliefStep1PersonalInfo: View {
    @ObservedObject var viewModel: ReliefFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Let's start with your contact information")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("We'll use this to follow up on your request and keep you updated.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            // Form Fields
            VStack(spacing: 20) {
                // Full Name
                ReliefFormField(
                    title: "Full Name",
                    placeholder: "Enter your full name",
                    text: $viewModel.fullName,
                    icon: "person.fill",
                    isRequired: true
                )

                // Email
                ReliefFormField(
                    title: "Email Address",
                    placeholder: "your@email.com",
                    text: $viewModel.email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    isRequired: true
                )

                // Phone
                ReliefFormField(
                    title: "Phone Number",
                    placeholder: "(555) 123-4567",
                    text: $viewModel.phone,
                    icon: "phone.fill",
                    keyboardType: .phonePad,
                    isRequired: false
                )
            }

            // Privacy note
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#5B8A6B"))

                Text("Your information is secure and will only be used to process your relief request.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }
            .padding(12)
            .background(Color(hex: "#5B8A6B").opacity(0.08))
            .cornerRadius(10)
        }
    }
}

// MARK: - Relief Form Field Component

struct ReliefFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isRequired: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                if isRequired {
                    Text("*")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                }
            }

            // Input
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#8B9A94"))
                        .frame(width: 24)
                }

                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#2D3B35"))
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
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
    }
}

struct ReliefStep1PersonalInfo_Previews: PreviewProvider {
    static var previews: some View {
        ReliefStep1PersonalInfo(viewModel: ReliefFlowViewModel())
        .padding()
        .background(Color(hex: "#F7F9F8"))
    }
}
