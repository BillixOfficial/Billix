//
//  OnboardingView.swift
//  Billix
//
//  Created by Billix Team
//

import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showCamera = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "1B4332"), Color(hex: "2D6A4F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                    .padding(.top, 20)
                    .padding(.horizontal, 40)

                // Content - Using switch instead of TabView to prevent
                // swipe gesture conflicts with PhotosPicker
                Group {
                    switch viewModel.currentStep {
                    case 1: zipCodeStep
                    case 2: handleStep
                    case 3: displayNameStep
                    case 4: avatarStep
                    case 5: birthdayStep
                    case 6: genderStep
                    default: zipCodeStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom buttons
                bottomButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Sign Out") {
                    Task {
                        try? await AuthService.shared.signOut()
                    }
                }
                .foregroundColor(.white.opacity(0.8))
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showCamera) {
            OnboardingImagePicker(image: $viewModel.selectedImage, sourceType: .camera)
        }
        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
            Task {
                await viewModel.loadImage()
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...viewModel.totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= viewModel.currentStep ? Color.white : Color.white.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Step 1: ZIP Code

    private var zipCodeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "location.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)

            // Title
            Text("What's your ZIP code?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Subtitle
            Text("We use this to show you local bill comparisons and savings opportunities in your area.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Input
            TextField("", text: $viewModel.zipCode)
                .keyboardType(.numberPad)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(viewModel.isZipCodeValid ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                )
                .padding(.horizontal, 60)
                .onChange(of: viewModel.zipCode) { _, newValue in
                    // Limit to 5 digits
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count > 5 {
                        viewModel.zipCode = String(filtered.prefix(5))
                    } else {
                        viewModel.zipCode = filtered
                    }
                }

            // Validation feedback
            if !viewModel.zipCode.isEmpty && !viewModel.isZipCodeValid {
                Text("Please enter a 5-digit ZIP code")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Step 2: Handle (Username)

    private var handleStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "at.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)

            // Title
            Text("Pick a username")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Subtitle
            Text("This is your unique handle in the Billix community. Others will see this on the marketplace and leaderboards.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Input with @ prefix
            HStack(spacing: 0) {
                Text("@")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))

                TextField("", text: $viewModel.handle, prompt: Text("savingsking").foregroundColor(.white.opacity(0.4)))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(viewModel.isHandleValid ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
            )
            .padding(.horizontal, 40)
            .onChange(of: viewModel.handle) { _, newValue in
                // Remove @ if typed and limit characters
                let cleaned = newValue.replacingOccurrences(of: "@", with: "")
                    .lowercased()
                    .filter { $0.isLetter || $0.isNumber || $0 == "_" }
                if cleaned.count > 20 {
                    viewModel.handle = String(cleaned.prefix(20))
                } else {
                    viewModel.handle = cleaned
                }
            }

            // Validation feedback
            if !viewModel.handle.isEmpty && !viewModel.isHandleValid {
                Text("3-20 characters, letters, numbers, and underscores only")
                    .font(.caption)
                    .foregroundColor(.orange.opacity(0.9))
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Step 3: Display Name

    private var displayNameStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)

            // Title
            Text("What should we call you?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Subtitle
            Text("This is your display name in the community.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Input
            TextField("", text: $viewModel.displayName, prompt: Text("Your name").foregroundColor(.white.opacity(0.5)))
                .font(.system(size: 24, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(viewModel.isDisplayNameValid ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                )
                .padding(.horizontal, 40)

            // Auto-filled indicator
            if AuthService.shared.appleProvidedName != nil && !viewModel.displayName.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "apple.logo")
                    Text("Pre-filled from Apple")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Step 4: Avatar

    private var avatarStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Title
            Text("Add a profile photo")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Subtitle
            Text("Optional - helps others recognize you in the community.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Avatar preview
            ZStack {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )

                    // Remove button
                    Button {
                        viewModel.removeSelectedImage()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .offset(x: 55, y: -55)
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.6))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                }
            }
            .padding(.vertical, 20)

            // Photo buttons
            HStack(spacing: 16) {
                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    Label("Library", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .foregroundColor(Color(hex: "1B4332"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }

                Button {
                    showCamera = true
                } label: {
                    Label("Camera", systemImage: "camera")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Step 5: Birthday

    private var birthdayStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "birthday.cake.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)

            // Title
            Text("When's your birthday?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Subtitle
            Text("We need this to verify you're 18+ for marketplace transactions and contracts.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Date Picker
            DatePicker(
                "",
                selection: $viewModel.birthday,
                in: viewModel.birthdayRange,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .padding(.horizontal, 40)

            // Age display
            HStack(spacing: 8) {
                if viewModel.isBirthdayValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("You're \(viewModel.userAge) years old")
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("You must be 18 or older")
                        .foregroundColor(.orange.opacity(0.9))
                }
            }
            .font(.callout)

            Spacer()
        }
    }

    // MARK: - Step 6: Gender

    private var genderStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)

            // Title
            Text("How do you identify?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Subtitle
            Text("Optional - helps us personalize your experience.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Gender options
            VStack(spacing: 12) {
                ForEach(GenderOption.allCases) { gender in
                    GenderOptionCard(
                        gender: gender,
                        isSelected: viewModel.selectedGender == gender
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedGender = gender
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 16) {
            // Back button (hidden on first step)
            if viewModel.currentStep > 1 {
                Button {
                    viewModel.previousStep()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(28)
                }
            }

            Spacer()

            // Skip button (only on optional steps: 4 Avatar, 6 Gender)
            if viewModel.currentStep == 4 || viewModel.currentStep == 6 {
                Button {
                    viewModel.skipCurrentStep()
                } label: {
                    Text("Skip")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.trailing, 8)
            }

            // Continue/Finish button
            Button {
                viewModel.nextStep()
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "1B4332")))
                    } else {
                        Text(viewModel.currentStep == viewModel.totalSteps ? "Get Started" : "Continue")
                            .font(.headline)
                        if viewModel.currentStep < viewModel.totalSteps {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .foregroundColor(Color(hex: "1B4332"))
                .frame(width: viewModel.currentStep == viewModel.totalSteps ? 160 : 140, height: 56)
                .background(viewModel.canProceedFromCurrentStep ? Color.white : Color.white.opacity(0.5))
                .cornerRadius(28)
            }
            .disabled(!viewModel.canProceedFromCurrentStep || viewModel.isLoading)
        }
    }
}

// MARK: - Gender Option Card

struct GenderOptionCard: View {
    let gender: GenderOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: gender.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                    .cornerRadius(12)

                Text(gender.title)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Goal Option Card

struct GoalOptionCard: View {
    let goal: GoalOption
    let isSelected: Bool
    var customText: Binding<String>?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : goal.color)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? goal.color : goal.color.opacity(0.2))
                    .cornerRadius(12)

                if goal == .custom && isSelected, let binding = customText {
                    TextField("Enter your goal", text: binding)
                        .foregroundColor(.white)
                        .font(.body)
                } else {
                    Text(goal.title)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.white)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Onboarding Image Picker

struct OnboardingImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: OnboardingImagePicker

        init(_ parent: OnboardingImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
