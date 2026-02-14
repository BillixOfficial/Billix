//
//  UploadHubView.swift
//  Billix
//
//  Redesigned to match Home page styling
//

import SwiftUI
import SwiftData

/// Upload Hub matching Home page design patterns
struct UploadHubView: View {

    @StateObject private var viewModel = UploadViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredBill.uploadDate, order: .reverse) private var storedBills: [StoredBill]
    @State private var showQuickAddInfo = false
    @State private var showFullAnalysisInfo = false
    @State private var navigateToUploadMethods = false
    @State private var navigateToBillConnection = false
    @State private var refreshTrigger = UUID()

    // Derive recent uploads from SwiftData query
    private var recentUploads: [RecentUpload] {
        storedBills.prefix(3).compactMap { $0.toRecentUpload() }
    }

    private var numberOfAddCards: Int {
        max(0, 4 - recentUploads.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                        .padding(.horizontal, HomeTheme.horizontalPadding)
                        .padding(.top, 12)

                    // Quick Add Zone
                    quickAddZone

                    // Full Analysis Zone
                    fullAnalysisZone

                    // Bill Connection Zone (NEW)
                    billConnectionZone

                    // Recent Uploads Zone
                    recentUploadsZone

                    Spacer().frame(height: 100)
                }
                .padding(.top, 8)
            }
            .background(HomeTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToUploadMethods) {
                UploadMethodSelectionView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $navigateToBillConnection) {
                BillConnectionView()
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
            refreshTrigger = UUID()
        }
        .sheet(isPresented: $viewModel.showQuickAddFlow) {
            QuickAddFlowView(
                onComplete: {
                    viewModel.dismissFlows()
                    refreshTrigger = UUID()
                },
                onSwitchToFullAnalysis: {
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000)
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
            if oldValue != nil && newValue == nil {
                refreshTrigger = UUID()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Upload")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(HomeTheme.primaryText)

                Text("Add bills or request support")
                    .font(.system(size: 14))
                    .foregroundColor(HomeTheme.secondaryText)
            }

            Spacer()

            // Upload count badge
            if !storedBills.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(storedBills.count)")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(HomeTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(HomeTheme.accentLight)
                .cornerRadius(20)
            }
        }
    }

    // MARK: - Quick Add Zone

    private var quickAddZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HomeTheme.warning)

                Text("QUICK ADD")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(HomeTheme.secondaryText)
                    .tracking(0.5)

                Spacer()

                Button {
                    showQuickAddInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(HomeTheme.secondaryText.opacity(0.6))
                }
                .popover(isPresented: $showQuickAddInfo, arrowEdge: .top) {
                    QuickAddInfoPopover()
                        .presentationCompactAdaptation(.popover)
                }
            }
            .padding(.horizontal, HomeTheme.horizontalPadding)

            // Card
            Button {
                haptic(.medium)
                viewModel.startQuickAdd()
            } label: {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(HomeTheme.warning.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(HomeTheme.warning)
                    }

                    // Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Answer 3 Questions")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(HomeTheme.primaryText)

                        Text("30 seconds • No upload needed")
                            .font(.system(size: 13))
                            .foregroundColor(HomeTheme.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(HomeTheme.secondaryText)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: HomeTheme.shadowColor, radius: HomeTheme.shadowRadius, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))
            .padding(.horizontal, HomeTheme.horizontalPadding)
        }
    }

    // MARK: - Full Analysis Zone

    private var fullAnalysisZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HomeTheme.accent)

                Text("FULL ANALYSIS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(HomeTheme.secondaryText)
                    .tracking(0.5)

                Spacer()

                Button {
                    showFullAnalysisInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(HomeTheme.secondaryText.opacity(0.6))
                }
                .popover(isPresented: $showFullAnalysisInfo, arrowEdge: .top) {
                    FullAnalysisInfoPopover()
                        .presentationCompactAdaptation(.popover)
                }
            }
            .padding(.horizontal, HomeTheme.horizontalPadding)

            // Card
            NavigationLink(destination: UploadMethodSelectionView(viewModel: viewModel)) {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(HomeTheme.accent.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(HomeTheme.accent)
                    }

                    // Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upload & Analyze Bill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(HomeTheme.primaryText)

                        Text("Line items • Savings • Insights")
                            .font(.system(size: 13))
                            .foregroundColor(HomeTheme.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(HomeTheme.secondaryText)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: HomeTheme.shadowColor, radius: HomeTheme.shadowRadius, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))
            .padding(.horizontal, HomeTheme.horizontalPadding)
        }
    }

    // MARK: - Bill Connection Zone (NEW)

    private var billConnectionZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HomeTheme.purple)

                Text("BILL CONNECTION")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(HomeTheme.secondaryText)
                    .tracking(0.5)

                Spacer()

                // "New" badge
                Text("NEW")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(HomeTheme.purple)
                    .cornerRadius(4)
            }
            .padding(.horizontal, HomeTheme.horizontalPadding)

            // Card
            NavigationLink(destination: BillConnectionView()) {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(HomeTheme.purple.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(HomeTheme.purple)
                    }

                    // Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Request Bill Support")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(HomeTheme.primaryText)

                        Text("Connect with supporters in your area")
                            .font(.system(size: 13))
                            .foregroundColor(HomeTheme.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(HomeTheme.secondaryText)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: HomeTheme.shadowColor, radius: HomeTheme.shadowRadius, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))
            .padding(.horizontal, HomeTheme.horizontalPadding)
        }
    }

    // MARK: - Recent Uploads Zone

    private var recentUploadsZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HomeTheme.info)

                Text("RECENT UPLOADS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(HomeTheme.secondaryText)
                    .tracking(0.5)

                Spacer()

                if !recentUploads.isEmpty {
                    NavigationLink(destination: AllUploadsView()) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(HomeTheme.info)
                    }
                }
            }
            .padding(.horizontal, HomeTheme.horizontalPadding)

            if recentUploads.isEmpty {
                // Empty state
                emptyUploadsCard
                    .padding(.horizontal, HomeTheme.horizontalPadding)
            } else {
                // Horizontal scroll of uploads
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentUploads) { upload in
                            Button {
                                viewModel.selectedUpload = upload
                            } label: {
                                UploadCard(upload: upload)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // Add more cards
                        ForEach(0..<numberOfAddCards, id: \.self) { _ in
                            NavigationLink(destination: UploadMethodSelectionView(viewModel: viewModel)) {
                                AddUploadCard()
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, HomeTheme.horizontalPadding)
                }
            }
        }
    }

    // MARK: - Empty Uploads Card

    private var emptyUploadsCard: some View {
        HStack(spacing: 16) {
            Image("VaultEmpty")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)

            VStack(alignment: .leading, spacing: 4) {
                Text("No bills yet")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(HomeTheme.primaryText)

                Text("Upload a bill to start tracking your expenses")
                    .font(.system(size: 13))
                    .foregroundColor(HomeTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: HomeTheme.shadowColor, radius: HomeTheme.shadowRadius, x: 0, y: 2)
    }
}

// MARK: - Upload Card

struct UploadCard: View {
    let upload: RecentUpload

    private var accentColor: Color {
        upload.source == .quickAdd ? HomeTheme.warning : HomeTheme.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Source badge
            HStack(spacing: 4) {
                if upload.source == .quickAdd {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8, weight: .semibold))
                }
                Text(upload.source.displayName)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(accentColor.opacity(0.12))
            .cornerRadius(6)

            // Provider
            Text(upload.provider)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(HomeTheme.primaryText)
                .lineLimit(1)

            Spacer()

            // Amount
            Text(upload.formattedAmount)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(HomeTheme.primaryText)
        }
        .padding(12)
        .frame(width: 120, height: 110)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: HomeTheme.shadowColor, radius: 6, x: 0, y: 2)
    }
}

// MARK: - Add Upload Card

struct AddUploadCard: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(HomeTheme.accent.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(HomeTheme.accent)
            }

            Text("Add Bill")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(HomeTheme.accent)
        }
        .frame(width: 120, height: 110)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(HomeTheme.accent.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .background(HomeTheme.accent.opacity(0.03).cornerRadius(14))
        )
    }
}

// MARK: - Info Popovers

struct QuickAddInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Add")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(HomeTheme.primaryText)

            VStack(alignment: .leading, spacing: 6) {
                UploadInfoRow(icon: "bolt.fill", text: "Just 30 seconds", color: HomeTheme.warning)
                UploadInfoRow(icon: "photo.badge.arrow.down.fill", text: "No upload needed", color: HomeTheme.info)
                UploadInfoRow(icon: "list.number", text: "3 simple questions", color: HomeTheme.accent)
            }

            Text("Great for quick rate comparison")
                .font(.system(size: 11))
                .foregroundColor(HomeTheme.secondaryText)
                .padding(.top, 4)
        }
        .padding(14)
        .frame(width: 200)
        .background(Color.white)
    }
}

struct FullAnalysisInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Full Analysis")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(HomeTheme.primaryText)

            VStack(alignment: .leading, spacing: 6) {
                UploadInfoRow(icon: "list.bullet.rectangle.portrait", text: "Line-by-line breakdown", color: HomeTheme.accent)
                UploadInfoRow(icon: "map", text: "Area rate comparison", color: HomeTheme.info)
                UploadInfoRow(icon: "dollarsign.circle", text: "Savings opportunities", color: HomeTheme.success)
                UploadInfoRow(icon: "chart.line.uptrend.xyaxis", text: "Usage insights", color: HomeTheme.purple)
            }
        }
        .padding(14)
        .frame(width: 210)
        .background(Color.white)
    }
}

struct UploadInfoRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 16)

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(HomeTheme.primaryText)
        }
    }
}

// MARK: - Preview

#Preview {
    UploadHubView()
        .modelContainer(for: StoredBill.self, inMemory: true)
}
