//
//  ReliefDetailView.swift
//  Billix
//
//  Detailed view for a single relief request with notes
//

import SwiftUI

struct ReliefDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let request: ReliefRequest

    @StateObject private var reliefService = ReliefService.shared
    @State private var notes: [ReliefRequestNote] = []
    @State private var documents: [ReliefRequestDocument] = []
    @State private var newNote: String = ""
    @State private var isLoadingNotes = true
    @State private var isAddingNote = false
    @State private var showCancelConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Header
                    statusHeader

                    // Request Details
                    requestDetails

                    // Timeline/Notes Section
                    notesSection

                    // Add Note Section
                    if request.status == .pending || request.status == .underReview {
                        addNoteSection
                    }

                    // Cancel Button (only for pending requests)
                    if request.status == .pending {
                        cancelSection
                    }

                    Spacer().frame(height: 40)
                }
                .padding(20)
            }
            .background(Color(hex: "#F7F9F8").ignoresSafeArea())
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .task {
                await loadNotes()
            }
            .alert("Cancel Request", isPresented: $showCancelConfirmation) {
                Button("Keep Request", role: .cancel) { }
                Button("Cancel Request", role: .destructive) {
                    Task {
                        try? await reliefService.cancelRequest(requestId: request.id)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to cancel this relief request? This action cannot be undone.")
            }
        }
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        VStack(spacing: 16) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(request.status.color.opacity(0.15))
                    .frame(width: 70, height: 70)

                Image(systemName: request.status.icon)
                    .font(.system(size: 32))
                    .foregroundColor(request.status.color)
            }

            // Status Text
            VStack(spacing: 4) {
                Text(request.status.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(request.status.color)

                Text(statusDescription)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
    }

    private var statusDescription: String {
        switch request.status {
        case .pending:
            return "Your request is waiting to be reviewed"
        case .underReview:
            return "We're currently reviewing your request"
        case .approved:
            return "Great news! Your request has been approved"
        case .denied:
            return "Unfortunately, your request was not approved"
        case .completed:
            return "Your relief request has been fulfilled"
        case .cancelled:
            return "This request has been cancelled"
        }
    }

    // MARK: - Request Details

    private var requestDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Request Details")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#2D3B35"))

            VStack(spacing: 12) {
                ReliefDetailRow(icon: request.billType.icon, iconColor: request.billType.color, label: "Bill Type", value: request.billType.displayName)
                if let provider = request.billProvider, !provider.isEmpty {
                    ReliefDetailRow(icon: "building.2.fill", iconColor: Color(hex: "#8B9A94"), label: "Provider", value: provider)
                }
                ReliefDetailRow(icon: "dollarsign.circle.fill", iconColor: .red, label: "Amount", value: request.formattedAmount)
                ReliefDetailRow(icon: request.urgencyLevel.icon, iconColor: request.urgencyLevel.color, label: "Urgency", value: request.urgencyLevel.displayName)
                if let shutoffDate = request.utilityShutoffDate {
                    let formatter = DateFormatter()
                    let _ = formatter.dateStyle = .medium
                    ReliefDetailRow(icon: "calendar.badge.exclamationmark", iconColor: .red, label: "Shutoff Date", value: formatter.string(from: shutoffDate))
                }
                ReliefDetailRow(icon: "calendar", iconColor: Color(hex: "#5B8A6B"), label: "Submitted", value: request.formattedCreatedDate)
            }

            if let description = request.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#8B9A94"))

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#2D3B35"))
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Updates & Notes")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Spacer()

                if isLoadingNotes {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if notes.isEmpty && !isLoadingNotes {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "#8B9A94").opacity(0.5))
                        Text("No updates yet")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#8B9A94"))
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(notes) { note in
                        NoteRow(note: note)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Add Note Section

    private var addNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a Note")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#2D3B35"))

            HStack(spacing: 12) {
                TextField("Add additional information...", text: $newNote)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(Color(hex: "#F7F9F8"))
                    .cornerRadius(10)

                Button {
                    Task {
                        await addNote()
                    }
                } label: {
                    if isAddingNote {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 44, height: 44)
                .background(newNote.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                .cornerRadius(10)
                .disabled(newNote.isEmpty || isAddingNote)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Cancel Section

    private var cancelSection: some View {
        Button {
            showCancelConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                Text("Cancel Request")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Actions

    private func loadNotes() async {
        isLoadingNotes = true
        do {
            notes = try await reliefService.fetchNotes(for: request.id)
        } catch {
            print("Failed to load notes: \(error)")
        }
        isLoadingNotes = false
    }

    private func addNote() async {
        guard !newNote.isEmpty else { return }

        isAddingNote = true
        do {
            let note = try await reliefService.addNote(to: request.id, text: newNote)
            notes.insert(note, at: 0)
            newNote = ""
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            print("Failed to add note: \(error)")
        }
        isAddingNote = false
    }
}

// MARK: - Relief Detail Row

private struct ReliefDetailRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#8B9A94"))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#2D3B35"))
        }
    }
}

// MARK: - Note Row

private struct NoteRow: View {
    let note: ReliefRequestNote

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(note.isAdminNote ? Color(hex: "#5B8A6B").opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: note.isAdminNote ? "person.badge.shield.checkmark.fill" : "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(note.isAdminNote ? Color(hex: "#5B8A6B") : Color(hex: "#8B9A94"))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(note.isAdminNote ? "Billix Team" : "You")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Spacer()

                    Text(note.formattedDate)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Text(note.noteText)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#5D6D66"))
            }
        }
        .padding(12)
        .background(note.isAdminNote ? Color(hex: "#5B8A6B").opacity(0.06) : Color(hex: "#F7F9F8"))
        .cornerRadius(10)
    }
}

#Preview {
    ReliefDetailView(
        request: ReliefRequest(
            id: UUID(),
            userId: UUID(),
            fullName: "John Doe",
            email: "john@example.com",
            phone: nil,
            billType: .electric,
            billProvider: "DTE Energy",
            amountOwed: 250.00,
            description: "Behind on payments due to recent job loss. Looking for any assistance programs available.",
            incomeLevel: .from25kTo50k,
            householdSize: 3,
            employmentStatus: .unemployed,
            urgencyLevel: .high,
            utilityShutoffDate: Date().addingTimeInterval(5 * 24 * 60 * 60),
            status: .underReview,
            statusNotes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}
