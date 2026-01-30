//
//  UploadMethodSelectionView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

/// Compact, no-scroll view for selecting an upload method for full bill analysis
/// Follows industry best practices (Spotify, Duolingo, Headspace patterns)
struct UploadMethodSelectionView: View {
    @ObservedObject var viewModel: UploadViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Compact Hero Section
            VStack(spacing: 8) {
                // Gradient icon
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.billixChartBlue, .billixMoneyGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)

                Text("Upload for Full Analysis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.billixDarkGreen)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)
            }
            .padding(.top, 16)

            // MARK: - Upload Method Buttons (Horizontal Row) - NOW ON TOP
            VStack(spacing: 12) {
                Text("Choose upload method")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
                    .textCase(.uppercase)
                    .tracking(0.5)

                HStack(spacing: 10) {
                    UploadMethodButton(
                        icon: "camera.fill",
                        label: "Camera",
                        color: .buttonCamera
                    ) {
                        viewModel.startCamera()
                    }

                    UploadMethodButton(
                        icon: "photo.fill",
                        label: "Photos",
                        color: .buttonGallery
                    ) {
                        viewModel.startGallery()
                    }

                    UploadMethodButton(
                        icon: "doc.fill",
                        label: "File",
                        color: .buttonDocument
                    ) {
                        viewModel.startDocumentPicker()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)

            // MARK: - Benefits List (Vertical Stack) - NOW ON BOTTOM
            VStack(spacing: 0) {
                BenefitRow(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    title: "Spot hidden fees",
                    subtitle: "Find charges you didn't know about"
                )

                Divider().padding(.leading, 52)

                BenefitRow(
                    icon: "list.bullet.rectangle.portrait",
                    iconColor: .billixChartBlue,
                    title: "See every charge",
                    subtitle: "Line-by-line breakdown of your bill"
                )

                Divider().padding(.leading, 52)

                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .purple,
                    title: "Track your usage",
                    subtitle: "Understand patterns over time"
                )

                Divider().padding(.leading, 52)

                BenefitRow(
                    icon: "dollarsign.circle.fill",
                    iconColor: .billixMoneyGreen,
                    title: "Get savings tips",
                    subtitle: "Personalized ways to lower your bill"
                )
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
            )
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: appeared)

            Spacer()
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "#90EE90").opacity(0.4), Color.white],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Full Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation {
                appeared = true
            }
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

// MARK: - Benefit Row (List Item with Icon, Title, Subtitle)

private struct BenefitRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 14) {
            // Icon in colored circle with animation
            ZStack {
                // Pulsing background
                Circle()
                    .fill(iconColor.opacity(0.08))
                    .frame(width: 44, height: 44)
                    .scaleEffect(isAnimating ? 1.15 : 1.0)
                    .opacity(isAnimating ? 0 : 0.6)

                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.billixMediumGreen)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .onAppear {
            // Stagger the animation start
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 0...0.5) * 1_000_000_000))
                isAnimating = true
            }
        }
    }
}

// MARK: - Upload Method Button (Compact Square Button)

private struct UploadMethodButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .shadow(color: color.opacity(0.35), radius: 6, y: 3)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.96))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UploadMethodSelectionView(viewModel: UploadViewModel())
    }
}
