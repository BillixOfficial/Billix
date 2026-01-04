//
//  OnboardingViewModel.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation
import SwiftUI
import PhotosUI

// MARK: - Gender Options

enum GenderOption: String, CaseIterable, Identifiable {
    case male = "male"
    case female = "female"
    case nonBinary = "non_binary"
    case preferNotToSay = "prefer_not_to_say"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .nonBinary: return "Non-binary"
        case .preferNotToSay: return "Prefer not to say"
        }
    }

    var icon: String {
        switch self {
        case .male: return "person.fill"
        case .female: return "person.fill"
        case .nonBinary: return "person.2.fill"
        case .preferNotToSay: return "hand.raised.fill"
        }
    }
}

@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Step Management
    @Published var currentStep = 1
    let totalSteps = 6  // ZIP, Handle, Display Name, Avatar, Birthday, Gender

    // MARK: - Form Data
    @Published var zipCode = ""
    @Published var handle = ""  // NEW: Username like @SavingsKing
    @Published var displayName = ""
    @Published var selectedImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var birthday: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()  // NEW: Default to 25 years ago
    @Published var selectedGender: GenderOption?  // NEW: Gender selection
    @Published var selectedGoal: GoalOption?
    @Published var customGoal = ""

    // MARK: - UI State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showImagePicker = false
    @Published var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    // MARK: - Handle Validation
    @Published var isCheckingHandle = false
    @Published var isHandleAvailable: Bool? = nil  // nil = not checked yet
    private var handleCheckTask: Task<Void, Never>?

    // MARK: - Validation

    var isZipCodeValid: Bool {
        let digitsOnly = zipCode.filter { $0.isNumber }
        return digitsOnly.count == 5
    }

    var isHandleValid: Bool {
        let trimmed = handle.trimmingCharacters(in: .whitespaces)
        // Handle must be 3-20 characters, alphanumeric and underscores only
        let regex = "^[a-zA-Z0-9_]{3,20}$"
        return trimmed.range(of: regex, options: .regularExpression) != nil
    }

    var isDisplayNameValid: Bool {
        displayName.trimmingCharacters(in: .whitespaces).count >= 2
    }

    var isBirthdayValid: Bool {
        // Must be at least 18 years old
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return (ageComponents.year ?? 0) >= 18
    }

    var userAge: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year ?? 0
    }

    var canProceedFromCurrentStep: Bool {
        switch currentStep {
        case 1: return isZipCodeValid
        case 2: return isHandleValid && isHandleAvailable == true && !isCheckingHandle
        case 3: return isDisplayNameValid
        case 4: return true  // Avatar is optional
        case 5: return isBirthdayValid
        case 6: return true  // Gender is optional
        default: return false
        }
    }

    /// Check if the handle is available (with debouncing)
    func checkHandleAvailability() {
        // Cancel any existing check
        handleCheckTask?.cancel()

        let trimmedHandle = handle.trimmingCharacters(in: .whitespaces).lowercased()

        // Reset if handle is invalid
        guard isHandleValid else {
            isHandleAvailable = nil
            isCheckingHandle = false
            return
        }

        isCheckingHandle = true
        isHandleAvailable = nil

        // Debounce the check by 500ms
        handleCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)

            guard !Task.isCancelled else { return }

            let available = await AuthService.shared.isHandleAvailable(trimmedHandle)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.isHandleAvailable = available
                self.isCheckingHandle = false
            }
        }
    }

    var finalGoal: String? {
        if let selected = selectedGoal {
            return selected == .custom ? customGoal : selected.title
        }
        return nil
    }

    // Date range for birthday picker (18-100 years old)
    var birthdayRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let minDate = calendar.date(byAdding: .year, value: -100, to: Date()) ?? Date()
        let maxDate = calendar.date(byAdding: .year, value: -18, to: Date()) ?? Date()
        return minDate...maxDate
    }

    // MARK: - Initialization

    init() {
        // Pre-fill display name from Apple if available
        if let appleName = AuthService.shared.appleProvidedName {
            var nameParts: [String] = []
            if let givenName = appleName.givenName {
                nameParts.append(givenName)
            }
            if let familyName = appleName.familyName {
                nameParts.append(familyName)
            }
            if !nameParts.isEmpty {
                displayName = nameParts.joined(separator: " ")
            }
        }
    }

    // MARK: - Navigation

    func nextStep() {
        guard canProceedFromCurrentStep else { return }

        if currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            Task {
                await completeOnboarding()
            }
        }
    }

    func previousStep() {
        if currentStep > 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }

    func skipCurrentStep() {
        // Only allow skipping optional steps (4: Avatar, 6: Gender)
        guard currentStep == 4 || currentStep == 6 else { return }

        if currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            Task {
                await completeOnboarding()
            }
        }
    }

    // MARK: - Image Handling

    func loadImage() async {
        guard let item = selectedPhotoItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.selectedImage = image
                }
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }

    func removeSelectedImage() {
        selectedImage = nil
        selectedPhotoItem = nil
    }

    // MARK: - Onboarding Completion

    func completeOnboarding() async {
        isLoading = true
        errorMessage = nil

        // Prepare avatar data
        var avatarData: Data? = nil
        if let image = selectedImage {
            avatarData = image.jpegData(compressionQuality: 0.8)
        }

        do {
            try await AuthService.shared.completeOnboarding(
                zipCode: zipCode.filter { $0.isNumber },
                handle: handle.trimmingCharacters(in: .whitespaces).lowercased(),
                displayName: displayName.trimmingCharacters(in: .whitespaces),
                avatarData: avatarData,
                birthday: birthday,
                gender: selectedGender?.rawValue,
                goal: finalGoal
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}

// MARK: - Goal Options

enum GoalOption: String, CaseIterable, Identifiable {
    case lowerBills = "lower_bills"
    case trackExpenses = "track_expenses"
    case findDeals = "find_deals"
    case helpCommunity = "help_community"
    case custom = "custom"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lowerBills: return "Lower my monthly bills"
        case .trackExpenses: return "Track all my expenses"
        case .findDeals: return "Find better deals"
        case .helpCommunity: return "Help my community"
        case .custom: return "Something else"
        }
    }

    var icon: String {
        switch self {
        case .lowerBills: return "arrow.down.circle.fill"
        case .trackExpenses: return "chart.bar.fill"
        case .findDeals: return "tag.fill"
        case .helpCommunity: return "person.3.fill"
        case .custom: return "pencil.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .lowerBills: return .green
        case .trackExpenses: return .blue
        case .findDeals: return .orange
        case .helpCommunity: return .purple
        case .custom: return .gray
        }
    }
}
