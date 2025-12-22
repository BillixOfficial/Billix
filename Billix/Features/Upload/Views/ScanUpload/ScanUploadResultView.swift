//
//  ScanUploadResultView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

/// Result view after scan upload analysis completes
/// Uses tabbed layout with hero section and swipeable tabs
struct ScanUploadResultView: View {
    let analysis: BillAnalysis
    let onComplete: () -> Void

    var body: some View {
        AnalysisResultsTabbedView(analysis: analysis, onComplete: onComplete)
    }
}

struct ScanUploadErrorView: View {
    let error: UploadError
    let onRetry: () -> Void
    let onDismiss: () -> Void

    private var isNotABillError: Bool {
        if case .notABill = error {
            return true
        }
        return false
    }

    private var buttonText: String {
        isNotABillError ? "Close" : "Try Again"
    }

    private var buttonAction: () -> Void {
        isNotABillError ? onDismiss : onRetry
    }

    var body: some View {
        VStack(spacing: 24) {
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                )

            Text("Upload Failed")
                .font(.title2)
                .fontWeight(.bold)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: buttonAction) {
                Text(buttonText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                    )
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
