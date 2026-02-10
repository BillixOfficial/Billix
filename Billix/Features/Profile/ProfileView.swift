//
//  ProfileView.swift
//  Billix
//
//  Profile Page - All profile and settings content in tabs
//

import SwiftUI
import PhotosUI
import StoreKit

// MARK: - Profile View

struct ProfileView: View {
    // Modal presentation support
    var isModal: Bool = false
    @Environment(\.dismiss) private var dismiss

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
            }
        }
    }

    // User email from auth session
    @State private var userEmail: String = ""

    // Bio editing states
    @State private var showBioEditor = false
    @State private var editingBio = ""
    @State private var isSavingBio = false

    // Photo picker states
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var showPhotoError = false
    @State private var photoErrorMessage = ""
    @State private var avatarCacheBuster = Date() // Force AsyncImage refresh after upload

    // Settings states
    @State private var biometricLock = false
    @State private var neighborhoodStats = true
    @State private var providerBidding = false
    @State private var billDueDates = true
    @State private var priceHikeAlerts = true
    @State private var syncCalendar = false

    // Support states
    @State private var showDeleteAccountAlert = false
    @State private var showReportErrorSheet = false
    @State private var showHelpCenterSheet = false
    @State private var showSuggestFeatureSheet = false
    @State private var feedbackText = ""
    @State private var selectedErrorCategory = "Bill Analysis"
    @State private var isSubmittingFeedback = false
    @State private var showFeedbackSuccess = false

    // Account editing states
    @State private var showEditNameSheet = false
    @State private var showEditEmailSheet = false
    @State private var showChangePasswordSheet = false
    @State private var showHouseholdSheet = false
    @State private var showSubscriptionSheet = false
    @State private var editingName = ""
    @State private var editingEmail = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSavingAccount = false
    @State private var accountErrorMessage = ""
    @State private var showAccountError = false
    @State private var showAccountSuccess = false
    @State private var accountSuccessMessage = ""

    // Household states
    @State private var householdName = ""
    @State private var householdInviteCode = ""
    @State private var householdMembers: [HouseholdMember] = []
    @State private var isCreatingHousehold = false
    @State private var isJoiningHousehold = false
    @State private var joinCode = ""

    // Verification states
    @State private var showPhoneVerification = false
    @State private var showIDVerification = false
    @State private var verifiedOnlyMode = false
    @ObservedObject private var phoneVerificationService = PhoneVerificationService.shared
    @ObservedObject private var idVerificationService = IDVerificationService.shared
    @ObservedObject private var tokenService = TokenService.shared

    // Trust & Points
    @ObservedObject private var activityScoreService = ActivityScoreService.shared
    @State private var userBillixPoints: Int = 0
    private let rewardsService = RewardsService.shared

    // Username state
    @State private var username: String = ""

    // Referral code states
    @State private var referralCodeInput: String = ""
    @State private var isRedeemingCode = false
    @State private var referralCodeRedeemed = false

    // StoreKit
    @ObservedObject private var storeKit = StoreKitService.shared

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
            .toolbar {
                if isModal {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.gray.opacity(0.6), Color(hex: "#F5F7F6"))
                        }
                    }
                }
            }
            .onAppear {
                fetchUserEmail()
                loadUsernameFromProfile()
                loadUserPoints()
                Task {
                    await activityScoreService.fetchAndCalculateScore()
                }
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
        .presentationBackground(Color(hex: "#F5F7F6"))
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
            }
        }
    }

    // MARK: - Username Loading

    private func loadUsernameFromProfile() {
        // First try to load from database
        if let handle = authService.currentUser?.billixProfile?.handle, !handle.isEmpty {
            username = handle
        } else if username.isEmpty {
            // Generate random username and save it
            username = generateRandomUsername()
            saveUsernameToDatabase(username)
        }
    }

    private func generateRandomUsername() -> String {
        let adjectives = ["Swift", "Clever", "Savvy", "Smart", "Thrifty", "Lucky", "Happy", "Bright", "Cool", "Epic"]
        let nouns = ["Saver", "Guru", "Pro", "Star", "Champ", "Hero", "Ninja", "Ace", "Boss", "Whiz"]
        let randomNumber = Int.random(in: 100...999)
        let adjective = adjectives.randomElement() ?? "Savvy"
        let noun = nouns.randomElement() ?? "Saver"
        return "\(adjective)\(noun)\(randomNumber)"
    }

    private func saveUsernameToDatabase(_ newUsername: String) {
        Task {
            do {
                try await authService.updateHandle(newUsername)
            } catch {
            }
        }
    }

    // MARK: - Points Loading

    private func loadUserPoints() {
        guard let userId = authService.currentUser?.id else { return }
        Task {
            do {
                let points = try await rewardsService.getUserPoints(userId: userId)
                await MainActor.run {
                    userBillixPoints = points
                }
            } catch {
            }
        }
    }

    // MARK: - Photo Upload

    private func uploadProfilePhoto(item: PhotosPickerItem) async {
        await MainActor.run {
            isUploadingPhoto = true
        }

        do {
            // Load image data from picker
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                throw NSError(domain: "ProfileView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image data"])
            }

            // Compress image if needed
            let compressedData: Data
            if let uiImage = UIImage(data: imageData) {
                compressedData = uiImage.jpegData(compressionQuality: 0.7) ?? imageData
            } else {
                compressedData = imageData
            }

            // Use AuthService's updateAvatar method (handles upload + database update + refresh)
            try await authService.updateAvatar(imageData: compressedData)

            await MainActor.run {
                isUploadingPhoto = false
                selectedPhotoItem = nil

                // Clear URL cache to force fresh image load
                URLCache.shared.removeAllCachedResponses()

                avatarCacheBuster = Date() // Force AsyncImage to reload

                print("[ProfileView] Upload complete. Current avatarUrl: \(authService.currentUser?.profile.avatarUrl ?? "nil")")
                print("[ProfileView] Cache buster updated to: \(avatarCacheBuster)")

                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

        } catch {
            print("[ProfileView] Upload error: \(error.localizedDescription)")
            await MainActor.run {
                isUploadingPhoto = false
                selectedPhotoItem = nil
                photoErrorMessage = error.localizedDescription
                showPhotoError = true
                UINotificationFeedbackGenerator().notificationOccurred(.error)
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
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack {
                // Rounded Rectangle Photo Container - Light grayish-blue background like Figma
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "#E8EEF4"))
                    .frame(width: 100, height: 130)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

                // Profile image or initials
                if let avatarUrl = authService.currentUser?.profile.avatarUrl,
                   let url = URL(string: "\(avatarUrl)?v=\(Int(avatarCacheBuster.timeIntervalSince1970))") {
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

                // Upload overlay
                if isUploadingPhoto {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 100, height: 130)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }

                // Camera icon overlay (bottom right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(accentGreen)
                                .frame(width: 28, height: 28)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .offset(x: 4, y: 4)
                    }
                }
                .frame(width: 100, height: 130)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: selectedPhotoItem) { _, newItem in
            if let newItem = newItem {
                Task {
                    await uploadProfilePhoto(item: newItem)
                }
            }
        }
        .alert("Photo Upload Error", isPresented: $showPhotoError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(photoErrorMessage)
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

            // BILLIX STATS Card
            ProfileCard(title: "BILLIX STATS") {
                VStack(spacing: 14) {
                    // Billix Score (out of 100)
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(activityScoreService.scoreColor.opacity(0.15))
                                .frame(width: 42, height: 42)

                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 18))
                                .foregroundColor(activityScoreService.scoreColor)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("BILLIX SCORE")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(lightGrayText)
                                .tracking(0.8)
                            HStack(spacing: 6) {
                                Text("\(activityScoreService.score)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(activityScoreService.scoreColor)
                                Text("/ 100")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(grayTextColor)
                                Text("•")
                                    .foregroundColor(grayTextColor)
                                Text(activityScoreService.scoreLabel)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(activityScoreService.scoreColor)
                            }
                        }

                        Spacer()
                    }

                    Divider()
                        .background(Color(hex: "#E5E7EB"))

                    // Billix Points
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#F3E8FF"))
                                .frame(width: 42, height: 42)

                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#5D4DB1"))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("BILLIX POINTS")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(lightGrayText)
                                .tracking(0.8)
                            HStack(spacing: 4) {
                                Text("\(userBillixPoints)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(darkTextColor)
                                Text("pts")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(grayTextColor)
                            }
                        }

                        Spacer()
                    }

                    Divider()
                        .background(Color(hex: "#E5E7EB"))

                    // Member Since
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#EEF2FF"))
                                .frame(width: 42, height: 42)

                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#6366F1"))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("MEMBER SINCE")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(lightGrayText)
                                .tracking(0.8)
                            Text(authService.currentUser?.memberSinceString.replacingOccurrences(of: "Member since: ", with: "") ?? "")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(darkTextColor)
                        }

                        Spacer()
                    }

                    Divider()
                        .background(Color(hex: "#E5E7EB"))

                    // Bills Analyzed
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#FEF3E2"))
                                .frame(width: 42, height: 42)

                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#E8A54B"))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("BILLS ANALYZED")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(lightGrayText)
                                .tracking(0.8)
                            Text("\(authService.currentUser?.billixProfile?.billsAnalyzedCount ?? 0)")
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
                    // Name - Editable
                    Button {
                        editingName = profileData.name
                        showEditNameSheet = true
                    } label: {
                        AccountRowView(icon: "person.fill", iconColor: .blue, title: "Name", value: profileData.name)
                    }

                    Divider().padding(.leading, 52)

                    // Email - Display only
                    AccountRowView(icon: "envelope.fill", iconColor: .blue, title: "Email", value: profileData.email, showChevron: false)

                    Divider().padding(.leading, 52)

                    // Username - Display only
                    AccountRowView(icon: "at", iconColor: .purple, title: "Username", value: username.isEmpty ? "Not set" : "@\(username)", showChevron: false)

                    Divider().padding(.leading, 52)

                    // Household - Opens management sheet
                    Button {
                        loadHouseholdData()
                        showHouseholdSheet = true
                    } label: {
                        AccountRowView(icon: "person.2.fill", iconColor: .blue, title: "Household", value: householdName.isEmpty ? "Not set" : householdName)
                    }

                    Divider().padding(.leading, 52)

                    // Change Password
                    Button {
                        currentPassword = ""
                        newPassword = ""
                        confirmPassword = ""
                        showChangePasswordSheet = true
                    } label: {
                        AccountRowView(icon: "lock.fill", iconColor: .blue, title: "Change Password", value: nil)
                    }
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

                        Text(storeKit.isPremium ? "Prime" : "Free")
                            .font(.system(size: 14, weight: storeKit.isPremium ? .semibold : .regular))
                            .foregroundColor(storeKit.isPremium ? selectedTabColor : grayTextColor)
                    }
                    .padding(.vertical, 8)

                    if !storeKit.isPremium {
                        Divider().padding(.leading, 52)

                        Button {
                            showSubscriptionSheet = true
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

                                Text("Get Billix Prime - $4.99/mo")
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
            }

            // Verification Status Card
            verificationStatusCard

            // Connect Tokens Card
            connectTokensCard

            // Referral Card
            ProfileCard(title: "INVITE & EARN") {
                VStack(spacing: 16) {
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
                            Text("Enter Referral Code")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(darkTextColor)
                            Text("Get bonus points when you use a friend's code")
                                .font(.system(size: 12))
                                .foregroundColor(grayTextColor)
                        }

                        Spacer()
                    }

                    if referralCodeRedeemed {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Code redeemed successfully!")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 8)
                    } else {
                        HStack(spacing: 10) {
                            TextField("Enter code", text: $referralCodeInput)
                                .font(.system(size: 15, design: .monospaced))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#F5F7F6"))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )

                            Button {
                                redeemReferralCode()
                            } label: {
                                if isRedeemingCode {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(width: 70, height: 38)
                                } else {
                                    Text("Redeem")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 70, height: 38)
                                }
                            }
                            .background(Capsule().fill(referralCodeInput.isEmpty ? Color.gray : Color.purple))
                            .disabled(referralCodeInput.isEmpty || isRedeemingCode)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditNameSheet) {
            EditNameSheet(
                name: $editingName,
                isSaving: $isSavingAccount,
                onSave: saveNameChange
            )
        }
        .sheet(isPresented: $showEditEmailSheet) {
            EditEmailSheet(
                email: $editingEmail,
                isSaving: $isSavingAccount,
                onSave: saveEmailChange
            )
        }
        .sheet(isPresented: $showChangePasswordSheet) {
            ChangePasswordSheet(
                currentPassword: $currentPassword,
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isSaving: $isSavingAccount,
                onSave: savePasswordChange
            )
        }
        .sheet(isPresented: $showHouseholdSheet) {
            HouseholdSheet(
                householdName: $householdName,
                inviteCode: $householdInviteCode,
                members: $householdMembers,
                joinCode: $joinCode,
                isCreating: $isCreatingHousehold,
                isJoining: $isJoiningHousehold,
                onCreate: createHousehold,
                onJoin: joinHousehold,
                onLeave: leaveHousehold
            )
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionSheet(storeKit: storeKit, accentColor: selectedTabColor)
        }
        .sheet(isPresented: $showPhoneVerification) {
            PhoneVerificationView {
                // Refresh verification status after completion
                Task {
                    _ = try? await phoneVerificationService.checkVerificationStatus()
                }
            }
        }
        .sheet(isPresented: $showIDVerification) {
            IDVerificationView {
                // Refresh verification status after completion
                Task {
                    _ = try? await idVerificationService.checkVerificationStatus()
                }
            }
        }
        .alert("Error", isPresented: $showAccountError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(accountErrorMessage)
        }
        .alert("Success", isPresented: $showAccountSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(accountSuccessMessage)
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
                    // Report AI Error
                    Button {
                        feedbackText = ""
                        selectedErrorCategory = "Bill Analysis"
                        showReportErrorSheet = true
                    } label: {
                        SupportRowView(icon: "exclamationmark.bubble.fill", iconColor: .orange, title: "Report AI Error", subtitle: "Help us improve our AI accuracy")
                    }

                    Divider().padding(.leading, 52)

                    // Help Center
                    Button {
                        showHelpCenterSheet = true
                    } label: {
                        SupportRowView(icon: "questionmark.circle.fill", iconColor: .blue, title: "Help Center", subtitle: "FAQs, guides, and tutorials")
                    }

                    Divider().padding(.leading, 52)

                    // Suggest a Feature
                    Button {
                        feedbackText = ""
                        showSuggestFeatureSheet = true
                    } label: {
                        SupportRowView(icon: "lightbulb.fill", iconColor: .yellow, title: "Suggest a Feature", subtitle: "We'd love to hear your ideas")
                    }
                }
            }

            // Legal Card
            ProfileCard(title: "LEGAL") {
                VStack(spacing: 0) {
                    // Terms of Service
                    Button {
                        openURL("https://www.billixapp.com/terms")
                    } label: {
                        SupportRowView(icon: "doc.text.fill", iconColor: .gray, title: "Terms of Service", subtitle: "Our terms and conditions")
                    }

                    Divider().padding(.leading, 52)

                    // Privacy Policy
                    Button {
                        openURL("https://www.billixapp.com/privacy")
                    } label: {
                        SupportRowView(icon: "hand.raised.fill", iconColor: .gray, title: "Privacy Policy", subtitle: "How we protect your data")
                    }

                    Divider().padding(.leading, 52)

                    // App Version (not clickable)
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("App Version")
                                .font(.system(size: 15))
                                .foregroundColor(darkTextColor)
                            Text("Build 1.0.2 (2024.12)")
                                .font(.system(size: 12))
                                .foregroundColor(grayTextColor)
                        }

                        Spacer()

                        Text("v1.0.2")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTabColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(selectedTabColor.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                }
            }

            // Account Actions Card
            ProfileCard(title: "ACCOUNT ACTIONS") {
                VStack(spacing: 0) {
                    // Log Out
                    Button {
                        Task {
                            try? await AuthService.shared.signOut()
                        }
                    } label: {
                        SupportRowView(icon: "rectangle.portrait.and.arrow.right.fill", iconColor: .blue, title: "Log Out", subtitle: "Sign out of your account")
                    }

                    Divider().padding(.leading, 52)

                    // Delete Account
                    Button {
                        showDeleteAccountAlert = true
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

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Delete Account")
                                    .font(.system(size: 15))
                                    .foregroundColor(.red)
                                Text("Permanently delete all your data")
                                    .font(.system(size: 12))
                                    .foregroundColor(grayTextColor)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(grayTextColor)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }

            // Contact Us Card
            ProfileCard(title: "CONTACT US") {
                VStack(spacing: 0) {
                    // Email Support
                    Button {
                        openEmail(
                            to: "info@billixapp.com",
                            subject: "General Inquiry - Billix App",
                            body: "Hi Billix Team,\n\n"
                        )
                    } label: {
                        SupportRowView(icon: "envelope.fill", iconColor: selectedTabColor, title: "Email Support", subtitle: "info@billixapp.com")
                    }

                    Divider().padding(.leading, 52)

                    // Website
                    Button {
                        openURL("https://www.billixapp.com")
                    } label: {
                        SupportRowView(icon: "globe", iconColor: Color(hex: "#6366F1"), title: "Visit Website", subtitle: "www.billixapp.com")
                    }
                }
            }
        }
        .sheet(isPresented: $showReportErrorSheet) {
            ReportErrorSheet(
                feedbackText: $feedbackText,
                selectedCategory: $selectedErrorCategory,
                isSubmitting: $isSubmittingFeedback,
                onSubmit: submitErrorReport
            )
        }
        .sheet(isPresented: $showHelpCenterSheet) {
            HelpCenterSheet()
        }
        .sheet(isPresented: $showSuggestFeatureSheet) {
            SuggestFeatureSheet(
                feedbackText: $feedbackText,
                isSubmitting: $isSubmittingFeedback,
                onSubmit: submitFeatureSuggestion
            )
        }
        .alert("Delete Account?", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                openEmail(
                    to: "support@billixapp.com",
                    subject: "Account Deletion Request",
                    body: """
                    Hi Billix Team,

                    I would like to request the deletion of my account.

                    User ID: \(authService.currentUser?.id.uuidString ?? "Unknown")
                    Email: \(userEmail)

                    I understand this action is permanent and all my data will be deleted.

                    Thank you.
                    """
                )
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.")
        }
        .alert("Feedback Submitted!", isPresented: $showFeedbackSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thank you for your feedback! We'll review it and get back to you if needed.")
        }
    }

    // MARK: - Feedback Submission

    private func submitErrorReport() {
        isSubmittingFeedback = true
        // In production, this would send to your backend
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isSubmittingFeedback = false
            showReportErrorSheet = false
            showFeedbackSuccess = true
            feedbackText = ""
        }
    }

    private func submitFeatureSuggestion() {
        isSubmittingFeedback = true
        // In production, this would send to your backend
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isSubmittingFeedback = false
            showSuggestFeatureSheet = false
            showFeedbackSuccess = true
            feedbackText = ""
        }
    }

    // MARK: - Account Update Functions

    private func saveNameChange() {
        print("🔵 saveNameChange called")
        isSavingAccount = true
        Task {
            do {
                guard let userId = authService.currentUser?.id else {
                    throw NSError(domain: "ProfileView", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                }

                // Update profiles table
                try await SupabaseService.shared.client
                    .from("profiles")
                    .update(["display_name": editingName])
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                // Refresh user data to reflect changes in UI
                try await authService.refreshUserData()

                // Dismiss sheet first
                print("🔵 Dismissing sheet...")
                await MainActor.run {
                    isSavingAccount = false
                    showEditNameSheet = false
                }

                // Wait for sheet dismissal animation before showing alert
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

                // Show success alert
                print("🔵 Showing alert...")
                await MainActor.run {
                    accountSuccessMessage = "Name updated successfully!"
                    showAccountSuccess = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isSavingAccount = false
                    accountErrorMessage = error.localizedDescription
                    showAccountError = true
                }
            }
        }
    }

    private func saveEmailChange() {
        print("🔵 saveEmailChange called")
        isSavingAccount = true
        Task {
            do {
                // Update email in Supabase Auth
                try await SupabaseService.shared.client.auth.update(user: .init(email: editingEmail))

                // Dismiss sheet first
                print("🔵 Dismissing sheet...")
                await MainActor.run {
                    isSavingAccount = false
                    showEditEmailSheet = false
                }

                // Wait for sheet dismissal animation before showing alert
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

                // Show success alert
                print("🔵 Showing alert...")
                await MainActor.run {
                    accountSuccessMessage = "A confirmation email has been sent to your new email address. Please verify to complete the change."
                    showAccountSuccess = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isSavingAccount = false
                    accountErrorMessage = error.localizedDescription
                    showAccountError = true
                }
            }
        }
    }

    private func savePasswordChange() {
        guard newPassword == confirmPassword else {
            accountErrorMessage = "Passwords do not match"
            showAccountError = true
            return
        }

        guard newPassword.count >= 8 else {
            accountErrorMessage = "Password must be at least 8 characters"
            showAccountError = true
            return
        }

        print("🔵 savePasswordChange called")
        isSavingAccount = true
        Task {
            do {
                // Update password in Supabase Auth
                try await SupabaseService.shared.client.auth.update(user: .init(password: newPassword))

                // Dismiss sheet first
                print("🔵 Dismissing sheet...")
                await MainActor.run {
                    isSavingAccount = false
                    showChangePasswordSheet = false
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                }

                // Wait for sheet dismissal animation before showing alert
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

                // Show success alert
                print("🔵 Showing alert...")
                await MainActor.run {
                    accountSuccessMessage = "Password changed successfully!"
                    showAccountSuccess = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isSavingAccount = false
                    accountErrorMessage = error.localizedDescription
                    showAccountError = true
                }
            }
        }
    }

    // MARK: - Household Functions

    private func loadHouseholdData() {
        Task {
            guard let userId = authService.currentUser?.id else { return }

            do {
                // First check if user is in a household via household_members
                let memberResponse: [HouseholdMemberDB] = try await SupabaseService.shared.client
                    .from("household_members")
                    .select("*, households(*)")
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                    .value

                if let membership = memberResponse.first, let household = membership.households {
                    await MainActor.run {
                        householdName = household.name
                        householdInviteCode = household.invite_code
                    }

                    // Load all members
                    let membersResponse: [HouseholdMemberWithProfile] = try await SupabaseService.shared.client
                        .from("household_members")
                        .select("*, profiles(display_name, user_id)")
                        .eq("household_id", value: household.id.uuidString)
                        .execute()
                        .value

                    await MainActor.run {
                        householdMembers = membersResponse.map { member in
                            HouseholdMember(
                                id: member.id,
                                userId: member.user_id,
                                name: member.profiles?.display_name ?? "Unknown",
                                role: member.role,
                                joinedAt: member.joined_at
                            )
                        }
                    }
                } else {
                    await MainActor.run {
                        householdName = ""
                        householdInviteCode = ""
                        householdMembers = []
                    }
                }
            } catch {
            }
        }
    }

    private func createHousehold() {
        guard !householdName.isEmpty else {
            accountErrorMessage = "Please enter a household name"
            showAccountError = true
            return
        }

        isCreatingHousehold = true
        Task {
            do {
                guard let userId = authService.currentUser?.id else {
                    throw NSError(domain: "ProfileView", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                }

                // Create household
                let newHousehold = HouseholdInsert(name: householdName, owner_id: userId)
                let response: [HouseholdDB] = try await SupabaseService.shared.client
                    .from("households")
                    .insert(newHousehold)
                    .select()
                    .execute()
                    .value

                guard let household = response.first else {
                    throw NSError(domain: "ProfileView", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create household"])
                }

                // Add owner as member
                let member = HouseholdMemberInsert(household_id: household.id, user_id: userId, role: "owner")
                try await SupabaseService.shared.client
                    .from("household_members")
                    .insert(member)
                    .execute()

                // Update profile with household_id
                try await SupabaseService.shared.client
                    .from("profiles")
                    .update(["household_id": household.id.uuidString])
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                await MainActor.run {
                    householdInviteCode = household.invite_code
                    isCreatingHousehold = false
                    loadHouseholdData()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isCreatingHousehold = false
                    accountErrorMessage = error.localizedDescription
                    showAccountError = true
                }
            }
        }
    }

    private func joinHousehold() {
        guard !joinCode.isEmpty else {
            accountErrorMessage = "Please enter an invite code"
            showAccountError = true
            return
        }

        isJoiningHousehold = true
        Task {
            do {
                guard let userId = authService.currentUser?.id else {
                    throw NSError(domain: "ProfileView", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                }

                // Find household by invite code
                let households: [HouseholdDB] = try await SupabaseService.shared.client
                    .from("households")
                    .select()
                    .eq("invite_code", value: joinCode.uppercased())
                    .execute()
                    .value

                guard let household = households.first else {
                    throw NSError(domain: "ProfileView", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid invite code"])
                }

                // Check member count
                let memberCount: Int = try await SupabaseService.shared.client
                    .from("household_members")
                    .select("*", head: true, count: .exact)
                    .eq("household_id", value: household.id.uuidString)
                    .execute()
                    .count ?? 0

                guard memberCount < household.max_members else {
                    throw NSError(domain: "ProfileView", code: 3, userInfo: [NSLocalizedDescriptionKey: "Household is full"])
                }

                // Add user as member
                let member = HouseholdMemberInsert(household_id: household.id, user_id: userId, role: "member")
                try await SupabaseService.shared.client
                    .from("household_members")
                    .insert(member)
                    .execute()

                // Update profile
                try await SupabaseService.shared.client
                    .from("profiles")
                    .update(["household_id": household.id.uuidString])
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                await MainActor.run {
                    isJoiningHousehold = false
                    joinCode = ""
                    loadHouseholdData()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isJoiningHousehold = false
                    accountErrorMessage = error.localizedDescription
                    showAccountError = true
                }
            }
        }
    }

    private func leaveHousehold() {
        Task {
            do {
                guard let userId = authService.currentUser?.id else { return }

                // Remove from household_members
                try await SupabaseService.shared.client
                    .from("household_members")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                // Clear household_id in profiles using raw SQL
                try await SupabaseService.shared.client
                    .rpc("clear_household_id", params: ["p_user_id": userId.uuidString])
                    .execute()

                await MainActor.run {
                    householdName = ""
                    householdInviteCode = ""
                    householdMembers = []
                    showHouseholdSheet = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    accountErrorMessage = error.localizedDescription
                    showAccountError = true
                }
            }
        }
    }

    private func redeemReferralCode() {
        guard !referralCodeInput.isEmpty else { return }

        isRedeemingCode = true
        Task {
            do {
                // Simulate API call to validate and redeem code
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay

                // TODO: Add actual referral code redemption logic with Supabase
                // For now, just mark as redeemed
                await MainActor.run {
                    isRedeemingCode = false
                    referralCodeRedeemed = true
                    referralCodeInput = ""
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isRedeemingCode = false
                    accountErrorMessage = "Failed to redeem code. Please try again."
                    showAccountError = true
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func openEmail(to: String, subject: String, body: String) {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailtoString = "mailto:\(to)?subject=\(encodedSubject)&body=\(encodedBody)"

        if let url = URL(string: mailtoString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Verification Status Card

    private var verificationStatusCard: some View {
        ProfileCard(title: "VERIFICATION STATUS") {
            VStack(spacing: 0) {
                // Phone Verification
                Button {
                    if !phoneVerificationService.isPhoneVerified {
                        showPhoneVerification = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(phoneVerificationService.isPhoneVerified ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: phoneVerificationService.isPhoneVerified ? "phone.badge.checkmark" : "phone.fill")
                                .font(.system(size: 16))
                                .foregroundColor(phoneVerificationService.isPhoneVerified ? .green : .orange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Phone Number")
                                .font(.system(size: 15))
                                .foregroundColor(darkTextColor)
                            Text(phoneVerificationService.isPhoneVerified ? "Verified" : "Tap to verify")
                                .font(.system(size: 12))
                                .foregroundColor(phoneVerificationService.isPhoneVerified ? .green : grayTextColor)
                        }

                        Spacer()

                        if phoneVerificationService.isPhoneVerified {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(grayTextColor)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .disabled(phoneVerificationService.isPhoneVerified)

                Divider().padding(.leading, 52)

                // ID Verification
                Button {
                    if !idVerificationService.isIDVerified {
                        showIDVerification = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(idVerificationService.isIDVerified ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: idVerificationService.isIDVerified ? "checkmark.seal.fill" : "person.text.rectangle")
                                .font(.system(size: 16))
                                .foregroundColor(idVerificationService.isIDVerified ? .green : .blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("ID Verification")
                                .font(.system(size: 15))
                                .foregroundColor(darkTextColor)
                            Text(idVerificationService.isIDVerified ? "Verified" : "Get the Verified badge")
                                .font(.system(size: 12))
                                .foregroundColor(idVerificationService.isIDVerified ? .green : grayTextColor)
                        }

                        Spacer()

                        if idVerificationService.isIDVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.billixMoneyGreen)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(grayTextColor)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .disabled(idVerificationService.isIDVerified)

                // Verified Only Mode (Prime feature)
                if storeKit.isPrime && phoneVerificationService.isPhoneVerified && idVerificationService.isIDVerified {
                    Divider().padding(.leading, 52)

                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 16))
                                .foregroundColor(.purple)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Verified Only Mode")
                                .font(.system(size: 15))
                                .foregroundColor(darkTextColor)
                            Text("Only match with verified users")
                                .font(.system(size: 12))
                                .foregroundColor(grayTextColor)
                        }

                        Spacer()

                        Toggle("", isOn: $verifiedOnlyMode)
                            .labelsHidden()
                            .tint(selectedTabColor)
                            .onChange(of: verifiedOnlyMode) { _, newValue in
                                Task {
                                    await updateVerifiedOnlyMode(newValue)
                                }
                            }
                    }
                    .padding(.vertical, 8)
                }

                // Verification Tier Display
                if phoneVerificationService.isPhoneVerified || idVerificationService.isIDVerified {
                    Divider().padding(.leading, 52)

                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(verificationTierColor.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: verificationTierIcon)
                                .font(.system(size: 16))
                                .foregroundColor(verificationTierColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Trust Level")
                                .font(.system(size: 15))
                                .foregroundColor(darkTextColor)
                            Text(verificationTierName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(verificationTierColor)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            Task {
                _ = try? await phoneVerificationService.checkVerificationStatus()
                _ = try? await idVerificationService.checkVerificationStatus()
                await loadVerifiedOnlyMode()
            }
        }
    }

    // MARK: - Verification Tier Helpers

    private var verificationTier: VerificationTier {
        if idVerificationService.isIDVerified && phoneVerificationService.isPhoneVerified {
            return .fullyVerified
        } else if phoneVerificationService.isPhoneVerified {
            return .phoneVerified
        }
        return .basic
    }

    private var verificationTierName: String {
        switch verificationTier {
        case .basic: return "Basic"
        case .phoneVerified: return "Phone Verified"
        case .fullyVerified: return "Fully Verified"
        }
    }

    private var verificationTierIcon: String {
        switch verificationTier {
        case .basic: return "person"
        case .phoneVerified: return "phone.badge.checkmark"
        case .fullyVerified: return "checkmark.seal.fill"
        }
    }

    private var verificationTierColor: Color {
        switch verificationTier {
        case .basic: return .gray
        case .phoneVerified: return .blue
        case .fullyVerified: return .billixMoneyGreen
        }
    }

    private func updateVerifiedOnlyMode(_ enabled: Bool) async {
        guard let userId = authService.currentUser?.id else { return }

        do {
            try await SupabaseService.shared.client
                .from("profiles")
                .update(["verified_only_mode": enabled])
                .eq("user_id", value: userId.uuidString)
                .execute()
        } catch {
        }
    }

    private func loadVerifiedOnlyMode() async {
        guard let userId = authService.currentUser?.id else { return }

        do {
            let response: [VerifiedOnlyResponse] = try await SupabaseService.shared.client
                .from("profiles")
                .select("verified_only_mode")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            if let mode = response.first?.verified_only_mode {
                await MainActor.run {
                    verifiedOnlyMode = mode
                }
            }
        } catch {
        }
    }

    // MARK: - Connect Tokens Card

    private var connectTokensCard: some View {
        ProfileCard(title: "CONNECT TOKENS") {
            VStack(spacing: 0) {
                // Token Balance
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.billixGoldenAmber.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(.billixGoldenAmber)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Token Balance")
                            .font(.system(size: 15))
                            .foregroundColor(darkTextColor)

                        if tokenService.hasUnlimitedTokens {
                            Text("Unlimited (Prime)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedTabColor)
                        } else {
                            Text("\(tokenService.totalAvailableTokens) tokens available")
                                .font(.system(size: 12))
                                .foregroundColor(grayTextColor)
                        }
                    }

                    Spacer()

                    if !tokenService.hasUnlimitedTokens {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(tokenService.tokenBalance)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.billixGoldenAmber)
                            if tokenService.freeTokensRemaining > 0 {
                                Text("+\(tokenService.freeTokensRemaining) free")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)

                // Buy Tokens (only show if not Prime)
                if !tokenService.hasUnlimitedTokens {
                    Divider().padding(.leading, 52)

                    Button {
                        Task {
                            do {
                                let success = try await tokenService.purchaseTokenPack()
                                if success {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                }
                            } catch {
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Buy 3 Tokens")
                                    .font(.system(size: 15))
                                    .foregroundColor(darkTextColor)
                                Text("$1.99 - Use for Bill Connection")
                                    .font(.system(size: 12))
                                    .foregroundColor(grayTextColor)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(grayTextColor)
                        }
                        .padding(.vertical, 8)
                    }

                    Divider().padding(.leading, 52)

                    // Token info
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: "info.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Token Info")
                                .font(.system(size: 15))
                                .foregroundColor(darkTextColor)
                            Text("2 free tokens/month, reset on \(tokenResetDateString)")
                                .font(.system(size: 12))
                                .foregroundColor(grayTextColor)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            Task {
                await tokenService.loadTokenBalance()
            }
        }
    }

    private var tokenResetDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: tokenService.freeTokensResetDate)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(AuthService.shared)
}
