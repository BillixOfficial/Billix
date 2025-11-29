//
//  UploadHubView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//  Redesigned with Figma-inspired task management layout
//

import SwiftUI
import SwiftData

/// Upload Hub with Figma-inspired design
/// - Header with greeting
/// - Hero progress card with CTA
/// - Horizontal "In Progress" section
/// - Vertical upload methods list with progress circles
struct UploadHubView: View {

    @StateObject private var viewModel = UploadViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var appeared = false
    @State private var fullAnalysisTapped = false
    @State private var showFullAnalysisInfo = false
    @State private var showQuickAddInfo = false
    @State private var infoPulse = false
    @State private var quickAddInfoPulse = false
    @State private var navigateToUploadMethods = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background matching Home screen
                Color.billixLightGreen
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // SECTION 1: Header
                        headerSection
                            .padding(.horizontal, 20)

                        // SECTION 2: Hero Progress Card (Quick Add)
                        heroProgressCard
                            .padding(.horizontal, 20)

                        // SECTION 3: Recent Uploads - Horizontal scroll
                        inProgressSection

                        // SECTION 4: Upload for Full Analysis - Single card
                        fullAnalysisCard
                            .padding(.horizontal, 20)

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToUploadMethods) {
                UploadMethodSelectionView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
            Task {
                await viewModel.loadRecentUploads()
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .sheet(isPresented: $viewModel.showQuickAddFlow) {
            QuickAddFlowView(
                onComplete: {
                    viewModel.dismissFlows()
                    viewModel.handleUploadComplete()
                },
onSwitchToFullAnalysis: {
                    // Dismiss Quick Add and navigate to upload method selection after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToUploadMethods = true
                    }
                }
            )
        }
        .sheet(isPresented: $viewModel.showScanUploadFlow) {
            ScanUploadFlowView(
                preselectedImage: viewModel.selectedImage,
                fileData: viewModel.selectedFileData,
                fileName: viewModel.selectedFileName,
                onComplete: {
                    viewModel.dismissFlows()
                    viewModel.handleUploadComplete()
                }
            )
        }
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
        .sheet(item: $viewModel.selectedUpload) { upload in
            if let bill = viewModel.findStoredBill(for: upload.id) {
                UploadDetailView(upload: upload, storedBill: bill)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 14) {
            // Avatar circle with icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.billixMoneyGreen, Color.billixMoneyGreen.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Upload Your Bills")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.billixDarkGreen)

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
    }

    // MARK: - Hero Progress Card (Figma style)

    private var heroProgressCard: some View {
        ZStack {
            // Gradient background like Figma
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.billixMoneyGreen,
                            Color.billixMoneyGreen.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Decorative circles in background (like Figma)
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 120, height: 120)
                .offset(x: 80, y: -30)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 80, height: 80)
                .offset(x: 100, y: 40)

            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Quick Add a Bill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        // Info button with pulsing ring animation
                        ZStack {
                            // Single pulsing ring
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                .frame(width: 28, height: 28)
                                .scaleEffect(quickAddInfoPulse ? 1.3 : 1.0)
                                .opacity(quickAddInfoPulse ? 0 : 1)
                                .animation(.easeOut(duration: 2.5).repeatForever(autoreverses: false), value: quickAddInfoPulse)

                            // Info button
                            Button {
                                showQuickAddInfo.toggle()
                            } label: {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .shadow(color: .white.opacity(0.3), radius: 4)
                            }
                            .scaleEffect(quickAddInfoPulse ? 1.08 : 1.0)
                            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: quickAddInfoPulse)
                            .popover(isPresented: $showQuickAddInfo, arrowEdge: .top) {
                                QuickAddInfoPopover()
                                    .presentationCompactAdaptation(.popover)
                            }
                        }
                        .onAppear {
                            quickAddInfoPulse = true
                        }
                    }

                    Text("3 questions for rate comparison")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))

                    // CTA Button - Only this triggers the flow
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            viewModel.startQuickAdd()
                        }
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Start Now")
                                .font(.system(size: 14, weight: .semibold))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.billixMoneyGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle(scale: 0.95))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Arrow indicator - Also triggers the flow
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.startQuickAdd()
                    }
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 44, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.9))
                .padding(.trailing, 8)
            }
            .padding(20)
        }
        .frame(height: 160)
        .shadow(color: .billixMoneyGreen.opacity(0.3), radius: 20, x: 0, y: 10)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
    }

    // MARK: - In Progress Section (Horizontal scroll)

    private var inProgressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Uploads")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                // Decorative dot
                Circle()
                    .fill(Color.billixSavingsYellow)
                    .frame(width: 8, height: 8)

                Spacer()

                // View All button
                if !viewModel.recentUploads.isEmpty {
                    NavigationLink(destination: AllUploadsView()) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.billixChartBlue)
                    }
                }

                if viewModel.isLoadingRecent {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.billixMoneyGreen)
                }
            }
            .padding(.horizontal, 20)

            if viewModel.recentUploads.isEmpty {
                // Empty state card
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        EmptyUploadCard()
                        EmptyUploadCard(isSecondary: true)
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.recentUploads.prefix(4)) { upload in
                            Button {
                                viewModel.selectedUpload = upload
                            } label: {
                                RecentUploadCard(upload: upload)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: appeared)
    }

    // MARK: - Full Analysis Card (Navigation to upload method selection)

    private var fullAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Full Analysis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                // Info button with pulsing ring animation
                ZStack {
                    // Single pulsing ring
                    Circle()
                        .stroke(Color.billixChartBlue.opacity(0.5), lineWidth: 2)
                        .frame(width: 28, height: 28)
                        .scaleEffect(infoPulse ? 1.3 : 1.0)
                        .opacity(infoPulse ? 0 : 1)
                        .animation(.easeOut(duration: 2.5).repeatForever(autoreverses: false), value: infoPulse)

                    // Info button with subtle pulse
                    Button {
                        showFullAnalysisInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.billixChartBlue)
                            .shadow(color: .billixChartBlue.opacity(0.3), radius: 4)
                    }
                    .scaleEffect(infoPulse ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: infoPulse)
                    .popover(isPresented: $showFullAnalysisInfo, arrowEdge: .top) {
                        FullAnalysisInfoPopover()
                            .presentationCompactAdaptation(.popover)
                    }
                }
                .onAppear {
                    infoPulse = true
                }
            }

            NavigationLink(destination: UploadMethodSelectionView(viewModel: viewModel)) {
                VStack(spacing: 16) {
                    // Top row: Icon + Text
                    HStack(spacing: 14) {
                        // Icon with colored background
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.billixChartBlue.opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.billixChartBlue)
                        }

                        // Simplified text content (checkpoints moved to next screen)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upload for Full Analysis")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.billixDarkGreen)

                            Text("Get a complete breakdown of your bill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.billixMediumGreen)
                        }

                        Spacer()
                    }

                    // Explicit CTA Button - makes the action crystal clear
                    HStack(spacing: 8) {
                        Text("Start Analysis")
                            .font(.system(size: 15, weight: .semibold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.billixChartBlue, .billixChartBlue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .billixChartBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                        .shadow(color: .billixChartBlue.opacity(0.08), radius: 16, x: 0, y: 8)
                )
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.97))
            .simultaneousGesture(TapGesture().onEnded {
                fullAnalysisTapped.toggle()
            })
            .sensoryFeedback(.impact(weight: .medium), trigger: fullAnalysisTapped)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: appeared)
    }
}

// MARK: - Upload Method Row (Figma Task Group style)

struct UploadMethodRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                }

                Spacer()

                // Chevron arrow indicating tappable action
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
}

// MARK: - Recent Upload Card (Horizontal scroll card)

struct RecentUploadCard: View {
    let upload: RecentUpload

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Category/source label with Quick Add badge
            HStack(spacing: 6) {
                if upload.source == .quickAdd {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.billixMoneyGreen)
                }
                Text(upload.source.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(sourceBackgroundColor)
            )

            // Provider name
            Text(upload.provider)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            // Amount and status
            HStack {
                Text(upload.formattedAmount)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Image(systemName: upload.status.icon)
                    .font(.system(size: 12))
                    .foregroundColor(statusColor(for: upload.status))
            }
        }
        .padding(14)
        .frame(width: 150, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }

    private var sourceBackgroundColor: Color {
        upload.source == .quickAdd
            ? Color.billixMoneyGreen.opacity(0.15)
            : Color.billixMoneyGreen.opacity(0.1)
    }

    private func statusColor(for status: UploadStatus) -> Color {
        switch status {
        case .processing: return .orange
        case .analyzed: return .billixMoneyGreen
        case .needsConfirmation: return .billixSavingsYellow
        case .failed: return .red
        }
    }
}

// MARK: - Empty Upload Card

struct EmptyUploadCard: View {
    var isSecondary: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isSecondary ? "Personal" : "Get Started")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.billixMediumGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSecondary ? Color.buttonDocument.opacity(0.1) : Color.billixMoneyGreen.opacity(0.1))
                )

            Text(isSecondary ? "Add your first bill" : "Upload a bill to begin")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
                .lineLimit(2)

            Spacer()

            // Empty progress bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.billixMoneyGreen.opacity(0.2))
                .frame(height: 4)
        }
        .padding(14)
        .frame(width: 150, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Feature Checkpoint (small checkmark + text)

struct FeatureCheckpoint: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.billixMoneyGreen)

            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.billixMediumGreen)
        }
    }
}

// MARK: - Full Analysis Info Popover

struct FullAnalysisInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            Text("What You'll Get")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.billixDarkGreen)

            // Compact features list
            VStack(alignment: .leading, spacing: 6) {
                InfoFeatureRow(icon: "list.bullet.rectangle.portrait", text: "Line-by-line breakdown")
                InfoFeatureRow(icon: "map", text: "Area rate comparison")
                InfoFeatureRow(icon: "dollarsign.circle", text: "Savings opportunities")
                InfoFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Usage insights")
            }
        }
        .padding(12)
        .frame(width: 200)
        .background(Color.white)
    }
}

struct QuickAddInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            Text("About Quick Add")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.billixDarkGreen)

            // Structured features list
            VStack(alignment: .leading, spacing: 6) {
                InfoFeatureRow(icon: "bolt.fill", text: "Just 30 seconds")
                InfoFeatureRow(icon: "photo.badge.arrow.down.fill", text: "No upload needed")
                InfoFeatureRow(icon: "list.number", text: "3 simple questions")
                InfoFeatureRow(icon: "chart.bar.fill", text: "Rate comparison only")
            }

            // Clarification note
            Text("Note: For full analysis, use Full Analysis option")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.billixMediumGreen)
                .padding(.top, 4)
        }
        .padding(12)
        .frame(width: 210)
        .background(Color.white)
    }
}

struct InfoFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.billixChartBlue)
                .frame(width: 16)

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.billixDarkGreen)
        }
    }
}

// MARK: - Preview

#Preview {
    UploadHubView()
        .modelContainer(for: StoredBill.self, inMemory: true)
}
