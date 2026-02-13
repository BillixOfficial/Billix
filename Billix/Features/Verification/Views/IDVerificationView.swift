//
//  IDVerificationView.swift
//  Billix
//
//  View for ID document verification
//

import SwiftUI
import PhotosUI

struct IDVerificationView: View {
    @StateObject private var verificationService = IDVerificationService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selfieImage: UIImage?
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var showSelfiePicker = false
    @State private var showFrontPicker = false
    @State private var showBackPicker = false
    @State private var showCamera = false
    @State private var cameraTarget: CameraTarget = .selfie
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum CameraTarget {
        case selfie, front, back
    }

    // Callback when verification completes (submission sent, not approved)
    var onVerificationComplete: (() -> Void)?

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.billixCreamBeige.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Show different content based on status
                        switch verificationService.verificationStatus {
                        case .verified:
                            verifiedStatusView
                        case .pending:
                            pendingStatusView
                        case .rejected:
                            rejectedStatusView
                        case .notStarted, .failed:
                            // Show upload UI
                            headerSection
                            idCaptureSection
                            submitButton
                            privacyNote
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Verify ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showSelfiePicker) {
                IDImagePicker(image: $selfieImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showFrontPicker) {
                IDImagePicker(image: $frontImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showBackPicker) {
                IDImagePicker(image: $backImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                IDImagePicker(
                    image: cameraTargetBinding,
                    sourceType: .camera
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Verification Submitted!", isPresented: $showSuccess) {
                Button("Done") {
                    onVerificationComplete?()
                    dismiss()
                }
            } message: {
                Text("Your ID verification has been submitted. We'll review it within 24 hours and notify you once approved.")
            }
            .task {
                // Fetch current status on appear
                await verificationService.fetchSubmissionStatus()
            }
        }
    }

    /// Binding for camera target image
    private var cameraTargetBinding: Binding<UIImage?> {
        switch cameraTarget {
        case .selfie:
            return $selfieImage
        case .front:
            return $frontImage
        case .back:
            return $backImage
        }
    }

    // MARK: - Status Views

    /// View shown when verification is complete
    private var verifiedStatusView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.billixMoneyGreen)

            Text("ID Verified")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.billixDarkTeal)

            Text("Your identity has been verified. You can now participate in Bill Connections.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Done") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.billixDarkTeal)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.top)
        }
        .padding(.top, 40)
    }

    /// View shown when verification is pending review
    private var pendingStatusView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 80))
                .foregroundColor(.billixGoldenAmber)

            Text("Under Review")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.billixDarkTeal)

            Text("Estimated review time: ~24 hours")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.billixGoldenAmber)

            Text("Your ID verification is being reviewed. We'll notify you once it's approved.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let submittedAt = verificationService.submissionStatus?.submittedAt {
                Text("Submitted: \(submittedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Info banner - upload blocked while pending
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.billixDarkTeal)
                Text("You cannot submit a new verification while one is under review.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.billixDarkTeal.opacity(0.1))
            .cornerRadius(12)

            Button("Done") {
                onVerificationComplete?()
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.billixDarkTeal)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.top)
        }
        .padding(.top, 40)
    }

    /// View shown when verification was rejected
    private var rejectedStatusView: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text("Verification Rejected")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.billixDarkTeal)

            if let reason = verificationService.rejectionReason {
                VStack(spacing: 8) {
                    Text("Reason:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(reason)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }

            Text("Please review the reason above and submit new photos.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                // Reset to show upload UI
                verificationService.verificationStatus = .notStarted
                selfieImage = nil
                frontImage = nil
                backImage = nil
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.billixDarkTeal)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.top)
        }
        .padding(.top, 40)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.billixMoneyGreen)

            Text("Verify Your Identity")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.billixDarkTeal)

            Text("Take a photo of your government-issued ID to get the Verified badge and unlock premium matching features.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - ID Capture Section

    private var idCaptureSection: some View {
        VStack(spacing: 20) {
            // Selfie (required)
            IDCaptureCard(
                title: "Selfie",
                subtitle: "Take a clear photo of your face",
                image: selfieImage,
                isRequired: true,
                preferCamera: true,
                onCameraCapture: {
                    cameraTarget = .selfie
                    showCamera = true
                },
                onGallerySelect: {
                    showSelfiePicker = true
                },
                onRemove: {
                    selfieImage = nil
                }
            )

            // Front of ID (required)
            IDCaptureCard(
                title: "Front of ID",
                subtitle: "Driver's License, Passport, or State ID",
                image: frontImage,
                isRequired: true,
                onCameraCapture: {
                    cameraTarget = .front
                    showCamera = true
                },
                onGallerySelect: {
                    showFrontPicker = true
                },
                onRemove: {
                    frontImage = nil
                }
            )

            // Back of ID (optional)
            IDCaptureCard(
                title: "Back of ID",
                subtitle: "Optional - for driver's licenses",
                image: backImage,
                isRequired: false,
                onCameraCapture: {
                    cameraTarget = .back
                    showCamera = true
                },
                onGallerySelect: {
                    showBackPicker = true
                },
                onRemove: {
                    backImage = nil
                }
            )
        }
    }

    // MARK: - Submit Button

    /// Check if all required images are captured
    private var canSubmit: Bool {
        selfieImage != nil && frontImage != nil
    }

    private var submitButton: some View {
        Button(action: submitVerification) {
            HStack {
                if verificationService.isLoading {
                    ProgressView()
                        .tint(.white)
                    Text("Submitting...")
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Submit for Review")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSubmit ? Color.billixDarkTeal : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canSubmit || verificationService.isLoading)
        .padding(.top)
    }

    // MARK: - Privacy Note

    private var privacyNote: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.secondary)
                Text("Secure Verification")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text("Your photos are securely stored and only reviewed by Billix staff to verify your identity. Once verified, your photos are deleted. We never share your information with third parties.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func submitVerification() {
        guard let selfie = selfieImage, let front = frontImage else { return }

        Task {
            do {
                try await verificationService.submitForManualVerification(
                    selfie: selfie,
                    idFront: front,
                    idBack: backImage
                )
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - ID Capture Card

struct IDCaptureCard: View {
    let title: String
    let subtitle: String
    let image: UIImage?
    let isRequired: Bool
    var preferCamera: Bool = false
    let onCameraCapture: () -> Void
    let onGallerySelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.billixDarkTeal)

                if isRequired {
                    Text("Required")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                }
            }

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)

            // Image or capture buttons
            if let image = image {
                // Show captured image
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.billixMoneyGreen, lineWidth: 2)
                        )

                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.red))
                    }
                    .padding(8)
                }
            } else {
                // Show capture options
                HStack(spacing: 12) {
                    // Camera button
                    Button(action: onCameraCapture) {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Camera")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.billixDarkTeal.opacity(0.1))
                        .foregroundColor(.billixDarkTeal)
                        .cornerRadius(12)
                    }

                    // Gallery button
                    Button(action: onGallerySelect) {
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.title2)
                            Text("Gallery")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.billixDarkTeal.opacity(0.1))
                        .foregroundColor(.billixDarkTeal)
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Image Picker

private struct IDImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: IDImagePicker

        init(_ parent: IDImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

struct IDVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        IDVerificationView()
    }
}
