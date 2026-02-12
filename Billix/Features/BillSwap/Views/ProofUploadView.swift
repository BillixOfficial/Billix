//
//  ProofUploadView.swift
//  Billix
//
//  Phase 4: Proof of Support
//  Allows the supporter to upload a screenshot of their payment confirmation
//

import SwiftUI
import PhotosUI
import Supabase

struct ProofUploadView: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showImageSource = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var uploadError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Image Selection Area (main focus)
                    ProofImageSection(
                        selectedImage: $selectedImage,
                        showImageSource: $showImageSource
                    )

                    // Requirements checklist
                    ProofChecklistCard(proofType: viewModel.terms?.proofRequired ?? .screenshot)

                    // Upload Button (when image selected)
                    if selectedImage != nil {
                        ProofUploadSection(
                            isUploading: isUploading,
                            uploadProgress: uploadProgress,
                            uploadError: uploadError,
                            onUpload: uploadProof
                        )
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Upload Proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.billixDarkTeal)
                }
            }
            .confirmationDialog("Add Proof Image", isPresented: $showImageSource) {
                Button("Take Photo") {
                    showCamera = true
                }
                Button("Choose from Library") {
                    showPhotoPicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $selectedImage)
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }

    private func uploadProof() {
        guard let image = selectedImage else { return }

        isUploading = true
        uploadError = nil
        uploadProgress = 0

        Task {
            do {
                // Simulate upload progress
                for i in 1...10 {
                    try await Task.sleep(nanoseconds: 100_000_000)
                    uploadProgress = Double(i) / 10.0
                }

                // Upload to storage and get URL
                let proofUrl = try await uploadImageToStorage(image)

                // Submit proof via view model
                await viewModel.submitProof(proofUrl: proofUrl)

                isUploading = false
                dismiss()
            } catch {
                uploadError = error.localizedDescription
                isUploading = false
            }
        }
    }

    private func uploadImageToStorage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ProofUploadError.imageConversionFailed
        }

        let filename = "proof_\(connection.id.uuidString)_\(Date().timeIntervalSince1970).jpg"
        let supabase = SupabaseService.shared.client

        try await supabase.storage
            .from("connection-proofs")
            .upload(
                path: filename,
                file: imageData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg"
                )
            )

        let publicUrl = try supabase.storage
            .from("connection-proofs")
            .getPublicURL(path: filename)

        return publicUrl.absoluteString
    }
}

// MARK: - Proof Image Section

struct ProofImageSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var showImageSource: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16))
                Text("Payment Screenshot")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()

                if selectedImage != nil {
                    Button {
                        showImageSource = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12))
                            Text("Change")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .foregroundColor(.white)
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.billixDarkTeal, Color.billixDarkTeal.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Image area
            Group {
                if let image = selectedImage {
                    // Show selected image
                    VStack(spacing: 12) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.billixMoneyGreen.opacity(0.5), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.billixMoneyGreen)
                            Text("Image ready to upload")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.billixMoneyGreen)
                        }
                    }
                    .padding(20)
                } else {
                    // Upload prompt
                    Button {
                        showImageSource = true
                    } label: {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.billixDarkTeal.opacity(0.08))
                                    .frame(width: 72, height: 72)

                                Image(systemName: "camera.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color.billixDarkTeal)
                            }

                            VStack(spacing: 4) {
                                Text("Add Screenshot")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color.billixDarkTeal)

                                Text("Take a photo or choose from library")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    Color.billixDarkTeal.opacity(0.25),
                                    style: StrokeStyle(lineWidth: 2, dash: [8])
                                )
                        )
                        .padding(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Proof Checklist Card

struct ProofChecklistCard: View {
    let proofType: ProofType

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .font(.system(size: 14))
                    .foregroundColor(Color.billixMoneyGreen)
                Text("Your screenshot should show")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.billixDarkTeal)
            }

            VStack(alignment: .leading, spacing: 10) {
                ProofCheckItem(text: "Confirmation number", isRequired: true)
                ProofCheckItem(text: "Amount paid", isRequired: true)
                ProofCheckItem(text: "Date and time", isRequired: true)
                ProofCheckItem(text: "Company name or logo", isRequired: false)

                if proofType == .screenshotWithConfirmation {
                    ProofCheckItem(text: "Email confirmation", isRequired: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct ProofCheckItem: View {
    let text: String
    let isRequired: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isRequired ? Color.billixMoneyGreen : Color.gray.opacity(0.15))
                    .frame(width: 20, height: 20)

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isRequired ? .white : .gray.opacity(0.5))
            }

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(isRequired ? .primary : .secondary)

            Spacer()

            if isRequired {
                Text("Required")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color.billixGoldenAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.billixGoldenAmber.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Upload Section

struct ProofUploadSection: View {
    let isUploading: Bool
    let uploadProgress: Double
    let uploadError: String?
    let onUpload: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            if isUploading {
                // Upload progress
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.billixMoneyGreen.opacity(0.2), lineWidth: 4)
                            .frame(width: 56, height: 56)

                        Circle()
                            .trim(from: 0, to: uploadProgress)
                            .stroke(
                                Color.billixMoneyGreen,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(uploadProgress * 100))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.billixMoneyGreen)
                    }

                    Text("Uploading proof...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            } else {
                // Error message
                if let error = uploadError {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16))
                        Text(error)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#C45C5C"), Color(hex: "#C45C5C").opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Submit button
                Button(action: onUpload) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                        Text("Submit Proof")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.billixMoneyGreen, Color.billixMoneyGreen.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.billixMoneyGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Errors

enum ProofUploadError: LocalizedError {
    case imageConversionFailed
    case uploadFailed(String)
    case storageBucketNotFound

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to process the image. Please try again."
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .storageBucketNotFound:
            return "Storage configuration error. Please try again later."
        }
    }
}

// MARK: - Preview

#Preview {
    ProofUploadView(
        connection: Connection.mockExecuting(),
        viewModel: ConnectionDetailViewModel(connection: Connection.mockExecuting())
    )
}
