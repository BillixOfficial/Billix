//
//  ScanUploadOptionsView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct ScanUploadOptionsView: View {
    @ObservedObject var viewModel: ScanUploadViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose how to upload your bill")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                // Camera Button
                UploadOptionButton(
                    title: "Take Photo",
                    subtitle: "Use your camera to capture the bill",
                    icon: "camera.fill",
                    color: .blue
                ) {
                    // TODO: Implement camera picker
                    simulateMockUpload(source: .camera)
                }

                // Photo Library Button
                UploadOptionButton(
                    title: "Choose from Photos",
                    subtitle: "Select an image from your library",
                    icon: "photo.on.rectangle",
                    color: .purple
                ) {
                    // TODO: Implement photo picker
                    simulateMockUpload(source: .photos)
                }

                // File Picker Button
                UploadOptionButton(
                    title: "Choose File",
                    subtitle: "Select a PDF or image file",
                    icon: "folder.fill",
                    color: .orange
                ) {
                    // TODO: Implement document picker
                    simulateMockUpload(source: .documentPicker)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }

    // Temporary mock upload for testing
    private func simulateMockUpload(source: UploadSource) {
        Task {
            // Create dummy file data
            let dummyData = "Mock bill data".data(using: .utf8)!
            await viewModel.uploadBill(
                fileData: dummyData,
                fileName: "mock-bill.pdf",
                source: source
            )
        }
    }
}

struct UploadOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
    }
}
