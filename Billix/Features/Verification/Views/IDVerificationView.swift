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

    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var showFrontPicker = false
    @State private var showBackPicker = false
    @State private var showCamera = false
    @State private var cameraTarget: CameraTarget = .front
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum CameraTarget {
        case front, back
    }

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

                        // ID capture sections
                        idCaptureSection

                        // Submit button
                        submitButton

                        // Privacy note
                        privacyNote

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Verify ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showFrontPicker) {
                IDImagePicker(image: $frontImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showBackPicker) {
                IDImagePicker(image: $backImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                IDImagePicker(
                    image: cameraTarget == .front ? $frontImage : $backImage,
                    sourceType: .camera
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("ID Verified!", isPresented: $showSuccess) {
                Button("Done") {
                    onVerificationComplete?()
                    dismiss()
                }
            } message: {
                Text("Your ID has been verified successfully. You now have the Verified badge!")
            }
        }
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
            // Front of ID
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

    private var submitButton: some View {
        Button(action: submitVerification) {
            HStack {
                if verificationService.isLoading {
                    ProgressView()
                        .tint(.white)
                    Text("Verifying...")
                } else {
                    Image(systemName: "checkmark.shield")
                    Text("Verify My ID")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(frontImage != nil ? Color.billixDarkTeal : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(frontImage == nil || verificationService.isLoading)
        .padding(.top)
    }

    // MARK: - Privacy Note

    private var privacyNote: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.secondary)
                Text("Your Privacy is Protected")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text("We use your ID only to verify your identity. We do NOT store your ID images or personal information from your ID. Only your verification status is saved.")
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
        guard let front = frontImage else { return }

        Task {
            do {
                let verified = try await verificationService.verifyID(
                    frontImage: front,
                    backImage: backImage
                )
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

// MARK: - ID Capture Card

struct IDCaptureCard: View {
    let title: String
    let subtitle: String
    let image: UIImage?
    let isRequired: Bool
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

#Preview {
    IDVerificationView()
}
