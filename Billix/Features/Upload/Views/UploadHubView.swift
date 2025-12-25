//
//  UploadHubView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//  Redesigned with engaging, modern design
//

import SwiftUI
import SwiftData

// MARK: - Theme (Consistent with HomeView)

private enum Theme {
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let tertiaryText = Color(hex: "#A8B5AE")
    static let accent = Color(hex: "#5B8A6B")
    static let accentLight = Color(hex: "#5B8A6B").opacity(0.08)
    static let border = Color(hex: "#E5EAE7")
    static let divider = Color(hex: "#F0F3F1")
    static let info = Color(hex: "#5BA4D4")
    static let warning = Color(hex: "#E8A54B")
    static let warmGradientStart = Color(hex: "#FEF3E2")
    static let warmGradientEnd = Color(hex: "#FDE9D0")
    static let coolGradientStart = Color(hex: "#E8F4FD")
    static let coolGradientEnd = Color(hex: "#D6ECFA")

    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 20
    static let shadowColor = Color.black.opacity(0.06)
    static let shadowRadius: CGFloat = 12
}

/// Upload Hub with clean, modern design
struct UploadHubView: View {

    @StateObject private var viewModel = UploadViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredBill.uploadDate, order: .reverse) private var storedBills: [StoredBill]
    @State private var appeared = false
    @State private var fullAnalysisTapped = false
    @State private var showFullAnalysisInfo = false
    @State private var showQuickAddInfo = false
    @State private var infoPulse = false
    @State private var quickAddInfoPulse = false
    @State private var navigateToUploadMethods = false
    @State private var refreshTrigger = UUID()

    // Derive recent uploads from SwiftData query (auto-updates on changes)
    private var recentUploads: [RecentUpload] {
        storedBills.prefix(4).compactMap { $0.toRecentUpload() }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background matching Home screen
                Theme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // SECTION 1: Header
                        headerSection
                            .padding(.horizontal, Theme.horizontalPadding)

                        // SECTION 2: Quick Add Card (Redesigned)
                        quickAddCard
                            .padding(.horizontal, Theme.horizontalPadding)

                        // SECTION 3: Recent Uploads - Horizontal scroll
                        inProgressSection

                        // SECTION 4: Upload for Full Analysis - Single card
                        fullAnalysisCard
                            .padding(.horizontal, Theme.horizontalPadding)

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
            // Force refresh when view appears
            refreshTrigger = UUID()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .task(id: refreshTrigger) {
            // Task runs when refreshTrigger changes, causing view to re-render with latest @Query data
            // Note: We now use @Query directly, so no need to manually load data
            // Just triggering this task causes a refresh of the SwiftData query
        }
        .sheet(isPresented: $viewModel.showQuickAddFlow) {
            QuickAddFlowView(
                onComplete: {
                    viewModel.dismissFlows()
                    // Trigger refresh to show new upload
                    refreshTrigger = UUID()
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
                    // Trigger refresh to show new upload
                    refreshTrigger = UUID()
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
        .onChange(of: viewModel.selectedUpload) { oldValue, newValue in
            // Refresh uploads when detail sheet is dismissed
            if oldValue != nil && newValue == nil {
                refreshTrigger = UUID()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Animated icon badge with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.15), Theme.accent.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Upload Your Bills")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Theme.primaryText)

                    Text("Track expenses & find savings")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
    }

    // MARK: - Quick Add Card (Engaging gradient design)

    private var quickAddCard: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                viewModel.startQuickAdd()
            }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            ZStack {
                // Warm gradient background
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [Theme.warmGradientStart, Theme.warmGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Decorative circles
                GeometryReader { geo in
                    Circle()
                        .fill(Theme.warning.opacity(0.08))
                        .frame(width: 100, height: 100)
                        .offset(x: geo.size.width - 60, y: -30)

                    Circle()
                        .fill(Theme.warning.opacity(0.05))
                        .frame(width: 60, height: 60)
                        .offset(x: geo.size.width - 100, y: geo.size.height - 40)
                }
                .clipped()

                // Content
                HStack(spacing: 16) {
                    // Left side - Icon and info
                    HStack(spacing: 14) {
                        // Icon badge with shadow
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                                .shadow(color: Theme.warning.opacity(0.2), radius: 8, x: 0, y: 4)

                            Image(systemName: "bolt.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Theme.warning)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Quick Add")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Theme.primaryText)

                                // Info button
                                Button {
                                    showQuickAddInfo.toggle()
                                } label: {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.secondaryText.opacity(0.8))
                                }
                                .popover(isPresented: $showQuickAddInfo, arrowEdge: .top) {
                                    QuickAddInfoPopover()
                                        .presentationCompactAdaptation(.popover)
                                }
                            }

                            Text("Answer 3 questions for rate comparison")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.secondaryText)
                        }
                    }

                    Spacer()

                    // Right side - CTA with gradient
                    HStack(spacing: 6) {
                        Text("Start")
                            .font(.system(size: 14, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#E8A54B"), Color(hex: "#D4943E")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Theme.warning.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(18)
            }
            .frame(height: 90)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
    }

    // MARK: - In Progress Section (Horizontal scroll)

    private var inProgressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Uploads")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                // Decorative dot
                Circle()
                    .fill(Theme.warning)
                    .frame(width: 8, height: 8)

                Spacer()

                // View All button
                if !recentUploads.isEmpty {
                    NavigationLink(destination: AllUploadsView()) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Theme.info)
                    }
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)

            if recentUploads.isEmpty {
                // Single empty state card
                HStack {
                    EmptyUploadCard()
                    Spacer()
                }
                .padding(.horizontal, Theme.horizontalPadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(recentUploads) { upload in
                            Button {
                                viewModel.selectedUpload = upload
                            } label: {
                                RecentUploadCard(upload: upload)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, Theme.horizontalPadding)
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
            HStack(spacing: 6) {
                Text("Full Analysis")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.primaryText)

                // Info button
                Button {
                    showFullAnalysisInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondaryText)
                }
                .popover(isPresented: $showFullAnalysisInfo, arrowEdge: .top) {
                    FullAnalysisInfoPopover()
                        .presentationCompactAdaptation(.popover)
                }
            }

            NavigationLink(destination: UploadMethodSelectionView(viewModel: viewModel)) {
                ZStack {
                    // Cool gradient background
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [Theme.coolGradientStart, Theme.coolGradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Decorative elements
                    GeometryReader { geo in
                        Circle()
                            .fill(Theme.info.opacity(0.08))
                            .frame(width: 120, height: 120)
                            .offset(x: geo.size.width - 70, y: -40)

                        Circle()
                            .fill(Theme.info.opacity(0.05))
                            .frame(width: 80, height: 80)
                            .offset(x: -20, y: geo.size.height - 50)
                    }
                    .clipped()

                    VStack(spacing: 16) {
                        // Top row: Icon + Text + Ready badge
                        HStack(spacing: 14) {
                            // Icon with white background and shadow
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                    .shadow(color: Theme.info.opacity(0.2), radius: 8, x: 0, y: 4)

                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Theme.info)
                            }

                            // Text content
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upload for Full Analysis")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.primaryText)

                                Text("Get a complete breakdown of your bill")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.secondaryText)
                            }

                            Spacer()

                            // Ready to Start badge
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 36, height: 36)
                                        .shadow(color: Theme.info.opacity(0.15), radius: 4, x: 0, y: 2)

                                    Image(systemName: "hand.tap.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.info)
                                }

                                Text("Ready?")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.info)
                            }
                        }

                        // Feature pills
                        HStack(spacing: 8) {
                            FeaturePill(icon: "chart.bar.fill", text: "Line items")
                            FeaturePill(icon: "map.fill", text: "Rate compare")
                            FeaturePill(icon: "lightbulb.fill", text: "Savings")
                        }

                        // CTA Button with gradient
                        HStack(spacing: 8) {
                            Text("Start Analysis")
                                .font(.system(size: 15, weight: .bold))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#5BA4D4"), Color(hex: "#4A93C3")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Theme.info.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .padding(18)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))
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

// MARK: - Feature Pill

struct FeaturePill: View {
    let icon: String
    let text: String

    private let infoColor = Color(hex: "#5BA4D4")
    private let primaryText = Color(hex: "#2D3B35")

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(infoColor)

            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(primaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
    }
}

// MARK: - Upload Method Row

struct UploadMethodRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    private let primaryText = Color(hex: "#2D3B35")
    private let secondaryText = Color(hex: "#8B9A94")
    private let borderColor = Color(hex: "#E5EAE7")

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(primaryText)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryText)
                }

                Spacer()

                // Chevron arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(secondaryText)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
}

// MARK: - Recent Upload Card (Horizontal scroll card)

struct RecentUploadCard: View {
    let upload: RecentUpload

    private let accentColor = Color(hex: "#5B8A6B")
    private let primaryText = Color(hex: "#2D3B35")
    private let secondaryText = Color(hex: "#8B9A94")
    private let warningColor = Color(hex: "#E8A54B")
    private let borderColor = Color(hex: "#E5EAE7")

    var body: some View {
        ZStack {
            // White card background
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)

            // Subtle top accent bar
            VStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [sourceAccentColor.opacity(0.15), sourceAccentColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 50)

                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 8) {
                // Category/source label with Quick Add badge
                HStack(spacing: 5) {
                    if upload.source == .quickAdd {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(warningColor)
                    }
                    Text(upload.source.displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(sourceAccentColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: sourceAccentColor.opacity(0.15), radius: 4, x: 0, y: 2)
                )

                // Provider name
                Text(upload.provider)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Amount and status
                HStack {
                    Text(upload.formattedAmount)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(primaryText)

                    Spacer()

                    // Status indicator with background
                    ZStack {
                        Circle()
                            .fill(statusColor(for: upload.status).opacity(0.12))
                            .frame(width: 26, height: 26)

                        Image(systemName: upload.status.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(statusColor(for: upload.status))
                    }
                }
            }
            .padding(14)
        }
        .frame(width: 155, height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var sourceAccentColor: Color {
        upload.source == .quickAdd ? warningColor : accentColor
    }

    private func statusColor(for status: UploadStatus) -> Color {
        switch status {
        case .processing: return .orange
        case .analyzed: return accentColor
        case .needsConfirmation: return warningColor
        case .failed: return .red
        }
    }
}

// MARK: - Empty Upload Card

struct EmptyUploadCard: View {
    private let primaryText = Color(hex: "#2D3B35")
    private let secondaryText = Color(hex: "#8B9A94")
    private let tertiaryText = Color(hex: "#A8B5AE")
    private let accentColor = Color(hex: "#5B8A6B")

    var body: some View {
        ZStack {
            // Subtle gradient background
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F7F9F8"), Color(hex: "#F0F3F1")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Decorative circles
            Circle()
                .fill(accentColor.opacity(0.04))
                .frame(width: 80, height: 80)
                .offset(x: 60, y: -30)

            Circle()
                .fill(accentColor.opacity(0.03))
                .frame(width: 50, height: 50)
                .offset(x: -50, y: 40)

            HStack(spacing: 14) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)

                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(tertiaryText)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("No Bills Yet")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(primaryText)

                    Text("Upload a bill to get started")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryText)
                }

                Spacer()
            }
            .padding(16)
        }
        .frame(height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: "#E5EAE7").opacity(0.6), lineWidth: 1)
        )
    }
}

// MARK: - Feature Checkpoint (small checkmark + text)

struct FeatureCheckpoint: View {
    let text: String

    private let accentColor = Color(hex: "#5B8A6B")
    private let secondaryText = Color(hex: "#8B9A94")

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(accentColor)

            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(secondaryText)
        }
    }
}

// MARK: - Full Analysis Info Popover

struct FullAnalysisInfoPopover: View {
    private let primaryText = Color(hex: "#2D3B35")

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            Text("What You'll Get")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(primaryText)

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
    private let primaryText = Color(hex: "#2D3B35")
    private let secondaryText = Color(hex: "#8B9A94")

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            Text("About Quick Add")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(primaryText)

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
                .foregroundColor(secondaryText)
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

    private let infoColor = Color(hex: "#5BA4D4")
    private let primaryText = Color(hex: "#2D3B35")

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(infoColor)
                .frame(width: 16)

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(primaryText)
        }
    }
}

// MARK: - Preview

#Preview {
    UploadHubView()
        .modelContainer(for: StoredBill.self, inMemory: true)
}
