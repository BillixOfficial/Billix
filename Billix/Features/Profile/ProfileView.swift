//
//  ProfileView.swift
//  Billix
//
//  Profile Page - All profile and settings content in tabs
//

import SwiftUI

// MARK: - Profile Tab Enum

enum ProfileTab: String, CaseIterable {
    case about = "ABOUT"
    case account = "ACCOUNT"
    case settings = "SETTINGS"
    case support = "SUPPORT"
}

// MARK: - Profile Data Model

struct ProfileData {
    var name: String
    var email: String
    var dateOfBirth: String
    var address: String
    var profileImageName: String?
    var phone: String

    // ABOUT tab data
    var bio: String
    var socialLinks: [SocialLink]
    var website: String

    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    static let preview = ProfileData(
        name: "Emily Nelson",
        email: "emilynelson@gmail.com",
        dateOfBirth: "06/15/1990",
        address: "123 Main St, Newark, NJ",
        profileImageName: nil,
        phone: "+1 (555) 123-4567",
        bio: "Passionate about saving money and helping others manage their bills better. Always looking for the best deals!",
        socialLinks: [
            SocialLink(platform: "twitter", username: "@emilynelson"),
            SocialLink(platform: "linkedin", username: "emilynelson"),
            SocialLink(platform: "instagram", username: "@emily.nelson"),
            SocialLink(platform: "facebook", username: "emily.nelson")
        ],
        website: "www.emilynelson.com"
    )
}

struct SocialLink: Identifiable {
    let id = UUID()
    var platform: String
    var username: String

    var iconName: String {
        switch platform.lowercased() {
        case "twitter", "x": return "paperplane.fill"
        case "linkedin": return "link"
        case "instagram": return "camera.fill"
        case "facebook": return "person.2.fill"
        default: return "link"
        }
    }

    var color: Color {
        switch platform.lowercased() {
        case "twitter", "x": return Color(hex: "#1DA1F2")
        case "linkedin": return Color(hex: "#0077B5")
        case "instagram": return Color(hex: "#E4405F")
        case "facebook": return Color(hex: "#1877F2")
        default: return .gray
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedTab: ProfileTab = .about

    // Computed profile data from AuthService
    private var profileData: ProfileData {
        guard let user = authService.currentUser else {
            return ProfileData.preview
        }

        // Format birthday if available
        var birthdayString = ""
        if let birthday = user.billixProfile?.birthday {
            // Convert from yyyy-MM-dd to MM/dd/yyyy
            let inputFormatter = DateFormatter()
            inputFormatter.dateFormat = "yyyy-MM-dd"
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MM/dd/yyyy"
            if let date = inputFormatter.date(from: birthday) {
                birthdayString = outputFormatter.string(from: date)
            }
        }

        return ProfileData(
            name: user.fullDisplayName,  // Shows "@handle DisplayName"
            email: userEmail,
            dateOfBirth: birthdayString,
            address: user.formattedLocation,  // Shows "07030 (Jersey City, NJ)"
            profileImageName: nil,
            phone: "",
            bio: user.bio ?? "No bio yet. Tap to add one!",
            socialLinks: [],
            website: ""
        )
    }

    // Fetch email from Supabase session
    private func fetchUserEmail() {
        Task {
            do {
                let session = try await SupabaseService.shared.client.auth.session
                await MainActor.run {
                    userEmail = session.user.email ?? ""
                }
            } catch {
                print("Failed to fetch user email: \(error)")
            }
        }
    }

    // User email from auth session
    @State private var userEmail: String = ""

    // Bio editing states
    @State private var showBioEditor = false
    @State private var editingBio = ""
    @State private var isSavingBio = false

    // Settings states
    @State private var biometricLock = false
    @State private var neighborhoodStats = true
    @State private var providerBidding = false
    @State private var billDueDates = true
    @State private var priceHikeAlerts = true
    @State private var syncCalendar = false

    // Colors - Clean professional palette
    private let backgroundColor = Color(hex: "#F5F7F6")  // Soft off-white with slight green tint
    private let selectedTabColor = Color(hex: "#4A7C59")  // Refined forest green
    private let darkTextColor = Color(hex: "#2D3436")  // Rich dark gray
    private let grayTextColor = Color(hex: "#636E72")  // Medium gray
    private let lightGrayText = Color(hex: "#B2BEC3")  // Light gray
    private let cardBackground = Color.white
    private let accentGreen = Color(hex: "#4A7C59")

    var body: some View {
        NavigationStack {
            ZStack {
                // Light blue background
                backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header Section
                        profileHeaderSection

                        // Tab Selector
                        tabSelector

                        // Tab Content
                        tabContent

                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchUserEmail()
            }
            .sheet(isPresented: $showBioEditor) {
                bioEditorSheet
            }
        }
    }

    // MARK: - Bio Editor Sheet

    private var bioEditorSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Edit your bio")
                    .font(.headline)
                    .foregroundColor(darkTextColor)

                TextEditor(text: $editingBio)
                    .font(.system(size: 16))
                    .padding(12)
                    .frame(minHeight: 150)
                    .background(Color(hex: "#F5F7F6"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                Text("\(editingBio.count)/300 characters")
                    .font(.caption)
                    .foregroundColor(editingBio.count > 300 ? .red : grayTextColor)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Bio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showBioEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBio()
                    }
                    .disabled(isSavingBio || editingBio.count > 300)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveBio() {
        isSavingBio = true
        Task {
            do {
                try await authService.updateBio(editingBio)
                await MainActor.run {
                    isSavingBio = false
                    showBioEditor = false
                }
            } catch {
                await MainActor.run {
                    isSavingBio = false
                }
                print("Failed to save bio: \(error)")
            }
        }
    }

    // MARK: - Profile Header (Photo + Info)

    private var profileHeaderSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Profile Photo - Rounded Rectangle (NOT circle)
            profilePhoto

            // Profile Info
            VStack(alignment: .leading, spacing: 10) {
                // Name
                Text(profileData.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(darkTextColor)
                    .tracking(-0.3)

                // Email
                VStack(alignment: .leading, spacing: 3) {
                    Text("Email")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(lightGrayText)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(profileData.email)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(grayTextColor)
                }

                // Date of Birth
                VStack(alignment: .leading, spacing: 3) {
                    Text("Date of Birth")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(lightGrayText)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(profileData.dateOfBirth)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(grayTextColor)
                }

                // Address
                VStack(alignment: .leading, spacing: 3) {
                    Text("Address")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(lightGrayText)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(profileData.address)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(grayTextColor)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private var profilePhoto: some View {
        ZStack {
            // Rounded Rectangle Photo Container - Light grayish-blue background like Figma
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#E8EEF4"))
                .frame(width: 100, height: 130)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

            // Profile image or initials
            if let avatarUrl = authService.currentUser?.profile.avatarUrl,
               let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 130)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    case .failure:
                        profilePlaceholder
                    case .empty:
                        ProgressView()
                            .frame(width: 100, height: 130)
                    @unknown default:
                        profilePlaceholder
                    }
                }
            } else {
                profilePlaceholder
            }
        }
    }

    private var profilePlaceholder: some View {
        // Placeholder silhouette/initials
        VStack(spacing: 6) {
            Image(systemName: "person.fill")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Color(hex: "#B0C0D0"))
            Text(profileData.initials)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#8899AA"))
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 2) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedTab == tab ? .white : grayTextColor)
                        .tracking(0.3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(selectedTabColor)
                                        .shadow(color: selectedTabColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                } else {
                                    Capsule()
                                        .fill(Color.clear)
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
        )
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .about:
            aboutTabContent
        case .account:
            accountTabContent
        case .settings:
            settingsTabContent
        case .support:
            supportTabContent
        }
    }

    // MARK: - ABOUT Tab Content (Bio, Social, Contact)

    private var aboutTabContent: some View {
        VStack(spacing: 14) {
            // BIO Card - Tappable to edit
            Button {
                editingBio = authService.currentUser?.bio ?? ""
                showBioEditor = true
            } label: {
                ProfileCard(title: "BIO") {
                    HStack {
                        Text(profileData.bio)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(grayTextColor)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(selectedTabColor.opacity(0.6))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // ON THE WEB Card
            ProfileCard(title: "ON THE WEB") {
                HStack(spacing: 14) {
                    ForEach(profileData.socialLinks) { link in
                        Button {
                            // Open social link
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(link.color.opacity(0.12))
                                    .frame(width: 48, height: 48)

                                Image(systemName: link.iconName)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(link.color)
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    Spacer()
                }
            }

            // WEBSITE & PHONE Card
            ProfileCard(title: nil) {
                VStack(spacing: 14) {
                    // Website
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#EEF2FF"))
                                .frame(width: 42, height: 42)

                            Image(systemName: "globe")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#6366F1"))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("WEBSITE")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(lightGrayText)
                                .tracking(0.8)
                            Text(profileData.website)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(darkTextColor)
                        }

                        Spacer()
                    }

                    Divider()
                        .background(Color(hex: "#E5E7EB"))

                    // Phone
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(selectedTabColor.opacity(0.12))
                                .frame(width: 42, height: 42)

                            Image(systemName: "phone.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selectedTabColor)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("PHONE")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(lightGrayText)
                                .tracking(0.8)
                            Text(profileData.phone)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(darkTextColor)
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - ACCOUNT Tab Content (Personal Info, Subscription)

    private var accountTabContent: some View {
        VStack(spacing: 16) {
            // Personal Information Card
            ProfileCard(title: "PERSONAL INFORMATION") {
                VStack(spacing: 0) {
                    ProfileSettingsRowLink(icon: "person.fill", iconColor: .blue, title: "Name", value: profileData.name)
                    Divider().padding(.leading, 52)
                    ProfileSettingsRowLink(icon: "envelope.fill", iconColor: .blue, title: "Email", value: profileData.email)
                    Divider().padding(.leading, 52)
                    ProfileSettingsRowLink(icon: "phone.fill", iconColor: .blue, title: "Phone Number", value: profileData.phone)
                    Divider().padding(.leading, 52)
                    ProfileSettingsRowLink(icon: "person.2.fill", iconColor: .blue, title: "Household", value: nil)
                    Divider().padding(.leading, 52)
                    ProfileSettingsRowLink(icon: "lock.fill", iconColor: .blue, title: "Change Password", value: nil)
                }
            }

            // Subscription Card
            ProfileCard(title: "SUBSCRIPTION") {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }

                        Text("Current Plan")
                            .font(.system(size: 15))
                            .foregroundColor(darkTextColor)

                        Spacer()

                        Text("Free")
                            .font(.system(size: 14))
                            .foregroundColor(grayTextColor)
                    }
                    .padding(.vertical, 8)

                    Divider().padding(.leading, 52)

                    Button {
                        // Upgrade to Prime
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.yellow)
                            }

                            Text("Get Billix Prime - $6.99/mo")
                                .font(.system(size: 15))
                                .foregroundColor(darkTextColor)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(grayTextColor)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }

            // Referral Card
            ProfileCard(title: "INVITE & EARN") {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "gift.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.purple)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Referral Code")
                            .font(.system(size: 15))
                            .foregroundColor(darkTextColor)
                        Text("BILLIX-2024")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.purple)
                    }

                    Spacer()

                    Button {
                        UIPasteboard.general.string = "BILLIX-2024"
                    } label: {
                        Text("Copy")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.purple))
                    }
                }
            }
        }
    }

    // MARK: - SETTINGS Tab Content (Data, Privacy, Notifications)

    private var settingsTabContent: some View {
        VStack(spacing: 16) {
            // Data Ingestion Card
            ProfileCard(title: "DATA INGESTION") {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "tray.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }

                        Text("My Billix Email")
                            .font(.system(size: 15))
                            .foregroundColor(darkTextColor)

                        Spacer()

                        Button {
                            UIPasteboard.general.string = "user@billix.app"
                        } label: {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)

                    Divider().padding(.leading, 52)

                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "calendar")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }

                        Text("Sync Calendar")
                            .font(.system(size: 15))
                            .foregroundColor(darkTextColor)

                        Spacer()

                        Toggle("", isOn: $syncCalendar)
                            .labelsHidden()
                            .tint(selectedTabColor)
                    }
                    .padding(.vertical, 8)
                }
            }

            // Privacy & Trust Card
            ProfileCard(title: "PRIVACY & TRUST") {
                VStack(spacing: 0) {
                    ProfileSettingsToggleRow(icon: "faceid", iconColor: .blue, title: "Biometric Lock", isOn: $biometricLock, tintColor: selectedTabColor)
                    Divider().padding(.leading, 52)
                    ProfileSettingsToggleRow(icon: "chart.bar.fill", iconColor: .blue, title: "Neighborhood Stats", isOn: $neighborhoodStats, tintColor: selectedTabColor)
                    Divider().padding(.leading, 52)
                    ProfileSettingsToggleRow(icon: "megaphone.fill", iconColor: .blue, title: "Provider Bidding", isOn: $providerBidding, tintColor: selectedTabColor)
                    Divider().padding(.leading, 52)
                    ProfileSettingsRowLink(icon: "square.and.arrow.up.fill", iconColor: .blue, title: "Export My Data", value: nil)
                }
            }

            // Notifications Card
            ProfileCard(title: "NOTIFICATIONS") {
                VStack(spacing: 0) {
                    ProfileSettingsToggleRow(icon: "bell.fill", iconColor: .blue, title: "Bill Due Dates", isOn: $billDueDates, tintColor: selectedTabColor)
                    Divider().padding(.leading, 52)
                    ProfileSettingsToggleRow(icon: "exclamationmark.triangle.fill", iconColor: .orange, title: "Price Hike Alerts", isOn: $priceHikeAlerts, tintColor: selectedTabColor)
                }
            }
        }
    }

    // MARK: - SUPPORT Tab Content (Help, Legal, Account Actions)

    private var supportTabContent: some View {
        VStack(spacing: 16) {
            // Help & Feedback Card
            ProfileCard(title: "HELP & FEEDBACK") {
                VStack(spacing: 0) {
                    ProfileSettingsRowLink(icon: "exclamationmark.bubble.fill", iconColor: .orange, title: "Report AI Error", value: nil)
                    Divider().padding(.leading, 52)
                    ProfileSettingsRowLink(icon: "questionmark.circle.fill", iconColor: .blue, title: "Help Center", value: nil)
                    Divider().padding(.leading, 52)
                    ProfileSettingsRowLink(icon: "lightbulb.fill", iconColor: .yellow, title: "Suggest a Feature", value: nil)
                }
            }

            // Legal Card
            ProfileCard(title: "LEGAL") {
                VStack(spacing: 0) {
                    ProfileSettingsRowLink(icon: "doc.text.fill", iconColor: .gray, title: "Terms of Service", value: nil)
                    Divider().padding(.leading, 52)
                    ProfileSettingsRowLink(icon: "hand.raised.fill", iconColor: .gray, title: "Privacy Policy", value: nil)
                    Divider().padding(.leading, 52)

                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }

                        Text("App Version")
                            .font(.system(size: 15))
                            .foregroundColor(darkTextColor)

                        Spacer()

                        Text("v1.0.2")
                            .font(.system(size: 14))
                            .foregroundColor(grayTextColor)
                    }
                    .padding(.vertical, 8)
                }
            }

            // Account Actions Card
            ProfileCard(title: "ACCOUNT ACTIONS") {
                VStack(spacing: 0) {
                    Button {
                        Task {
                            try? await AuthService.shared.signOut()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                            }

                            Text("Log Out")
                                .font(.system(size: 15))
                                .foregroundColor(darkTextColor)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(grayTextColor)
                        }
                        .padding(.vertical, 8)
                    }

                    Divider().padding(.leading, 52)

                    Button {
                        // Delete account
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                            }

                            Text("Delete Account")
                                .font(.system(size: 15))
                                .foregroundColor(.red)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(grayTextColor)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
}

// MARK: - Profile Card Component

struct ProfileCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title = title {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .tracking(1.2)
            }

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Profile Settings Row Link

struct ProfileSettingsRowLink: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?

    private let darkTextColor = Color(hex: "#2D3436")
    private let grayTextColor = Color(hex: "#636E72")

    var body: some View {
        Button {
            // Navigate to edit
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.10))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(darkTextColor)

                Spacer()

                if let value = value {
                    Text(value)
                        .font(.system(size: 13))
                        .foregroundColor(grayTextColor)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#CBD5E0"))
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ProfileSettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    let tintColor: Color

    private let darkTextColor = Color(hex: "#2D3436")

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.10))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(darkTextColor)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(tintColor)
                .scaleEffect(0.9)
        }
        .padding(.vertical, 6)
    }
}


// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(AuthService.shared)
}
