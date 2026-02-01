//
//  ProfileSheets.swift
//  Billix
//
//  Sheet views for the Profile feature
//

import SwiftUI

// MARK: - Report Error Sheet

struct ReportErrorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var feedbackText: String
    @Binding var selectedCategory: String
    @Binding var isSubmitting: Bool
    let onSubmit: () -> Void

    private let categories = ["Bill Analysis", "Savings Calculation", "Provider Detection", "Amount Recognition", "Other"]
    private let accentColor = Color(hex: "#4A7C59")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header illustration
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text("Report an AI Error")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3436"))

                        Text("Help us improve by telling us what went wrong")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#636E72"))
                            .multilineTextAlignment(.center)
                    }

                    // Category Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error Category")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#636E72"))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    Button {
                                        selectedCategory = category
                                    } label: {
                                        Text(category)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(selectedCategory == category ? .white : Color(hex: "#2D3436"))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(selectedCategory == category ? accentColor : Color(hex: "#F0F0F0"))
                                            )
                                    }
                                }
                            }
                        }
                    }

                    // Description Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Describe the Error")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#636E72"))

                        TextEditor(text: $feedbackText)
                            .font(.system(size: 15))
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color(hex: "#F5F7F6"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .overlay(
                                Group {
                                    if feedbackText.isEmpty {
                                        Text("What did you expect vs what happened?")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 20)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }

                    // Submit Button
                    Button {
                        onSubmit()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Submit Report")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(feedbackText.isEmpty ? Color.gray : accentColor)
                        .cornerRadius(12)
                    }
                    .disabled(feedbackText.isEmpty || isSubmitting)

                    Spacer()
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color(hex: "#F5F7F6"))
    }
}

// MARK: - Help Center Sheet

struct HelpCenterSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let accentColor = Color(hex: "#4A7C59")

    private let faqItems: [(icon: String, question: String, answer: String)] = [
        ("doc.text.viewfinder", "How do I upload a bill?", "Tap the Upload tab, then either take a photo of your bill or select one from your photo library. Our AI will analyze it automatically."),
        ("chart.line.uptrend.xyaxis", "How does Billix find savings?", "We analyze your bills and compare them against thousands of rates in your area to find better deals with other providers."),
        ("shield.checkmark", "Is my data secure?", "Yes! We use bank-level encryption to protect your data. We never sell your information and you can delete your account anytime."),
        ("clock.arrow.circlepath", "How often should I upload bills?", "We recommend uploading bills monthly to track changes and catch any unexpected price increases."),
        ("person.2", "What is bill swapping?", "Bill swapping lets you help others pay their bills in exchange for help with yours - building trust and community savings."),
        ("dollarsign.circle", "Is Billix free?", "Yes! Billix is free to use. We offer optional premium features for power users who want advanced analytics.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text("Help Center")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3436"))

                        Text("Find answers to common questions")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#636E72"))
                    }

                    // FAQ Items
                    VStack(spacing: 12) {
                        ForEach(faqItems, id: \.question) { item in
                            FAQItemView(icon: item.icon, question: item.question, answer: item.answer)
                        }
                    }

                    // Contact Support Button
                    VStack(spacing: 12) {
                        Text("Still need help?")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#636E72"))

                        Button {
                            if let url = URL(string: "mailto:support@billixapp.com?subject=Help%20Request") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Contact Support")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(accentColor)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.top, 8)

                    Spacer()
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color(hex: "#F5F7F6"))
    }
}

// MARK: - Suggest Feature Sheet

struct SuggestFeatureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var feedbackText: String
    @Binding var isSubmitting: Bool
    let onSubmit: () -> Void

    private let accentColor = Color(hex: "#4A7C59")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header illustration
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.yellow)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text("Suggest a Feature")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3436"))

                        Text("We'd love to hear your ideas for improving Billix")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#636E72"))
                            .multilineTextAlignment(.center)
                    }

                    // Idea Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Idea")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#636E72"))

                        TextEditor(text: $feedbackText)
                            .font(.system(size: 15))
                            .frame(minHeight: 150)
                            .padding(12)
                            .background(Color(hex: "#F5F7F6"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .overlay(
                                Group {
                                    if feedbackText.isEmpty {
                                        Text("Describe your feature idea and how it would help you...")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 20)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }

                    // Tips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tips for great suggestions:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#636E72"))

                        VStack(alignment: .leading, spacing: 6) {
                            TipRow(text: "Describe the problem you're trying to solve")
                            TipRow(text: "Explain how this would help you save money or time")
                            TipRow(text: "Be specific about what you'd like to see")
                        }
                    }
                    .padding(14)
                    .background(Color(hex: "#FEF9E7"))
                    .cornerRadius(12)

                    // Submit Button
                    Button {
                        onSubmit()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Submit Suggestion")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(feedbackText.isEmpty ? Color.gray : accentColor)
                        .cornerRadius(12)
                    }
                    .disabled(feedbackText.isEmpty || isSubmitting)

                    Spacer()
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color(hex: "#F5F7F6"))
    }
}

// MARK: - Edit Name Sheet

struct EditNameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    @Binding var isSaving: Bool
    let onSave: () -> Void

    private let accentColor = Color(hex: "#4A7C59")

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 70, height: 70)
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                }
                .padding(.top, 20)

                Text("Edit Your Name")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3436"))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#636E72"))

                    TextField("Enter your name", text: $name)
                        .font(.system(size: 16))
                        .padding(14)
                        .background(Color(hex: "#F5F7F6"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)

                Button {
                    print("🔵 EditNameSheet: Save button tapped")
                    onSave()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Save Changes")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(name.isEmpty || isSaving ? Color.gray : accentColor)
                    .cornerRadius(12)
                }
                .disabled(name.isEmpty || isSaving)
                .padding(.horizontal, 20)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color(hex: "#F5F7F6"))
    }
}

// MARK: - Edit Email Sheet

struct EditEmailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var email: String
    @Binding var isSaving: Bool
    let onSave: () -> Void

    private let accentColor = Color(hex: "#4A7C59")

    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 70, height: 70)
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                }
                .padding(.top, 20)

                VStack(spacing: 8) {
                    Text("Change Email")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3436"))

                    Text("A verification email will be sent to confirm")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#636E72"))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("New Email Address")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#636E72"))

                    TextField("Enter new email", text: $email)
                        .font(.system(size: 16))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(Color(hex: "#F5F7F6"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isValidEmail || email.isEmpty ? Color.gray.opacity(0.2) : Color.red.opacity(0.5), lineWidth: 1)
                        )

                    if !email.isEmpty && !isValidEmail {
                        Text("Please enter a valid email address")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)

                Button {
                    print("🔵 EditEmailSheet: Save button tapped")
                    onSave()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Update Email")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(!isValidEmail || isSaving ? Color.gray : accentColor)
                    .cornerRadius(12)
                }
                .disabled(!isValidEmail || isSaving)
                .padding(.horizontal, 20)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color(hex: "#F5F7F6"))
    }
}

// MARK: - Change Password Sheet

struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isSaving: Bool
    let onSave: () -> Void

    @State private var showNewPassword = false
    private let accentColor = Color(hex: "#4A7C59")

    var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }

    var isValidPassword: Bool {
        newPassword.count >= 8
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 70, height: 70)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 20)

                    Text("Change Password")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3436"))

                    VStack(spacing: 16) {
                        // New Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#636E72"))

                            HStack {
                                if showNewPassword {
                                    TextField("Enter new password", text: $newPassword)
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                }

                                Button {
                                    showNewPassword.toggle()
                                } label: {
                                    Image(systemName: showNewPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                }
                            }
                            .font(.system(size: 16))
                            .padding(14)
                            .background(Color(hex: "#F5F7F6"))
                            .cornerRadius(12)

                            if !newPassword.isEmpty && !isValidPassword {
                                Text("Password must be at least 8 characters")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }

                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#636E72"))

                            SecureField("Confirm new password", text: $confirmPassword)
                                .font(.system(size: 16))
                                .padding(14)
                                .background(Color(hex: "#F5F7F6"))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(!confirmPassword.isEmpty && !passwordsMatch ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                                )

                            if !confirmPassword.isEmpty && !passwordsMatch {
                                Text("Passwords do not match")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Button {
                        print("🔵 ChangePasswordSheet: Save button tapped")
                        onSave()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Update Password")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(!isValidPassword || !passwordsMatch || isSaving ? Color.gray : accentColor)
                        .cornerRadius(12)
                    }
                    .disabled(!isValidPassword || !passwordsMatch || isSaving)
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color(hex: "#F5F7F6"))
    }
}

// MARK: - Household Sheet

struct HouseholdSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var householdName: String
    @Binding var inviteCode: String
    @Binding var members: [HouseholdMember]
    @Binding var joinCode: String
    @Binding var isCreating: Bool
    @Binding var isJoining: Bool
    let onCreate: () -> Void
    let onJoin: () -> Void
    let onLeave: () -> Void

    @State private var showLeaveConfirmation = false
    @State private var selectedTab = 0
    private let accentColor = Color(hex: "#4A7C59")

    var hasHousehold: Bool {
        !inviteCode.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 70, height: 70)
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 20)

                    Text(hasHousehold ? householdName : "Household")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3436"))

                    if hasHousehold {
                        // Show household details
                        householdDetailsView
                    } else {
                        // Show create/join options
                        createJoinView
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Leave Household?", isPresented: $showLeaveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Leave", role: .destructive) { onLeave() }
            } message: {
                Text("Are you sure you want to leave this household?")
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color(hex: "#F5F7F6"))
    }

    private var householdDetailsView: some View {
        VStack(spacing: 20) {
            // Invite Code Card
            VStack(spacing: 12) {
                Text("INVITE CODE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .tracking(1)

                Text(inviteCode)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)

                Button {
                    UIPasteboard.general.string = inviteCode
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy Code")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(accentColor)
                    .cornerRadius(20)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#F5F7F6"))
            .cornerRadius(16)

            // Members List
            VStack(alignment: .leading, spacing: 12) {
                Text("MEMBERS (\(members.count))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .tracking(1)

                ForEach(members) { member in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(member.name.prefix(1)).uppercased())
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(accentColor)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "#2D3436"))

                            Text(member.role.capitalized)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#636E72"))
                        }

                        Spacer()

                        if member.role == "owner" {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }

            // Leave Button
            Button {
                showLeaveConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Leave Household")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.top, 10)
        }
    }

    private var createJoinView: some View {
        VStack(spacing: 20) {
            Text("Create a new household or join an existing one with an invite code")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#636E72"))
                .multilineTextAlignment(.center)

            // Tab Selector
            Picker("", selection: $selectedTab) {
                Text("Create New").tag(0)
                Text("Join Existing").tag(1)
            }
            .pickerStyle(.segmented)

            if selectedTab == 0 {
                // Create New
                VStack(alignment: .leading, spacing: 8) {
                    Text("Household Name")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#636E72"))

                    TextField("e.g., Smith Family", text: $householdName)
                        .font(.system(size: 16))
                        .padding(14)
                        .background(Color(hex: "#F5F7F6"))
                        .cornerRadius(12)
                }

                Button {
                    onCreate()
                } label: {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Household")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(householdName.isEmpty || isCreating ? Color.gray : accentColor)
                    .cornerRadius(12)
                }
                .disabled(householdName.isEmpty || isCreating)
            } else {
                // Join Existing
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invite Code")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#636E72"))

                    TextField("Enter 8-character code", text: $joinCode)
                        .font(.system(size: 16, design: .monospaced))
                        .textInputAutocapitalization(.characters)
                        .padding(14)
                        .background(Color(hex: "#F5F7F6"))
                        .cornerRadius(12)
                }

                Button {
                    onJoin()
                } label: {
                    HStack {
                        if isJoining {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "person.badge.plus")
                            Text("Join Household")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(joinCode.isEmpty || isJoining ? Color.gray : accentColor)
                    .cornerRadius(12)
                }
                .disabled(joinCode.isEmpty || isJoining)
            }
        }
    }
}

// MARK: - Subscription Sheet

struct SubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storeKit: StoreKitService
    let accentColor: Color

    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.2))
                            .frame(width: 90, height: 90)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text("Billix Prime")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3436"))

                        Text("Unlock premium features")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#636E72"))
                    }

                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced bill analytics")
                        FeatureRow(icon: "bell.badge.fill", text: "Priority price drop alerts")
                        FeatureRow(icon: "person.2.fill", text: "Unlimited household members")
                        FeatureRow(icon: "doc.text.magnifyingglass", text: "AI-powered savings recommendations")
                        FeatureRow(icon: "star.fill", text: "Early access to new features")
                        FeatureRow(icon: "headphones", text: "Priority customer support")
                    }
                    .padding(20)
                    .background(Color(hex: "#F5F7F6"))
                    .cornerRadius(16)

                    // Price Card
                    VStack(spacing: 8) {
                        Text("$4.99")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(accentColor)

                        Text("per month")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#636E72"))
                    }
                    .padding(.vertical, 20)

                    // Subscribe Button
                    Button {
                        purchasePrime()
                    } label: {
                        HStack {
                            if isPurchasing || storeKit.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "crown.fill")
                                Text("Subscribe to Prime")
                            }
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isPurchasing ? Color.gray : accentColor)
                        .cornerRadius(14)
                    }
                    .disabled(isPurchasing || storeKit.isLoading)

                    // Restore Purchases
                    Button {
                        Task {
                            await storeKit.restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(accentColor)
                    }

                    // Terms
                    Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period. You can manage your subscription in your App Store settings.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Spacer()
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color(hex: "#F5F7F6"))
    }

    private func purchasePrime() {
        isPurchasing = true

        Task {
            do {
                // Try to get the monthly product from StoreKit
                if let product = storeKit.monthlyProduct {
                    _ = try await storeKit.purchase(product)
                    await MainActor.run {
                        isPurchasing = false
                        if storeKit.isPremium {
                            dismiss()
                        }
                    }
                } else {
                    // Fallback: simulate purchase for testing (remove in production)
                    await MainActor.run {
                        isPurchasing = false
                        errorMessage = "Product not available. Please try again later."
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
