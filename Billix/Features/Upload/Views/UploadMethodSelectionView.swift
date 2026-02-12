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

    // Coin bounce animation (starts at top so first move is dropping into piggy)
    @State private var coinAtTop = true

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

                // MARK: - Mascot Character
                ZStack {
                    // Outer glass ring (larger, lower opacity)
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 300, height: 300)
                        .blur(radius: 0.5)

                    // Inner glass ring (more opaque)
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 220, height: 220)

                    // Glow effect behind mascot
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 120
                            )
                        )
                        .frame(width: 220, height: 220)
                        .blur(radius: 15)

                    // Piggy mascot with coin
                    VStack(spacing: -8) {
                        // Coin dropping in
                        Image("CoinInsert")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                            .offset(x: 0, y: 80 + (coinAtTop ? -20 : 65))
                            .animation(
                                .easeInOut(duration: 1.5),
                                value: coinAtTop
                            )

                        // Piggy
                        Image("HoloPiggy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 420, height: 420)
                            .offset(x: 0, y: -50)
                    }
                    .offset(y: mascotFloating ? -6 : 6)
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
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(2.0)
                    .textCase(.uppercase)
                    .foregroundColor(.billixDarkGreen.opacity(0.7))
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 3) {
                    Text("Full Analysis")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                    Text("Start Saving Now")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                }
                .offset(x: 2, y: 30)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            withAnimation {
                appeared = true
            }
            mascotFloating = true
            // Coin insert bounce animation (common mode so it runs during scrolling)
            let timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 1.5)) {
                    coinAtTop.toggle()
                }
            }
            RunLoop.current.add(timer, forMode: .common)
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
                        .foregroundColor(.billixDarkGreen)
                        .offset(y: -2)

                    // Label inside the circle - darker for readability
                    Text(label)
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.billixDarkGreen)
                }
                .offset(y: 2)
            }
            .shadow(color: .white.opacity(0.08), radius: 10, x: 0, y: 0)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.92))
    }
}

// MARK: - Preview

struct UploadMethodSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
        UploadMethodSelectionView(viewModel: UploadViewModel())
        }
    }
}
