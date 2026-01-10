//
//  ImportBillSheet.swift
//  Billix
//
//  Import Bill Sheet - Import from Upload Feature
//

import SwiftUI

struct ImportBillSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BillSwapViewModel

    // State for fetching uploaded bills
    @State private var uploadedBills: [BillAnalysis] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedBill: BillAnalysis?
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header explanation
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.billixDarkTeal)

                    Text("Import from Uploads")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Select a bill you've already uploaded to add it to Bill Swap")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(Color.billixDarkTeal.opacity(0.05))

                if isLoading {
                    Spacer()
                    ProgressView("Loading uploaded bills...")
                    Spacer()
                } else if uploadedBills.isEmpty {
                    EmptyUploadStateView()
                } else {
                    // Bills list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(uploadedBills, id: \.id) { bill in
                                ImportableBillRow(
                                    bill: bill,
                                    isSelected: selectedBill?.id == bill.id,
                                    isEligible: isBillEligibleForSwap(bill)
                                ) {
                                    if isBillEligibleForSwap(bill) {
                                        selectedBill = bill
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }

                // Import button
                if selectedBill != nil {
                    VStack(spacing: 12) {
                        if let bill = selectedBill {
                            SelectedBillSummary(bill: bill)
                        }

                        Button(action: importSelectedBill) {
                            HStack {
                                if isImporting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.down.doc")
                                    Text("Import to Bill Swap")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.billixMoneyGreen)
                            .cornerRadius(12)
                        }
                        .disabled(isImporting)
                    }
                    .padding(16)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
                }
            }
            .navigationTitle("Import Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadUploadedBills()
            }
            .alert("Import Error", isPresented: .constant(error != nil)) {
                Button("OK") { error = nil }
            } message: {
                Text(error?.localizedDescription ?? "Unknown error")
            }
        }
    }

    // MARK: - Helper Methods

    private func loadUploadedBills() {
        isLoading = true
        // In a real implementation, this would fetch from the Upload feature's data
        // For now, we'll use mock data or fetch from local storage
        Task {
            // Simulate loading
            try? await Task.sleep(nanoseconds: 500_000_000)

            // This would normally call a service to get uploaded bills
            // uploadedBills = await UploadService.shared.getRecentUploads()

            // Mock data for demonstration
            uploadedBills = createMockUploadedBills()
            isLoading = false
        }
    }

    private func isBillEligibleForSwap(_ bill: BillAnalysis) -> Bool {
        // Check amount is within swap range ($20-$200)
        let amountCents = Int(bill.amount * 100)
        guard amountCents >= 2000 && amountCents <= 20000 else { return false }

        // Check user's tier limit
        if let profile = viewModel.trustProfile {
            guard amountCents <= profile.tier.maxBillCents else { return false }
        }

        return true
    }

    private func importSelectedBill() {
        guard let bill = selectedBill else { return }

        isImporting = true

        Task {
            do {
                let _ = try await viewModel.importBillFromAnalysis(bill)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                self.error = error
                isImporting = false
            }
        }
    }

    private func createMockUploadedBills() -> [BillAnalysis] {
        // Mock data for preview/testing
        // In production, this would fetch from the Upload feature's stored analyses
        return BillAnalysis.mockBillsForSwapImport
    }
}

// MARK: - BillAnalysis Extension for Swap Import

extension BillAnalysis {
    /// Unique identifier for ForEach
    var id: String {
        "\(provider)-\(billDate)-\(amount)"
    }

    /// Due date as Date for display
    var dueDateAsDate: Date? {
        guard let dueDateStr = dueDate else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: dueDateStr)
    }

    /// Mock bills for testing import functionality
    static var mockBillsForSwapImport: [BillAnalysis] {
        let decoder = JSONDecoder()

        let mockJSON = """
        [
            {
                "provider": "Duke Energy",
                "amount": 85.00,
                "billDate": "2024-12-01",
                "dueDate": "2024-12-15",
                "accountNumber": "4521",
                "category": "Electric",
                "zipCode": "12345",
                "lineItems": [{"description": "Electric Service", "amount": 85.00}]
            },
            {
                "provider": "Comcast",
                "amount": 79.99,
                "billDate": "2024-12-01",
                "dueDate": "2024-12-12",
                "accountNumber": "7823",
                "category": "Internet",
                "zipCode": "12345",
                "lineItems": [{"description": "Internet Service", "amount": 79.99}]
            },
            {
                "provider": "City Water",
                "amount": 45.50,
                "billDate": "2024-12-01",
                "dueDate": "2024-12-10",
                "accountNumber": "2198",
                "category": "Water",
                "zipCode": "12345",
                "lineItems": [{"description": "Water Service", "amount": 45.50}]
            },
            {
                "provider": "AT&T",
                "amount": 250.00,
                "billDate": "2024-12-01",
                "dueDate": "2024-12-20",
                "accountNumber": "5567",
                "category": "Phone",
                "zipCode": "12345",
                "lineItems": [{"description": "Phone Service", "amount": 250.00}]
            }
        ]
        """.data(using: .utf8)!

        do {
            return try decoder.decode([BillAnalysis].self, from: mockJSON)
        } catch {
            print("Mock decode error: \(error)")
            return []
        }
    }
}

// MARK: - Importable Bill Row

struct ImportableBillRow: View {
    let bill: BillAnalysis
    let isSelected: Bool
    let isEligible: Bool
    let onTap: () -> Void

    private var amountString: String {
        String(format: "$%.2f", bill.amount)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(isEligible ? Color.billixDarkTeal.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: categoryIcon)
                        .font(.system(size: 18))
                        .foregroundColor(isEligible ? .billixDarkTeal : .gray)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.provider)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isEligible ? .primary : .secondary)

                    HStack(spacing: 8) {
                        Text(bill.category)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        if let dueDate = bill.dueDateAsDate {
                            Text("Due \(dueDate, style: .date)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(amountString)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isEligible ? .primary : .secondary)

                    if !isEligible {
                        Text("Out of range")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }

                // Selection indicator
                if isEligible {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .billixMoneyGreen : .gray.opacity(0.3))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.billixMoneyGreen.opacity(0.08) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.billixMoneyGreen : Color.gray.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .disabled(!isEligible)
    }

    private var categoryIcon: String {
        switch bill.category.lowercased() {
        case "electric", "electricity": return "bolt.fill"
        case "gas": return "flame.fill"
        case "water": return "drop.fill"
        case "internet": return "wifi"
        case "phone": return "phone.fill"
        case "cable": return "tv.fill"
        default: return "doc.text.fill"
        }
    }
}

// MARK: - Selected Bill Summary

struct SelectedBillSummary: View {
    let bill: BillAnalysis

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Selected Bill")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(bill.provider)
                    .font(.system(size: 14, weight: .medium))
            }

            Spacer()

            Text(String(format: "$%.2f", bill.amount))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.billixDarkTeal)
        }
        .padding(12)
        .background(Color.billixDarkTeal.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - Empty State

struct EmptyUploadStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No bills to import")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)

            Text("Upload a bill first using the Upload tab, then come back here to add it to Bill Swap")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ImportBillSheet(viewModel: BillSwapViewModel())
}
