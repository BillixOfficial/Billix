import SwiftUI

struct AnalysisResultsView: View {
    let analysis: BillAnalysis
    let onSave: () -> Void
    let onDismiss: () -> Void

    @State private var showingSaveConfirmation = false
    @State private var showBottomSheet = false

    var body: some View {
        ZStack {
            Color.billixCreamBeige.ignoresSafeArea()

            VStack(spacing: 24) {
                // Success animation header
                successHeader
                    .padding(.top, 40)

                // Hero summary card
                BillSummaryCard(
                    analysis: analysis,
                    onShare: shareAction,
                    onEdit: editAction,
                    onDelete: deleteAction
                )
                .padding(.horizontal, 20)
                .onTapGesture {
                    showBottomSheet = true
                }

                Spacer(minLength: 20)

                // Quick CTA
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.billixDarkTeal)
                        Text("Tap the card or swipe up to view details")
                            .font(.subheadline)
                            .foregroundColor(.billixDarkTeal)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)

                // Action buttons
                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showBottomSheet) {
            BillDetailBottomSheet(analysis: analysis)
        }
        .alert("Bill Saved!", isPresented: $showingSaveConfirmation) {
            Button("OK", action: onDismiss)
        } message: {
            Text("Your bill has been saved successfully.")
        }
        .onAppear {
            // Auto-show bottom sheet after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showBottomSheet = true
            }
        }
    }

    // MARK: - View Components

    private var successHeader: some View {
        VStack(spacing: 16) {
            // Animated success checkmark
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.billixMoneyGreen.opacity(0.2), Color.billixDarkTeal.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.billixMoneyGreen, Color.billixDarkTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .phaseAnimator([false, true]) { content, phase in
                content
                    .scaleEffect(phase ? 1.1 : 1.0)
                    .opacity(phase ? 1.0 : 0.8)
            } animation: { _ in
                .spring(duration: 1.0, bounce: 0.4)
            }

            VStack(spacing: 8) {
                Text("Bill Analyzed Successfully")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.billixNavyBlue)

                Text("AI has processed your bill and found insights")
                    .font(.subheadline)
                    .foregroundColor(.billixDarkTeal)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                onSave()
                showingSaveConfirmation = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("Save Bill")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.billixMoneyGreen, Color.billixDarkTeal],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.billixMoneyGreen.opacity(0.3), radius: 10, x: 0, y: 5)
            }

            Button(action: onDismiss) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                    Text("Upload Another Bill")
                        .font(.headline)
                }
                .foregroundColor(.billixNavyBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.billixNavyBlue.opacity(0.1), radius: 5, x: 0, y: 3)
            }
        }
    }

    // MARK: - Actions

    private func shareAction() {
        // TODO: Implement share functionality
        print("Share tapped")
    }

    private func editAction() {
        // TODO: Implement edit functionality
        print("Edit tapped")
    }

    private func deleteAction() {
        // TODO: Implement delete functionality
        print("Delete tapped")
    }
}
