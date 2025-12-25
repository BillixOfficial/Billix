//
//  UploadHubView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//  Redesigned with clean, modern flat design
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

    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 16
    static let shadowColor = Color.black.opacity(0.03)
    static let shadowRadius: CGFloat = 8
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
        HStack(spacing: 14) {
            // Clean flat icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.accentLight)
                    .frame(width: 48, height: 48)

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.accent)
            }

            Text("Upload Your Bills")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.primaryText)

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
    }

    // MARK: - Quick Add Card (Clean flat design)

    private var quickAddCard: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                viewModel.startQuickAdd()
            }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            HStack(spacing: 16) {
                // Left side - Icon and info
                HStack(spacing: 14) {
                    // Icon badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.warning.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.warning)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Quick Add")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.primaryText)

                            // Info button
                            Button {
                                showQuickAddInfo.toggle()
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.secondaryText)
                            }
                            .popover(isPresented: $showQuickAddInfo, arrowEdge: .top) {
                                QuickAddInfoPopover()
                                    .presentationCompactAdaptation(.popover)
                            }
                        }

                        Text("Answer 3 questions for rate comparison")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.secondaryText)
                    }
                }

                Spacer()

                // Right side - CTA
                HStack(spacing: 6) {
                    Text("Start")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.accent)
                .cornerRadius(10)
            }
            .padding(16)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.border, lineWidth: 1)
            )
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
                // Empty state card
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        EmptyUploadCard()
                        EmptyUploadCard(isSecondary: true)
                    }
                    .padding(.horizontal, Theme.horizontalPadding)
                }
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
                    .font(.system(size: 17, weight: .semibold))
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
                VStack(spacing: 16) {
                    // Top row: Icon + Text
                    HStack(spacing: 14) {
                        // Icon with colored background
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.info.opacity(0.12))
                                .frame(width: 44, height: 44)

                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Theme.info)
                        }

                        // Simplified text content
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upload for Full Analysis")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.primaryText)

                            Text("Get a complete breakdown of your bill")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.secondaryText)
                        }

                        Spacer()
                    }

                    // CTA Button
                    HStack(spacing: 8) {
                        Text("Start Analysis")
                            .font(.system(size: 15, weight: .semibold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.info)
                    .cornerRadius(12)
                }
                .padding(16)
                .background(Theme.cardBackground)
                .cornerRadius(Theme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.border, lineWidth: 1)
                )
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
        VStack(alignment: .leading, spacing: 10) {
            // Category/source label with Quick Add badge
            HStack(spacing: 5) {
                if upload.source == .quickAdd {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                        .foregroundColor(warningColor)
                }
                Text(upload.source.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryText)
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
                .foregroundColor(primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            // Amount and status
            HStack {
                Text(upload.formattedAmount)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(primaryText)

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
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var sourceBackgroundColor: Color {
        upload.source == .quickAdd
            ? warningColor.opacity(0.12)
            : accentColor.opacity(0.08)
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
    var isSecondary: Bool = false

    private let primaryText = Color(hex: "#2D3B35")
    private let secondaryText = Color(hex: "#8B9A94")
    private let tertiaryText = Color(hex: "#A8B5AE")
    private let infoColor = Color(hex: "#5BA4D4")
    private let borderColor = Color(hex: "#E5EAE7")

    var body: some View {
        if isSecondary {
            // Second card - guide to options above
            VStack(spacing: 10) {
                Spacer()

                // Icon representing options
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 32))
                    .foregroundColor(infoColor.opacity(0.6))

                // Guide user to CTAs above
                Text("Ready to Start?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)
                    .multilineTextAlignment(.center)

                Text("Choose an option above")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(14)
            .frame(width: 150, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                infoColor.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 3])
                            )
                    )
            )
        } else {
            // First card - explain what will appear here
            VStack(spacing: 10) {
                Spacer()

                // Icon representing empty/waiting
                Image(systemName: "tray")
                    .font(.system(size: 32))
                    .foregroundColor(tertiaryText)

                // Informational message
                Text("No Bills Yet")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)
                    .multilineTextAlignment(.center)

                Text("Your uploads will show here")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(14)
            .frame(width: 150, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                borderColor,
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 3])
                            )
                    )
            )
        }
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
