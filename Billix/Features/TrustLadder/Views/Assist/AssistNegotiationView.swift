//
//  AssistNegotiationView.swift
//  Billix
//
//  Created by Claude Code on 12/31/24.
//  Chat and negotiation view for Bill Assist transactions
//

import SwiftUI
import PhotosUI

// MARK: - Assist Negotiation View

struct AssistNegotiationView: View {
    let request: AssistRequest
    let isRequester: Bool

    @StateObject private var messagingService = AssistMessagingService()
    @State private var messageText = ""
    @State private var showTermsSheet = false
    @State private var showPaymentProofSheet = false
    @State private var showDisputeSheet = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var proposedTerms: RepaymentTerms?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header with request info
            requestHeader

            Divider()

            // Chat messages
            messagesScrollView

            // Typing indicator
            if !messagingService.typingUsers.isEmpty {
                typingIndicatorView
            }

            Divider()

            // Action bar (terms, payment proof)
            actionBar

            // Message input
            messageInputBar
        }
        .navigationTitle("Negotiation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showDisputeSheet = true }) {
                        Label("Report Issue", systemImage: "exclamationmark.triangle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showTermsSheet) {
            TermsProposalSheet(
                currentTerms: request.agreedTerms ?? request.preferredTerms ?? .giftDefault,
                amountRequested: request.amountRequested,
                onPropose: { terms in
                    Task {
                        try? await messagingService.sendTermsProposal(terms)
                    }
                }
            )
        }
        .sheet(isPresented: $showPaymentProofSheet) {
            PaymentProofSheet(
                request: request,
                onSubmit: { screenshotUrl in
                    Task {
                        try? await messagingService.sendPaymentSentMessage(screenshotUrl: screenshotUrl)
                    }
                }
            )
        }
        .sheet(isPresented: $showDisputeSheet) {
            DisputeSheet(request: request)
        }
        .task {
            do {
                try await messagingService.connect(to: request.id)
            } catch {
                print("Failed to connect to chat: \(error)")
            }
        }
        .onDisappear {
            Task {
                await messagingService.disconnect()
            }
        }
    }

    // MARK: - Request Header

    private var requestHeader: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: categoryIconName)
                    .font(.system(size: 18))
                    .foregroundColor(categoryColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(request.billProvider)
                    .font(.system(size: 15, weight: .semibold))

                HStack(spacing: 8) {
                    Text("$\(String(format: "%.2f", request.amountRequested))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)

                    statusBadge
                }
            }

            Spacer()

            // Connection fee status
            VStack(alignment: .trailing, spacing: 2) {
                if request.bothFeesPaid {
                    Label("Fees Paid", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                } else {
                    Label("Fee Pending", systemImage: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var statusBadge: some View {
        Text(request.status.displayName)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(request.status.color)
            .cornerRadius(4)
    }

    // MARK: - Messages

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Disclaimer at top
                    disclaimerBanner

                    ForEach(messagingService.messages) { message in
                        MessageBubble(
                            message: message,
                            isFromCurrentUser: isMessageFromCurrentUser(message),
                            onAcceptTerms: {
                                if let terms = message.termsData {
                                    Task {
                                        try? await messagingService.sendTermsAccepted(terms)
                                    }
                                }
                            },
                            onRejectTerms: {
                                Task {
                                    try? await messagingService.sendTermsRejected()
                                }
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messagingService.messages.count) { _ in
                if let lastMessage = messagingService.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private var disclaimerBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)

            Text("Billix is not a lender. All terms are negotiated directly between users.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Typing Indicator

    private var typingIndicatorView: some View {
        HStack(spacing: 8) {
            TypingDotsView()

            Text("typing...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 16) {
            // Propose terms button
            Button(action: { showTermsSheet = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 18))
                    Text("Terms")
                        .font(.system(size: 10))
                }
                .foregroundColor(.blue)
            }

            // Payment proof button (only for helper after terms accepted)
            if !isRequester && request.status == .termsAccepted {
                Button(action: { showPaymentProofSheet = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                        Text("Proof")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.green)
                }
            }

            // Verify payment button (only for requester after payment sent)
            if isRequester && request.status == .paymentSent {
                Button(action: {
                    Task {
                        try? await messagingService.sendPaymentVerifiedMessage()
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Verify")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.green)
                }
            }

            Spacer()

            // Status indicator
            if messagingService.isConnected {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Live")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Message Input

    private var messageInputBar: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .lineLimit(4)
                .onChange(of: messageText) { _ in
                    Task {
                        await messagingService.sendTypingIndicator()
                    }
                }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.isEmpty ? .gray : .blue)
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Helpers

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""

        Task {
            try? await messagingService.sendTextMessage(text)
        }
    }

    private func isMessageFromCurrentUser(_ message: AssistMessage) -> Bool {
        if isRequester {
            return message.senderId == request.requesterId
        } else {
            return message.senderId == request.helperId
        }
    }

    private var categoryIconName: String {
        switch request.billCategory.lowercased() {
        case "electric", "electricity": return "bolt.fill"
        case "gas", "natural gas": return "flame.fill"
        case "water": return "drop.fill"
        case "internet", "wifi": return "wifi"
        case "phone", "mobile": return "phone.fill"
        default: return "doc.text.fill"
        }
    }

    private var categoryColor: Color {
        switch request.billCategory.lowercased() {
        case "electric", "electricity": return .yellow
        case "gas", "natural gas": return .orange
        case "water": return .blue
        case "internet", "wifi": return .purple
        case "phone", "mobile": return .green
        default: return .gray
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: AssistMessage
    let isFromCurrentUser: Bool
    var onAcceptTerms: (() -> Void)? = nil
    var onRejectTerms: (() -> Void)? = nil

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                switch message.messageType {
                case .text:
                    textBubble

                case .termsProposal:
                    termsProposalBubble

                case .termsAccepted:
                    systemBubble(text: "Terms accepted", icon: "checkmark.circle.fill", color: .green)

                case .termsRejected:
                    systemBubble(text: "Terms declined", icon: "xmark.circle.fill", color: .red)

                case .system:
                    systemBubble(text: message.content ?? "System message", icon: "info.circle.fill", color: .blue)

                case .paymentSent:
                    systemBubble(text: "Payment sent", icon: "arrow.up.circle.fill", color: .green)

                case .paymentVerified:
                    systemBubble(text: "Payment verified", icon: "checkmark.seal.fill", color: .green)

                case .repaymentReceived:
                    systemBubble(text: message.content ?? "Repayment received", icon: "dollarsign.circle.fill", color: .green)
                }

                // Timestamp
                Text(timeString)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }

    private var textBubble: some View {
        Text(message.content ?? "")
            .font(.system(size: 15))
            .foregroundColor(isFromCurrentUser ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
            .cornerRadius(18)
    }

    private var termsProposalBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.purple)
                Text("Terms Proposal")
                    .font(.system(size: 13, weight: .semibold))
            }

            if let terms = message.termsData {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Type:")
                            .foregroundColor(.secondary)
                        Text(terms.assistType.displayName)
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 13))

                    if let rate = terms.interestRate, rate > 0 {
                        HStack {
                            Text("Interest:")
                                .foregroundColor(.secondary)
                            Text("\(Int(rate * 100))%")
                                .fontWeight(.medium)
                        }
                        .font(.system(size: 13))
                    }

                    if let date = terms.repaymentDate {
                        HStack {
                            Text("Due:")
                                .foregroundColor(.secondary)
                            Text(date, style: .date)
                                .fontWeight(.medium)
                        }
                        .font(.system(size: 13))
                    }
                }

                // Action buttons (only for recipient)
                if !isFromCurrentUser {
                    HStack(spacing: 12) {
                        Button(action: { onAcceptTerms?() }) {
                            Text("Accept")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                        }

                        Button(action: { onRejectTerms?() }) {
                            Text("Decline")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(12)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }

    private func systemBubble(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.createdAt)
    }
}

// MARK: - Typing Dots Animation

struct TypingDotsView: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Terms Proposal Sheet

struct TermsProposalSheet: View {
    @Environment(\.dismiss) private var dismiss

    let currentTerms: RepaymentTerms
    let amountRequested: Double
    let onPropose: (RepaymentTerms) -> Void

    @State private var selectedType: AssistType
    @State private var interestRate: Double
    @State private var repaymentDate: Date
    @State private var notes: String

    init(currentTerms: RepaymentTerms, amountRequested: Double, onPropose: @escaping (RepaymentTerms) -> Void) {
        self.currentTerms = currentTerms
        self.amountRequested = amountRequested
        self.onPropose = onPropose
        _selectedType = State(initialValue: currentTerms.assistType)
        _interestRate = State(initialValue: (currentTerms.interestRate ?? 0) * 100)
        _repaymentDate = State(initialValue: currentTerms.repaymentDate ?? Calendar.current.date(byAdding: .day, value: 30, to: Date())!)
        _notes = State(initialValue: currentTerms.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Assistance Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(AssistType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(selectedType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if selectedType == .loan {
                    Section("Loan Terms") {
                        HStack {
                            Text("Interest Rate")
                            Spacer()
                            TextField("0", value: $interestRate, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("%")
                                .foregroundColor(.secondary)
                        }

                        DatePicker("Repayment Due", selection: $repaymentDate, displayedComponents: .date)
                    }

                    Section("Summary") {
                        HStack {
                            Text("Principal")
                            Spacer()
                            Text("$\(String(format: "%.2f", amountRequested))")
                        }

                        HStack {
                            Text("Interest")
                            Spacer()
                            Text("$\(String(format: "%.2f", amountRequested * (interestRate / 100)))")
                        }

                        HStack {
                            Text("Total to Repay")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("$\(String(format: "%.2f", amountRequested * (1 + interestRate / 100)))")
                                .fontWeight(.semibold)
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Propose Terms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Propose") {
                        let terms = RepaymentTerms(
                            assistType: selectedType,
                            interestRate: selectedType == .loan ? interestRate / 100 : nil,
                            repaymentDate: selectedType == .loan ? repaymentDate : nil,
                            notes: notes.isEmpty ? nil : notes
                        )
                        onPropose(terms)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Payment Proof Sheet

struct PaymentProofSheet: View {
    @Environment(\.dismiss) private var dismiss

    let request: AssistRequest
    let onSubmit: (String?) -> Void

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var screenshotImage: Image?
    @State private var isUploading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Instructions
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)

                    Text("Upload Payment Proof")
                        .font(.headline)

                    Text("Take a screenshot of the payment confirmation showing the amount and provider.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Photo picker
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .screenshots
                ) {
                    if let image = screenshotImage {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "plus.rectangle.on.rectangle")
                                .font(.system(size: 32))
                            Text("Select Screenshot")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .onChange(of: selectedPhoto) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            screenshotImage = Image(uiImage: uiImage)
                        }
                    }
                }

                Spacer()

                // Submit button
                Button(action: {
                    isUploading = true
                    // TODO: Upload to storage and get URL
                    onSubmit(nil)
                    dismiss()
                }) {
                    HStack {
                        if isUploading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Submit Proof")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(screenshotImage != nil ? Color.green : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(screenshotImage == nil || isUploading)
            }
            .padding(24)
            .navigationTitle("Payment Proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Dispute Sheet

struct DisputeSheet: View {
    @Environment(\.dismiss) private var dismiss

    let request: AssistRequest

    @State private var selectedReason: AssistDisputeReason = .ghost
    @State private var description = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationView {
            Form {
                Section("Reason") {
                    Picker("Issue Type", selection: $selectedReason) {
                        ForEach(AssistDisputeReason.allCases, id: \.self) { reason in
                            Text(reason.displayName).tag(reason)
                        }
                    }
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(height: 120)
                }

                Section {
                    Button(action: submitDispute) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                            }
                            Text("Submit Report")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(description.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submitDispute() {
        isSubmitting = true
        // TODO: Submit dispute to backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSubmitting = false
            dismiss()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AssistNegotiationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AssistNegotiationView(
                request: .preview,
                isRequester: true
            )
        }
    }
}
#endif
