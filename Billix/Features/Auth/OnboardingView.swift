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

                // Content
                TabView(selection: $viewModel.currentStep) {
                    zipCodeStep.tag(1)
                    displayNameStep.tag(2)
                    avatarStep.tag(3)
                    goalStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)

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
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $viewModel.selectedImage, sourceType: .camera)
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

    // MARK: - Step 2: Display Name

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
            Text("This is how you'll appear in the community.")
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

    // MARK: - Step 3: Avatar

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

    // MARK: - Step 4: Goal

    private var goalStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Title
            Text("What's your main goal?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Subtitle
            Text("We'll personalize your experience based on what matters most to you.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Goal options
            VStack(spacing: 12) {
                ForEach(GoalOption.allCases) { goal in
                    GoalOptionCard(
                        goal: goal,
                        isSelected: viewModel.selectedGoal == goal,
                        customText: goal == .custom ? $viewModel.customGoal : nil
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedGoal = goal
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

            // Skip button (only on optional steps)
            if viewModel.currentStep >= 3 {
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

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
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
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
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

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
