//
//  UploadMethodSelectionView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

/// Full-screen view for selecting an upload method for full bill analysis
struct UploadMethodSelectionView: View {
    @ObservedObject var viewModel: UploadViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showCamera = false
    @State private var showGallery = false
    @State private var showDocumentPicker = false

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.96, green: 0.97, blue: 1.0)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header description + feature highlights
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Upload your bill to unlock AI-powered insights")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.billixDarkGreen)

                        // Feature badges - all visible without scrolling
                        HStack(spacing: 6) {
                            FeatureBadge(icon: "list.bullet.rectangle", text: "Line-by-line")
                            FeatureBadge(icon: "map", text: "Area comparison")
                            FeatureBadge(icon: "dollarsign.circle", text: "Find savings")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Section header for upload methods
                    Text("Choose how to upload")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.billixMediumGreen)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .padding(.horizontal, 20)

                    // Upload method options
                    VStack(spacing: 12) {
                        // Camera
                        UploadMethodRow(
                            icon: "camera.fill",
                            iconColor: .buttonCamera,
                            title: "Upload with Camera",
                            subtitle: "Take a photo of your bill"
                        ) {
                            showCamera = true
                        }

                        // Gallery
                        UploadMethodRow(
                            icon: "photo.on.rectangle",
                            iconColor: .buttonGallery,
                            title: "Choose from Gallery",
                            subtitle: "Select from your photos"
                        ) {
                            showGallery = true
                        }

                        // Document
                        UploadMethodRow(
                            icon: "doc.fill",
                            iconColor: .buttonDocument,
                            title: "Upload Document",
                            subtitle: "PDF or image file"
                        ) {
                            showDocumentPicker = true
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Choose Upload Method")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        // Present sheets directly from this view
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                viewModel.handleImageSelected(image)
                dismiss()
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showGallery) {
            ImagePicker(sourceType: .photoLibrary) { image in
                viewModel.handleImageSelected(image)
                dismiss()
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker { url in
                viewModel.handleDocumentSelected(url)
                dismiss()
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Feature Badge

struct FeatureBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.billixChartBlue)

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.billixDarkGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.billixChartBlue.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UploadMethodSelectionView(viewModel: UploadViewModel())
    }
}
