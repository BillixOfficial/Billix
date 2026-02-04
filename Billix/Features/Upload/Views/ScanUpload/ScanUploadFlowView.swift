//
//  ScanUploadFlowView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI
import SwiftData

/// Container for Scan/Upload flow
struct ScanUploadFlowView: View {
    @StateObject private var viewModel: ScanUploadViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let onComplete: () -> Void

    init(preselectedImage: UIImage? = nil, fileData: Data? = nil, fileName: String? = nil, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ScanUploadViewModel(
            preselectedImage: preselectedImage,
            fileData: fileData,
            fileName: fileName
        ))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.uploadState {
                case .idle, .selecting:
                    // If we have preselected content, show progress immediately
                    // The actual upload will start in onAppear via startIfReady()
                    if viewModel.hasPreselectedContent {
                        ScanUploadProgressView(viewModel: viewModel)
                    } else {
                        // Only show options if somehow no content was provided (fallback)
                        ScanUploadOptionsView(viewModel: viewModel)
                    }

                case .uploading, .analyzing:
                    ScanUploadProgressView(viewModel: viewModel)

                case .success(let analysis):
                    ScanUploadResultView(analysis: analysis, onComplete: {
                        onComplete()
                        dismiss()
                    })

                case .error(let error):
                    ScanUploadErrorView(
                        error: error,
                        onRetry: {
                            viewModel.retry()
                        },
                        onDismiss: {
                            dismiss()
                        }
                    )
                }
            }
            .navigationTitle("Full Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            // Inject ModelContext into ViewModel for saving bills
            viewModel.modelContext = modelContext
            // Start processing if there's preselected content
            viewModel.startIfReady()
        }
    }
}
