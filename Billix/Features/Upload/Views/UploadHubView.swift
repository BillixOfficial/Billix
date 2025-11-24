//
//  UploadHubView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//  Redesigned with modern SwiftUI best practices
//

import SwiftUI
import SwiftData

/// Modern Upload Hub with glassmorphism and gradient design
/// Section 1: Quick Add (Primary Hero)
/// Section 2: Scan/Upload (Secondary)
/// Section 3: Recent Uploads (History)
struct UploadHubView: View {

    @StateObject private var viewModel = UploadViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient Background matching home page theme
                LinearGradient(
                    colors: [
                        Color.billixLightGreen,
                        Color.billixLightGreen.opacity(0.8),
                        Color.white.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {

                        // SECTION 1: Quick Add (Primary Hero) - VISIBLE FIRST
                        quickAddSection
                            .transition(.scale.combined(with: .opacity))

                        // SECTION 2: Secondary Actions - Icon buttons (Card Container)
                        ZStack {
                            // White card background
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)

                            // Content
                            secondaryActionsSection
                                .padding(20)
                        }
                        .transition(.scale.combined(with: .opacity))

                        // SECTION 3: Recent Uploads (History) - Bottom
                        recentUploadsSection
                            .transition(.opacity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 80)
                }
                .scrollBounceBehavior(.basedOnSize)
                .navigationTitle("Upload")
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
                    QuickAddFlowView(onComplete: {
                        viewModel.dismissFlows()
                        viewModel.handleUploadComplete()
                    })
                }
                .sheet(isPresented: $viewModel.showScanUploadFlow) {
                    ScanUploadFlowView(onComplete: {
                        viewModel.dismissFlows()
                        viewModel.handleUploadComplete()
                    })
                }
            }
        }
    }

    // MARK: - Quick Add Section (Primary Hero)

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Primary Action")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.billixMediumGreen.opacity(0.8))
                .padding(.horizontal, 4)
                .textCase(.uppercase)
                .tracking(0.5)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    viewModel.startQuickAdd()
                }
            }) {
                ZStack {
                    // Hero gradient background
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.7, blue: 0.4),  // Rich green
                            Color(red: 0.95, green: 0.75, blue: 0.2)  // Vibrant yellow
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(20)

                    // Content optimized for hero card
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Quick Add a Bill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)

                            Text("30 seconds · No photo needed")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.95))
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)

                            Text("Compare your bill to area average instantly")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    .padding(20)
                }
                .frame(height: 120)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                .shadow(color: .billixMoneyGreen.opacity(0.2), radius: 40, x: 0, y: 20)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
    }

    // MARK: - Secondary Actions (Icon Buttons)

    private var secondaryActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Upload for Full Analysis")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen.opacity(0.8))
                    .padding(.horizontal, 4)
                    .textCase(.uppercase)
                    .tracking(0.5)

                VStack(alignment: .leading, spacing: 8) {
                    BenefitRow(
                        icon: "checkmark.circle.fill",
                        text: "Line-by-line breakdown",
                        color: .billixMoneyGreen
                    )

                    BenefitRow(
                        icon: "checkmark.circle.fill",
                        text: "Hidden fees analysis",
                        color: .billixMoneyGreen
                    )

                    BenefitRow(
                        icon: "checkmark.circle.fill",
                        text: "Personalized savings",
                        color: .billixMoneyGreen
                    )
                }
                .padding(.horizontal, 4)
            }

            HStack(spacing: 12) {
                // Camera button
                SecondaryActionButton(
                    icon: "camera.fill",
                    title: "Camera",
                    subtitle: "Scan bill",
                    gradient: [
                        Color(red: 0.2, green: 0.5, blue: 0.9),
                        Color(red: 0.5, green: 0.3, blue: 0.85)
                    ]
                ) {
                    viewModel.startScanUpload()
                }

                // Gallery button
                SecondaryActionButton(
                    icon: "photo.on.rectangle",
                    title: "Gallery",
                    subtitle: "From photos",
                    gradient: [
                        Color(red: 0.3, green: 0.6, blue: 0.9),
                        Color(red: 0.2, green: 0.8, blue: 0.8)
                    ]
                ) {
                    viewModel.startScanUpload()
                }

                // Document button
                SecondaryActionButton(
                    icon: "doc.fill",
                    title: "Document",
                    subtitle: "Upload file",
                    gradient: [
                        Color(red: 0.6, green: 0.4, blue: 0.9),
                        Color(red: 0.8, green: 0.3, blue: 0.85)
                    ]
                ) {
                    viewModel.startScanUpload()
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
    }

    // MARK: - Recent Uploads Section

    private var recentUploadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Uploads")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                if !viewModel.recentUploads.isEmpty {
                    Text("(\(viewModel.recentUploads.count))")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                }

                Spacer()

                if viewModel.isLoadingRecent {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.billixMoneyGreen)
                }
            }
            .padding(.horizontal, 4)

            if viewModel.recentUploads.isEmpty {
                // Compact empty state
                HStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.billixMediumGreen)

                    Text("No uploads yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.6))
                )
            } else {
                // Compact list - show only 3 most recent
                VStack(spacing: 10) {
                    ForEach(viewModel.recentUploads.prefix(3)) { upload in
                        RecentUploadRow(upload: upload)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // View All button if there are more than 3 bills
                    if viewModel.recentUploads.count > 3 {
                        Button(action: {
                            // TODO: Navigate to full Recent Uploads list
                        }) {
                            HStack {
                                Text("View All (\(viewModel.recentUploads.count))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.billixMoneyGreen)

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.billixMoneyGreen)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.billixBorderGreen, lineWidth: 1.5)
                                    )
                            )
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)
    }

}

// MARK: - Secondary Action Button Component

struct SecondaryActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(16)

                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                }
                .frame(height: 80)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Benefit Row Component

struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.billixDarkGreen)
        }
    }
}

// MARK: - Preview

#Preview {
    UploadHubView()
        .modelContainer(for: StoredBill.self, inMemory: true)
}
