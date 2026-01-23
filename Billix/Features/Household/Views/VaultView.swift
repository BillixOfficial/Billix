//
//  VaultView.swift
//  Billix
//
//  The Vault - Shared document safe for household
//  (lease agreements, Wi-Fi passwords, landlord info, etc.)
//

import SwiftUI
import Supabase

struct VaultView: View {
    @StateObject private var viewModel = VaultViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("The Vault")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        Text("Shared documents and info")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#8B9A94"))
                    }

                    Spacer()

                    Button {
                        viewModel.showAddDocument = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#5B8A6B"))
                    }
                }
                .padding(.horizontal, 20)

                // Quick Info Cards
                quickInfoSection

                // Documents by Type
                ForEach(DocumentType.allCases, id: \.self) { type in
                    let docs = viewModel.documents.filter { $0.documentType == type }
                    if !docs.isEmpty {
                        documentSection(type: type, documents: docs)
                    }
                }

                // Empty state
                if viewModel.documents.isEmpty && !viewModel.isLoading {
                    emptyVaultView
                }

                Spacer().frame(height: 100)
            }
            .padding(.top, 16)
        }
        .task {
            await viewModel.fetchDocuments()
        }
        .sheet(isPresented: $viewModel.showAddDocument) {
            AddDocumentSheet(viewModel: viewModel)
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: - Quick Info Section

    private var quickInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Info")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#2D3B35"))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickInfoCard(
                        icon: "wifi",
                        title: "Wi-Fi",
                        value: viewModel.wifiPassword ?? "Add password",
                        color: Color(hex: "#5BA4D4"),
                        onTap: { viewModel.showWifiEditor = true }
                    )

                    QuickInfoCard(
                        icon: "person.fill",
                        title: "Landlord",
                        value: viewModel.landlordInfo ?? "Add contact",
                        color: Color(hex: "#9B7EB8"),
                        onTap: { viewModel.showLandlordEditor = true }
                    )

                    QuickInfoCard(
                        icon: "key.fill",
                        title: "Spare Key",
                        value: viewModel.spareKeyLocation ?? "Add location",
                        color: Color(hex: "#E8A54B"),
                        onTap: { viewModel.showKeyEditor = true }
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Document Section

    private func documentSection(type: DocumentType, documents: [VaultDocument]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#5B8A6B"))
                Text(type.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Spacer()

                Text("\(documents.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(documents) { doc in
                    DocumentRow(document: doc, onDelete: {
                        Task {
                            await viewModel.deleteDocument(doc.id)
                        }
                    })

                    if doc.id != documents.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Empty State

    private var emptyVaultView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#5B8A6B").opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "#5B8A6B"))
            }

            Text("Your Vault is Empty")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#2D3B35"))

            Text("Store important documents like leases,\nutility bills, and household info here")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#8B9A94"))
                .multilineTextAlignment(.center)

            Button {
                viewModel.showAddDocument = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add First Document")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "#5B8A6B"))
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Quick Info Card

struct QuickInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)

                    Spacer()

                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8B9A94"))

                    Text(value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))
                        .lineLimit(1)
                }
            }
            .frame(width: 130)
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Document Row

struct DocumentRow: View {
    let document: VaultDocument
    let onDelete: () -> Void
    @State private var showActions = false

    var body: some View {
        HStack(spacing: 12) {
            // Document icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#5B8A6B").opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: document.documentType.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#5B8A6B"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                HStack(spacing: 6) {
                    Image(systemName: document.accessLevel == .all ? "person.2.fill" : "lock.fill")
                        .font(.system(size: 10))
                    Text(document.accessLevel.displayName)
                        .font(.system(size: 11))
                }
                .foregroundColor(Color(hex: "#8B9A94"))
            }

            Spacer()

            // Date added
            Text(formatDate(document.createdAt))
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#8B9A94"))

            // Actions menu
            Menu {
                Button {
                    // View document
                } label: {
                    Label("View", systemImage: "eye")
                }

                Button {
                    // Share document
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Add Document Sheet

struct AddDocumentSheet: View {
    @ObservedObject var viewModel: VaultViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedType: DocumentType = .other
    @State private var accessLevel: DocumentAccessLevel = .all

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Document Title")
                        .font(.headline)
                    TextField("e.g., Lease Agreement 2024", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                // Document Type
                VStack(alignment: .leading, spacing: 12) {
                    Text("Document Type")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(DocumentType.allCases, id: \.self) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 20))
                                        Text(type.displayName)
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(selectedType == type
                                        ? Color(hex: "#5B8A6B")
                                        : Color(hex: "#8B9A94"))
                                    .frame(width: 80, height: 70)
                                    .background(selectedType == type
                                        ? Color(hex: "#5B8A6B").opacity(0.12)
                                        : Color(hex: "#F5F5F5"))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Access Level
                VStack(alignment: .leading, spacing: 12) {
                    Text("Who Can View")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(DocumentAccessLevel.allCases, id: \.self) { level in
                        Button {
                            accessLevel = level
                        } label: {
                            HStack {
                                Image(systemName: level == .all ? "person.2.fill" : "lock.fill")
                                Text(level.displayName)
                                Spacer()
                                if accessLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "#5B8A6B"))
                                }
                            }
                            .foregroundColor(.primary)
                            .padding()
                            .background(accessLevel == level
                                ? Color(hex: "#5B8A6B").opacity(0.1)
                                : Color.clear)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()

                // Upload button (placeholder)
                Button {
                    // Upload document logic
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Select Document")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(title.isEmpty ? Color.gray : Color(hex: "#5B8A6B"))
                    .cornerRadius(12)
                }
                .disabled(title.isEmpty)
                .padding(.horizontal)
            }
            .padding(.top, 20)
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Vault ViewModel

@MainActor
class VaultViewModel: ObservableObject {
    private let supabase = SupabaseService.shared.client
    private let householdService = HouseholdService.shared

    @Published var documents: [VaultDocument] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showAddDocument = false
    @Published var showWifiEditor = false
    @Published var showLandlordEditor = false
    @Published var showKeyEditor = false

    // Quick info
    @Published var wifiPassword: String?
    @Published var landlordInfo: String?
    @Published var spareKeyLocation: String?

    func fetchDocuments() async {
        guard let household = householdService.currentHousehold else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let docs: [VaultDocument] = try await supabase
                .from("vault_documents")
                .select("*, profiles:uploader_id(id, display_name, avatar_url)")
                .eq("household_id", value: household.id.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            documents = docs
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteDocument(_ id: UUID) async {
        do {
            try await supabase
                .from("vault_documents")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            documents.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    VaultView()
}
