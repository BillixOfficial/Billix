//
//  UploadMethodSelectionView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

/// Redesigned upload method selection with mascot character and frosted glass buttons
struct UploadMethodSelectionView: View {
    @ObservedObject var viewModel: UploadViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var appeared = false
    @State private var mascotFloating = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.billixDarkGreen.opacity(0.8),
                    Color.billixMoneyGreen.opacity(0.6),
                    Color.billixLightGreen
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: - Mascot Character Placeholder
                ZStack {
                    // Glow effect behind mascot
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 20)

                    // Placeholder mascot
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 180, height: 180)

                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 180, height: 180)

                            VStack(spacing: 8) {
                                Image(systemName: "face.smiling.inverse")
                                    .font(.system(size: 60, weight: .light))
                                    .foregroundColor(.white.opacity(0.7))

                                Text("Mascot Coming Soon")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .offset(y: mascotFloating ? -8 : 8)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: mascotFloating
                    )
                }
                .frame(height: 320)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appeared)

                Spacer()

                // MARK: - Section Title
                Text("Choose Upload Method")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: appeared)

                // MARK: - Glass Circle Buttons
                HStack(spacing: 20) {
                    GlassCircleButton(icon: "camera", label: "Camera") {
                        viewModel.startCamera()
                    }

                    GlassCircleButton(icon: "photo.on.rectangle", label: "Photos") {
                        viewModel.startGallery()
                    }

                    GlassCircleButton(icon: "doc.text", label: "File") {
                        viewModel.startDocumentPicker()
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 140)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: appeared)
            }
        }
        .navigationTitle("Full Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            withAnimation {
                appeared = true
            }
            mascotFloating = true
        }
        // Present sheets
        .sheet(isPresented: $viewModel.showCamera) {
            ImagePicker(sourceType: .camera) { image in
                viewModel.handleImageSelected(image)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.showGallery) {
            ImagePicker(sourceType: .photoLibrary) { image in
                viewModel.handleImageSelected(image)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.showDocumentPicker) {
            DocumentPicker { url in
                viewModel.handleDocumentSelected(url)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $viewModel.showScanUploadFlow) {
            ScanUploadFlowView(
                preselectedImage: viewModel.selectedImage,
                fileData: viewModel.selectedFileData,
                fileName: viewModel.selectedFileName,
                onComplete: {
                    viewModel.showScanUploadFlow = false
                    viewModel.handleUploadComplete()
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Glass Circle Button

private struct GlassCircleButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            ZStack {
                // Outer filled circle (larger, lower opacity, soft edge)
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 0.5)

                // Inner filled circle (more opaque)
                Circle()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 65, height: 65)

                // Content stack (icon + label inside)
                VStack(spacing: 4) {
                    // Icon - positioned slightly higher
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.white)
                        .offset(y: -2)

                    // Label inside the circle - more readable
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .tracking(0.5)
                        .foregroundColor(.white)
                }
                .offset(y: 2)
            }
            .shadow(color: .white.opacity(0.08), radius: 10, x: 0, y: 0)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.92))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UploadMethodSelectionView(viewModel: UploadViewModel())
    }
}
