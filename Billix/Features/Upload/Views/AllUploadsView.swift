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
    @State private var isEditMode = false
    @State private var selectedBillsForDeletion: Set<UUID> = []
    @State private var billToDelete: StoredBill?
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            Color.billixLightGreen
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recentUploads) { upload in
                        HStack(spacing: 12) {
                            // Selection checkbox in edit mode
                            if isEditMode {
                                Button {
                                    toggleSelection(for: upload.id)
                                } label: {
                                    Image(systemName: selectedBillsForDeletion.contains(upload.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(selectedBillsForDeletion.contains(upload.id) ? .billixMoneyGreen : .gray)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            Button {
                                if !isEditMode {
                                    selectedBill = storedBills.first { $0.id == upload.id }
                                } else {
                                    toggleSelection(for: upload.id)
                                }
                            } label: {
                                RecentUploadRow(upload: upload)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    if let bill = storedBills.first(where: { $0.id == upload.id }) {
                                        billToDelete = bill
                                        showDeleteConfirmation = true
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationTitle("All Uploads")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !storedBills.isEmpty {
                    Button {
                        withAnimation {
                            if isEditMode {
                                // Exit edit mode
                                isEditMode = false
                                selectedBillsForDeletion.removeAll()
                            } else {
                                // Enter edit mode
                                isEditMode = true
                            }
                        }
                    } label: {
                        Text(isEditMode ? "Done" : "Select")
                            .foregroundColor(.billixChartBlue)
                    }
                }
            }

            if isEditMode {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        deleteSelectedBills()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Delete (\(selectedBillsForDeletion.count))")
                        }
                        .foregroundColor(.red)
                    }
                    .disabled(selectedBillsForDeletion.isEmpty)
                }
            }
        }
        .sheet(item: $selectedBill) { bill in
            if let upload = bill.toRecentUpload() {
                UploadDetailView(upload: upload, storedBill: bill)
            }
        }
        .confirmationDialog(
            "Delete this bill?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible,
            presenting: billToDelete
        ) { bill in
            Button("Delete", role: .destructive) {
                deleteBill(bill)
            }
            Button("Cancel", role: .cancel) {
                billToDelete = nil
            }
        }
    }

    private func toggleSelection(for id: UUID) {
        if selectedBillsForDeletion.contains(id) {
            selectedBillsForDeletion.remove(id)
        } else {
            selectedBillsForDeletion.insert(id)
        }
    }

    private func deleteSelectedBills() {
        for billId in selectedBillsForDeletion {
            if let bill = storedBills.first(where: { $0.id == billId }) {
                modelContext.delete(bill)
            }
        }
        try? modelContext.save()
        selectedBillsForDeletion.removeAll()

        withAnimation {
            isEditMode = false
        }
    }

    private func deleteBill(_ bill: StoredBill) {
        modelContext.delete(bill)
        try? modelContext.save()
        billToDelete = nil
    }

    private var recentUploads: [RecentUpload] {
        storedBills.compactMap { $0.toRecentUpload() }
    }
}

struct AllUploadsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
        AllUploadsView()
        }
    }
}
