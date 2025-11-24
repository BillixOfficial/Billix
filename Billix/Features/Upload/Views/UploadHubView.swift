//
//  UploadHubView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI
import SwiftData

/// Main Upload Hub - 3-section hybrid design
/// Section 1: Quick Add (Primary)
/// Section 2: Scan/Upload (Secondary)
/// Section 3: Recent Uploads (History)
struct UploadHubView: View {

    @StateObject private var viewModel = UploadViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // SECTION 1: Quick Add (Primary)
                    quickAddSection

                    // SECTION 2: Scan/Upload (Secondary)
                    scanUploadSection

                    // SECTION 3: Recent Uploads (History)
                    recentUploadsSection
                }
                .padding()
            }
            .navigationTitle("Upload")
            .onAppear {
                viewModel.modelContext = modelContext
                Task {
                    await viewModel.loadRecentUploads()
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

    // MARK: - Quick Add Section

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start without a bill in hand")
                .font(.headline)
                .foregroundColor(.secondary)

            Button(action: {
                viewModel.startQuickAdd()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Add a Bill (60 seconds)")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("No photo needed. Just tell us your provider and amount.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "bolt.fill")
                        .font(.largeTitle)
                        .foregroundColor(.billixMoneyGreen)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.billixMoneyGreen.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.billixMoneyGreen, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Scan/Upload Section

    private var scanUploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Have a bill ready?")
                .font(.headline)
                .foregroundColor(.secondary)

            Button(action: {
                viewModel.startScanUpload()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upload Bill")
                            .font(.title3)
                            .fontWeight(.medium)

                        Text("Uncover hidden fees, compare prices, and discover ways to save money.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "doc.text.viewfinder")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Recent Uploads Section

    private var recentUploadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Uploads")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                if viewModel.isLoadingRecent {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if viewModel.recentUploads.isEmpty {
                emptyStateView
            } else {
                ForEach(viewModel.recentUploads) { upload in
                    RecentUploadRow(upload: upload)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No uploads yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Get started by adding your first bill above")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Preview

#Preview {
    UploadHubView()
        .modelContainer(for: StoredBill.self, inMemory: true)
}
