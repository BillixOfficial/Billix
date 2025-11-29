//
//  AllUploadsView.swift
//  Billix
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI
import SwiftData

struct AllUploadsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredBill.uploadDate, order: .reverse)
    private var storedBills: [StoredBill]

    @State private var selectedBill: StoredBill?

    var body: some View {
        ZStack {
            Color.billixLightGreen
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recentUploads) { upload in
                        Button {
                            selectedBill = storedBills.first { $0.id == upload.id }
                        } label: {
                            RecentUploadRow(upload: upload)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationTitle("All Uploads")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedBill) { bill in
            if let upload = bill.toRecentUpload() {
                UploadDetailView(upload: upload, storedBill: bill)
            }
        }
    }

    private var recentUploads: [RecentUpload] {
        storedBills.compactMap { $0.toRecentUpload() }
    }
}

#Preview {
    NavigationView {
        AllUploadsView()
    }
}
