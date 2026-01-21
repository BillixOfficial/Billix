//
//  ReliefHistoryView.swift
//  Billix
//
//  View for displaying user's relief request history
//

import SwiftUI

struct ReliefHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var reliefService = ReliefService.shared
    @State private var selectedRequest: ReliefRequest?

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F7F9F8").ignoresSafeArea()

                if reliefService.isLoading {
                    ProgressView("Loading requests...")
                } else if reliefService.myRequests.isEmpty {
                    emptyState
                } else {
                    requestsList
                }
            }
            .navigationTitle("My Relief Requests")
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
                try? await reliefService.fetchMyRequests()
            }
            .sheet(item: $selectedRequest) { request in
                ReliefDetailView(request: request)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundColor(.red)
            }

            VStack(spacing: 8) {
                Text("No Requests Yet")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("When you submit a relief request,\nit will appear here.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Requests List

    private var requestsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(reliefService.myRequests) { request in
                    RequestCard(request: request) {
                        selectedRequest = request
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Request Card

struct RequestCard: View {
    let request: ReliefRequest
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Bill type icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(request.billType.color.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: request.billType.icon)
                            .font(.system(size: 20))
                            .foregroundColor(request.billType.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.billType.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        if let provider = request.billProvider, !provider.isEmpty {
                            Text(provider)
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#8B9A94"))
                        }
                    }

                    Spacer()

                    // Status badge
                    HStack(spacing: 4) {
                        Image(systemName: request.status.icon)
                            .font(.system(size: 10))
                        Text(request.status.displayName)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(request.status.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(request.status.color.opacity(0.12))
                    .cornerRadius(12)
                }

                Divider()

                // Details
                HStack(spacing: 20) {
                    // Amount
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Amount")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#8B9A94"))
                        Text(request.formattedAmount)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.red)
                    }

                    // Urgency
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Urgency")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#8B9A94"))
                        HStack(spacing: 4) {
                            Image(systemName: request.urgencyLevel.icon)
                                .font(.system(size: 11))
                            Text(request.urgencyLevel.displayName)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(request.urgencyLevel.color)
                    }

                    Spacer()

                    // Date
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Submitted")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#8B9A94"))
                        Text(request.formattedCreatedDate)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#2D3B35"))
                    }
                }

                // Shutoff warning if applicable
                if request.isShutoffImminent, let days = request.daysUntilShutoff {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)

                        Text("Shutoff in \(days) day\(days == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ReliefHistoryView()
}
