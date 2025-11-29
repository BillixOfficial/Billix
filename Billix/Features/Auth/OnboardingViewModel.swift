//
//  OnboardingViewModel.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Step Management
    @Published var currentStep = 1
    let totalSteps = 4

    // MARK: - Form Data
    @Published var zipCode = ""
    @Published var displayName = ""
    @Published var selectedImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedGoal: GoalOption?
    @Published var customGoal = ""

    // MARK: - UI State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showImagePicker = false
    @Published var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    // MARK: - Validation
    var isZipCodeValid: Bool {
        let digitsOnly = zipCode.filter { $0.isNumber }
        return digitsOnly.count == 5
    }

    var isDisplayNameValid: Bool {
        displayName.trimmingCharacters(in: .whitespaces).count >= 2
    }

    var canProceedFromCurrentStep: Bool {
        switch currentStep {
        case 1: return isZipCodeValid
        case 2: return isDisplayNameValid
        case 3, 4: return true // Optional steps
        default: return false
        }
    }

    var finalGoal: String? {
        if let selected = selectedGoal {
            return selected == .custom ? customGoal : selected.title
        }
        return nil
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
        // Only allow skipping optional steps (3 and 4)
        guard currentStep >= 3 else { return }

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
                displayName: displayName.trimmingCharacters(in: .whitespaces),
                avatarData: avatarData,
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
