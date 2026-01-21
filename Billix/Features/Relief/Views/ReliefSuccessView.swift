//
//  ReliefSuccessView.swift
//  Billix
//
//  Success screen after submitting a relief request
//

import SwiftUI

struct ReliefSuccessView: View {
    let request: ReliefRequest
    let onDone: () -> Void
    let onViewHistory: () -> Void

    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success Animation
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.red.opacity(0.15), lineWidth: 20)
                    .frame(width: 140, height: 140)

                // Inner circle
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)

                // Checkmark
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .scaleEffect(showConfetti ? 1 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)
            }

            // Title
            VStack(spacing: 12) {
                Text("Request Submitted!")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("We've received your relief request and will review it shortly.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Request Summary Card
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Request Summary")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Spacer()

                    // Status badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(request.status.color)
                            .frame(width: 6, height: 6)
                        Text(request.status.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(request.status.color)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(request.status.color.opacity(0.12))
                    .cornerRadius(12)
                }

                Divider()

                VStack(spacing: 12) {
                    SummaryRow(icon: request.billType.icon, iconColor: request.billType.color, label: "Bill Type", value: request.billType.displayName)
                    SummaryRow(icon: "dollarsign.circle.fill", iconColor: .red, label: "Amount", value: request.formattedAmount)
                    SummaryRow(icon: request.urgencyLevel.icon, iconColor: request.urgencyLevel.color, label: "Urgency", value: request.urgencyLevel.displayName)
                    SummaryRow(icon: "calendar", iconColor: Color(hex: "#5B8A6B"), label: "Submitted", value: request.formattedCreatedDate)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 24)

            // What's Next
            VStack(alignment: .leading, spacing: 12) {
                Text("What's Next?")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                VStack(alignment: .leading, spacing: 10) {
                    NextStepRow(number: 1, text: "We'll review your request within 24-48 hours")
                    NextStepRow(number: 2, text: "You'll receive an email update on your status")
                    NextStepRow(number: 3, text: "We may reach out if we need more information")
                }
            }
            .padding(20)
            .background(Color(hex: "#5B8A6B").opacity(0.08))
            .cornerRadius(16)
            .padding(.horizontal, 24)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onViewHistory()
                } label: {
                    Text("View My Requests")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onDone()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(hex: "#F7F9F8").ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Summary Row

private struct SummaryRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#8B9A94"))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#2D3B35"))
        }
    }
}

// MARK: - Next Step Row

private struct NextStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#5B8A6B"))
                    .frame(width: 22, height: 22)

                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#5D6D66"))
        }
    }
}

#Preview {
    ReliefSuccessView(
        request: ReliefRequest(
            id: UUID(),
            userId: UUID(),
            fullName: "John Doe",
            email: "john@example.com",
            phone: nil,
            billType: .electric,
            billProvider: "DTE Energy",
            amountOwed: 250.00,
            description: nil,
            incomeLevel: .from25kTo50k,
            householdSize: 3,
            employmentStatus: .unemployed,
            urgencyLevel: .high,
            utilityShutoffDate: nil,
            status: .pending,
            statusNotes: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        onDone: { },
        onViewHistory: { }
    )
}
