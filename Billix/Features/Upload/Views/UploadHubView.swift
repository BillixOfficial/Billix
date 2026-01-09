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
                // Background matching Explore screen
                LinearGradient(
                    colors: [Color(hex: "#90EE90").opacity(0.4), Color.white],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {

                        // SECTION 1: Header
                        headerSection
                            .padding(.horizontal, Theme.horizontalPadding)

                        // SECTION 2: Quick Add Card (Redesigned)
                        quickAddCard

                        // SECTION 3: Recent Uploads - Horizontal scroll
                        inProgressSection

                        // SECTION 4: Upload for Full Analysis - Single card
                        fullAnalysisCard
                            .padding(.bottom, 24)
                    }
                    .padding(.top, 20)
                }
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Upload Your Bills")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Theme.primaryText)

            // Bill Review button
            Button {
                // Action TBD
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Bill Review")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Color(hex: "#8B6914"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(hex: "#F5E6D3"))
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
    }

    // MARK: - Quick Add Card (Clean White Card Design)

    private var quickAddCard: some View {
        VStack(spacing: 14) {
            // Icon and text - horizontal layout
            HStack(spacing: 16) {
                // Green lightning icon in circle (left side)
                ZStack {
                    Circle()
                        .fill(Color(hex: "#E8F5E9"))
                        .frame(width: 50, height: 50)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "#5B8A6B"))
                }

                // Title and subtitle (left-aligned)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Add")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.primaryText)

                    Text("Answer 3 Questions")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()
            }

            // Full-width button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    viewModel.startQuickAdd()
                }
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } label: {
                HStack {
                    Text("Start Quick Add")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#5B8A6B"))
                )
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
    }

    // MARK: - In Progress Section (Horizontal scroll)

    private var inProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Clipboard icon
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#8B9A94"))

                Text("RECENT UPLOADS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .tracking(0.5)

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
                EmptyUploadCard()
                    .padding(.horizontal, 20)
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

    // MARK: - Full Analysis Card (Clean White Card Design)

    private var fullAnalysisCard: some View {
        VStack(spacing: 12) {
            // Magnifying glass icon with triple circle background
            ZStack {
                // Outer largest light circle
                Circle()
                    .fill(Color(hex: "#E8F5E9").opacity(0.25))
                    .frame(width: 90, height: 90)

                // Middle circle
                Circle()
                    .fill(Color(hex: "#E8F5E9").opacity(0.4))
                    .frame(width: 68, height: 68)

                // Inner green circle
                Circle()
                    .fill(Color(hex: "#E8F5E9"))
                    .frame(width: 50, height: 50)

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(Color(hex: "#6B7280"))
            }

            // Title
            Text("Analyze a New Bill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.primaryText)
                .multilineTextAlignment(.center)

            // Description - full text, no truncation
            Text("Upload a bill to find savings, track expenses, and get insights.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)

            // Inline pills with individual colors
            HStack(spacing: 6) {
                ColoredPillTag(text: "Line Items", backgroundColor: Color(hex: "#E9D5FF"))
                ColoredPillTag(text: "Surprises", backgroundColor: Color(hex: "#DBEAFE"))
                ColoredPillTag(text: "Rate compare", backgroundColor: Color(hex: "#FED7AA"))
                ColoredPillTag(text: "Savings", backgroundColor: Color(hex: "#FED7AA"))
            }

            // Full-width button
            NavigationLink(destination: UploadMethodSelectionView(viewModel: viewModel)) {
                HStack {
                    Text("Start Analysis")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#5B8A6B"))
                )
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
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

// MARK: - Empty Upload Card (White Card Container)

struct EmptyUploadCard: View {
    private let primaryText = Color(hex: "#2D3B35")
    private let secondaryText = Color(hex: "#8B9A94")

    var body: some View {
        HStack(spacing: 16) {
            // VaultEmpty PNG image - scaledToFit with fixed frame
            Image("VaultEmpty")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            VStack(alignment: .leading, spacing: 4) {
                Text("Your vault is empty.")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryText)

                Text("Add a bill to start tracking.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(secondaryText)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .frame(maxWidth: .infinity)
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

// MARK: - Floating Label Component

struct FloatingLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(hex: "#5BA4D4"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
    }
}

// MARK: - Pill Tag Component

struct PillTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color(hex: "#6B7280"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(hex: "#F3F4F6"))
            )
    }
}

// MARK: - Colored Pill Tag Component

struct ColoredPillTag: View {
    let text: String
    let backgroundColor: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(Color(hex: "#6B7280"))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
    }
}

// MARK: - Preview

#Preview {
    UploadHubView()
        .modelContainer(for: StoredBill.self, inMemory: true)
}
