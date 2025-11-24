//
//  RecentUploadRow.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct RecentUploadRow: View {
    let upload: RecentUpload

    var body: some View {
        HStack(spacing: 12) {
            // Source Icon
            Circle()
                .fill(sourceColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: upload.source.icon)
                        .foregroundColor(sourceColor)
                )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(upload.provider)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(upload.source.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(upload.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Status & Amount
            VStack(alignment: .trailing, spacing: 4) {
                if upload.amount > 0 {
                    Text(upload.formattedAmount)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                HStack(spacing: 4) {
                    Image(systemName: upload.status.icon)
                        .font(.caption2)

                    Text(upload.status.displayName)
                        .font(.caption)
                }
                .foregroundColor(statusColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    private var sourceColor: Color {
        switch upload.source {
        case .quickAdd:
            return .billixMoneyGreen
        case .camera:
            return .blue
        case .photos:
            return .purple
        case .documentScanner:
            return .orange
        case .documentPicker:
            return .pink
        }
    }

    private var statusColor: Color {
        switch upload.status {
        case .processing:
            return .orange
        case .analyzed:
            return .green
        case .needsConfirmation:
            return .yellow
        case .failed:
            return .red
        }
    }
}

#Preview {
    VStack {
        RecentUploadRow(upload: RecentUpload(
            id: UUID(),
            provider: "DTE Energy",
            amount: 124.56,
            source: .camera,
            status: .analyzed,
            uploadDate: Date().addingTimeInterval(-86400),
            thumbnailName: nil
        ))

        RecentUploadRow(upload: RecentUpload(
            id: UUID(),
            provider: "Comcast",
            amount: 89.99,
            source: .quickAdd,
            status: .processing,
            uploadDate: Date(),
            thumbnailName: nil
        ))
    }
    .padding()
}
