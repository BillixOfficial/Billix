//
//  ScanUploadProgressView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct ScanUploadProgressView: View {
    @ObservedObject var viewModel: ScanUploadViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 150, height: 150)

                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(
                        Color.billixMoneyGreen,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progress)

                Text("\(Int(viewModel.progress * 100))%")
                    .font(.title)
                    .fontWeight(.bold)
            }

            // Status Message
            Text(viewModel.statusMessage)
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}
