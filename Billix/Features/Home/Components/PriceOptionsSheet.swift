//
//  PriceOptionsSheet.swift
//  Billix
//
//  Bottom sheet showing available options for achieving a price target
//

import SwiftUI

struct PriceOptionsSheet: View {
    let billType: PriceBillType
    let targetAmount: Double
    let regionalAverage: Double
    let options: [PriceOption]

    @Environment(\.dismiss) private var dismiss
    @State private var showBillConnection = false
    @State private var showRelief = false
    @State private var showNegotiationScript = false
    @State private var showExpertBooking = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary header
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(billType.color.opacity(0.15))
                                .frame(width: 56, height: 56)

                            Image(systemName: billType.icon)
                                .font(.system(size: 24))
                                .foregroundColor(billType.color)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(billType.displayName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "#2D3B35"))

                            Text("Your target: $\(Int(targetAmount))/mo")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#8B9A94"))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Options list
                    VStack(spacing: 12) {
                        Text("Here's how we can help")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#8B9A94"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                                OptionRow(option: option) {
                                    handleOptionTap(option)
                                }

                                if index < options.count - 1 {
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

                    Spacer().frame(height: 40)
                }
            }
            .background(Color(hex: "#F7F9F8"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Your Options")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#5B8A6B"))
                }
            }
        }
        .fullScreenCover(isPresented: $showBillConnection) {
            BillConnectionView()
        }
        .fullScreenCover(isPresented: $showRelief) {
            ReliefFlowView()
        }
        .sheet(isPresented: $showNegotiationScript) {
            NegotiationScriptSheet(billType: billType, targetAmount: targetAmount)
        }
        .sheet(isPresented: $showExpertBooking) {
            ExpertBookingSheet(billType: billType, targetAmount: targetAmount)
        }
    }

    private func handleOptionTap(_ option: PriceOption) {
        haptic()
        switch option.action {
        case .viewRates:
            // Navigate to Explore tab
            dismiss()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToUpload"),
                    object: nil
                )
            }
        case .openBillConnection:
            showBillConnection = true
        case .showNegotiationScript:
            showNegotiationScript = true
        case .openRelief:
            showRelief = true
        case .bookExpert:
            showExpertBooking = true
        }
    }
}

// MARK: - Option Row

private struct OptionRow: View {
    let option: PriceOption
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(option.type.color.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: option.type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(option.type.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Text(option.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8B9A94"))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#8B9A94").opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Negotiation Script Sheet

struct NegotiationScriptSheet: View {
    let billType: PriceBillType
    let targetAmount: Double

    @Environment(\.dismiss) private var dismiss

    private var scripts: [(title: String, script: String)] {
        [
            (
                "Opening Line",
                "Hi, I've been a loyal customer for [X years] and I'm looking at my \(billType.displayName.lowercased()) bill. I've found that similar services are available for around $\(Int(targetAmount)) in my area. I'd like to discuss getting a better rate."
            ),
            (
                "If They Offer a Small Discount",
                "I appreciate that, but I was hoping to get closer to $\(Int(targetAmount)). Is there a loyalty discount or any promotions I might qualify for?"
            ),
            (
                "Retention Department Request",
                "I'd like to speak with your retention department. I'm considering switching providers unless we can work something out."
            ),
            (
                "Closing",
                "Thank you for your help. Can you confirm this new rate in writing? When will this take effect on my bill?"
            )
        ]
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Call Your Provider")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        Text("Use these scripts to negotiate a better rate for your \(billType.displayName.lowercased()) bill.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#8B9A94"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Scripts
                    VStack(spacing: 16) {
                        ForEach(Array(scripts.enumerated()), id: \.offset) { index, item in
                            NegotiationScriptCard(
                                number: index + 1,
                                title: item.title,
                                script: item.script
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pro Tips")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        VStack(alignment: .leading, spacing: 8) {
                            NegotiationTipRow(text: "Call early in the morning for shorter wait times")
                            NegotiationTipRow(text: "Be polite but firm - you're a valued customer")
                            NegotiationTipRow(text: "Have a competitor's offer ready to mention")
                            NegotiationTipRow(text: "Ask for the retention department if needed")
                        }
                    }
                    .padding(16)
                    .background(Color(hex: "#5BA4D4").opacity(0.08))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 40)
                }
            }
            .background(Color(hex: "#F7F9F8"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#5B8A6B"))
                }
            }
        }
    }
}

private struct NegotiationScriptCard: View {
    let number: Int
    let title: String
    let script: String

    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(number). \(title)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Spacer()

                Button {
                    haptic()
                    UIPasteboard.general.string = script
                    isCopied = true
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        isCopied = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                        Text(isCopied ? "Copied" : "Copy")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(isCopied ? Color(hex: "#4CAF7A") : Color(hex: "#5B8A6B"))
                }
            }

            Text(script)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#5D6D66"))
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

private struct NegotiationTipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#5BA4D4"))

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#5D6D66"))
        }
    }
}

// MARK: - Expert Booking Sheet

struct ExpertBookingSheet: View {
    let billType: PriceBillType
    let targetAmount: Double

    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber = ""
    @State private var selectedDate = Date()
    @State private var selectedTimeSlot: TimeSlot = .morning
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    enum TimeSlot: String, CaseIterable {
        case morning = "Morning (9am - 12pm)"
        case afternoon = "Afternoon (12pm - 5pm)"
        case evening = "Evening (5pm - 8pm)"

        var displayName: String { rawValue }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.billixPurple.opacity(0.15))
                                .frame(width: 72, height: 72)

                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 32))
                                .foregroundColor(Color.billixPurple)
                        }

                        Text("Talk to a Billix Expert")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        Text("Schedule a call with a real person who will walk you through your options step by step.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#8B9A94"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 8)

                    // Bill context
                    HStack(spacing: 12) {
                        Image(systemName: billType.icon)
                            .font(.system(size: 18))
                            .foregroundColor(billType.color)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Discussing: \(billType.displayName)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "#2D3B35"))

                            Text("Your target: $\(Int(targetAmount))/mo")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#8B9A94"))
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(Color(hex: "#F7F9F8"))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)

                    // Form fields
                    VStack(spacing: 20) {
                        // Phone number
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your phone number")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#5D6D66"))

                            TextField("(555) 123-4567", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .padding(14)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "#E0E5E3"), lineWidth: 1)
                                )
                        }

                        // Date picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preferred date")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#5D6D66"))

                            DatePicker(
                                "",
                                selection: $selectedDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "#E0E5E3"), lineWidth: 1)
                            )
                        }

                        // Time slot
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preferred time")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#5D6D66"))

                            ForEach(TimeSlot.allCases, id: \.self) { slot in
                                Button {
                                    haptic()
                                    selectedTimeSlot = slot
                                } label: {
                                    HStack {
                                        Text(slot.displayName)
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "#2D3B35"))

                                        Spacer()

                                        Image(systemName: selectedTimeSlot == slot ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedTimeSlot == slot ? Color.billixPurple : Color(hex: "#C5CCC9"))
                                    }
                                    .padding(14)
                                    .background(selectedTimeSlot == slot ? Color.billixPurple.opacity(0.08) : Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedTimeSlot == slot ? Color.billixPurple.opacity(0.3) : Color(hex: "#E0E5E3"), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }

                    // Submit button
                    Button {
                        Task {
                            await submitBooking()
                        }
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Schedule Call")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(phoneNumber.count >= 10 ? Color.billixPurple : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(phoneNumber.count < 10 || isSubmitting)
                    .padding(.horizontal, 20)

                    // Note
                    Text("A Billix expert will call you at your scheduled time. No AI, just real personalized help.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#8B9A94"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    Spacer().frame(height: 30)
                }
            }
            .background(Color(hex: "#F7F9F8"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#5B8A6B"))
                }
            }
            .alert("Call Scheduled!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("A Billix expert will call you at your scheduled time. We look forward to helping you save!")
            }
        }
    }

    private func submitBooking() async {
        guard phoneNumber.count >= 10 else {
            errorMessage = "Please enter a valid phone number"
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            // Get user info
            let session = try await SupabaseService.shared.client.auth.session
            let userId = session.user.id.uuidString
            let userEmail = session.user.email

            // Format date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: selectedDate)

            // Save to Supabase
            struct ExpertCallRequest: Encodable {
                let user_id: String
                let user_email: String?
                let phone_number: String
                let bill_type: String
                let target_amount: Double
                let preferred_date: String
                let preferred_time_slot: String
                let status: String
            }

            let request = ExpertCallRequest(
                user_id: userId,
                user_email: userEmail,
                phone_number: phoneNumber,
                bill_type: billType.rawValue,
                target_amount: targetAmount,
                preferred_date: dateString,
                preferred_time_slot: selectedTimeSlot.rawValue,
                status: "pending"
            )

            try await SupabaseService.shared.client
                .from("expert_call_requests")
                .insert(request)
                .execute()

            // Send notification to Billix team
            struct NotifyRequest: Encodable {
                let phoneNumber: String
                let billType: String
                let targetAmount: Double
                let preferredDate: String
                let preferredTimeSlot: String
                let userEmail: String?
            }

            let notifyRequest = NotifyRequest(
                phoneNumber: phoneNumber,
                billType: billType.displayName,
                targetAmount: targetAmount,
                preferredDate: dateString,
                preferredTimeSlot: selectedTimeSlot.rawValue,
                userEmail: userEmail
            )

            try? await SupabaseService.shared.client.functions
                .invoke("notify-expert-call", options: .init(body: notifyRequest))

            isSubmitting = false
            showSuccess = true

        } catch {
            print("❌ Failed to submit expert call request: \(error)")
            errorMessage = "Unable to schedule call. Please try again."
            isSubmitting = false
        }
    }
}

#Preview {
    PriceOptionsSheet(
        billType: PriceBillType.electric,
        targetAmount: 100,
        regionalAverage: 153,
        options: [
            PriceOption(type: .betterRate, title: "Better rates in your area", subtitle: "Compare plans and potentially save", action: .viewRates),
            PriceOption(type: .billConnection, title: "Bill Connection matches", subtitle: "Community members who can help", action: .openBillConnection),
            PriceOption(type: .negotiation, title: "Negotiation scripts ready", subtitle: "Proven tactics that work", action: .showNegotiationScript),
            PriceOption(type: .expertCall, title: "Talk to a Billix Expert", subtitle: "Real human, step-by-step guidance", action: .bookExpert)
        ]
    )
}
