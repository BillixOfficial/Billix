//
//  ScanUploadFlowView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

/// Container for Scan/Upload flow
struct ScanUploadFlowView: View {
    @StateObject private var viewModel: ScanUploadViewModel
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void

    init(preselectedImage: UIImage? = nil, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ScanUploadViewModel(preselectedImage: preselectedImage))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.uploadState {
                case .idle, .selecting:
                    ScanUploadOptionsView(viewModel: viewModel)

                case .uploading, .analyzing:
                    ScanUploadProgressView(viewModel: viewModel)

                case .success(let analysis):
                    ScanUploadResultView(analysis: analysis, onComplete: {
                        onComplete()
                        dismiss()
                    })

                case .error(let error):
                    ScanUploadErrorView(error: error, onRetry: {
                        viewModel.retry()
                    })
                }
            }
            .navigationTitle("Upload Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
