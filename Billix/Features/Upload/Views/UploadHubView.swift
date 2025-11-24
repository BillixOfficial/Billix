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

                        // SECTION 1: Quick Add (Primary Hero)
                        quickAddSection
                            .transition(.scale.combined(with: .opacity))

                        // SECTION 2: Scan/Upload (Secondary)
                        scanUploadSection
                            .transition(.scale.combined(with: .opacity))

                        // SECTION 3: Recent Uploads (History)
                        recentUploadsSection
                            .transition(.opacity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Start without a bill in hand")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.billixMediumGreen)
                .padding(.horizontal, 4)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    viewModel.startQuickAdd()
                }
            }) {
                ZStack {
                    // Stronger Gradient Background (darker for better contrast)
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.7, blue: 0.4),  // Richer green
                            Color(red: 0.95, green: 0.75, blue: 0.2)  // Vibrant yellow
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(24)

                    // Content with text shadows for better readability
                    HStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Add a Bill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)

                            Text("60 seconds · No photo needed")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)

                            Text("Just tell us your provider and amount")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                .lineLimit(2)
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.white.opacity(0.35), .white.opacity(0.15)],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 35
                                    )
                                )
                                .frame(width: 70, height: 70)

                            Image(systemName: "bolt.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                        }
                    }
                    .padding(24)
                }
                .frame(height: 160)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                .shadow(color: .billixMoneyGreen.opacity(0.2), radius: 40, x: 0, y: 20)
            }
            .scaleEffect(appeared ? 1 : 0.9)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Scan/Upload Section (Secondary)

    private var scanUploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Have a bill ready?")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.billixMediumGreen)
                .padding(.horizontal, 4)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    viewModel.startScanUpload()
                }
            }) {
                ZStack {
                    // Stronger Blue Gradient (darker for better contrast)
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.5, blue: 0.85),  // Deeper blue
                            Color(red: 0.15, green: 0.4, blue: 0.75)  // Darker blue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(20)

                    // Content with text shadows
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Upload Bill")
                                .font(.system(size: 21, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)

                            Text("Uncover hidden fees, compare prices, and discover ways to save money.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60)

                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                        }
                    }
                    .padding(20)
                }
                .frame(height: 120)
                .shadow(color: .black.opacity(0.12), radius: 15, x: 0, y: 8)
                .shadow(color: .billixChartBlue.opacity(0.15), radius: 30, x: 0, y: 15)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appeared)
    }

    // MARK: - Recent Uploads Section

    private var recentUploadsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Uploads")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.billixDarkGreen)

                    if !viewModel.recentUploads.isEmpty {
                        Text("\(viewModel.recentUploads.count) bills")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                    }
                }

                Spacer()

                if viewModel.isLoadingRecent {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.billixMoneyGreen)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)

            if viewModel.recentUploads.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 14) {
                    ForEach(viewModel.recentUploads) { upload in
                        RecentUploadRow(upload: upload)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                            )
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 40)
        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: appeared)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.billixLightGreen, .billixBorderGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "tray")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.billixMediumGreen)
            }

            VStack(spacing: 8) {
                Text("No uploads yet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Text("Get started by adding your first bill above")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.billixMediumGreen)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.billixBorderGreen, .billixBorderGreen.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Preview

#Preview {
    UploadHubView()
        .modelContainer(for: StoredBill.self, inMemory: true)
}
