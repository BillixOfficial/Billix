//
//  GuidedClaimView.swift
//  Billix
//
//  Guided claim submission with pre-filled script and provider contacts
//

import SwiftUI

struct GuidedClaimView: View {
    @ObservedObject var viewModel: OutageBotViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showCopiedToast = false
    @State private var showApproveSheet = false
    @State private var showDenySheet = false
    @State private var approvedAmount: String = ""
    @State private var denyReason: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MarketplaceTheme.Spacing.lg) {
                    // Claim status header
                    claimStatusHeader

                    // Claim script section
                    if let script = viewModel.currentClaimScript ?? viewModel.currentClaim.map({ GeneratedClaimScript(script: $0.claimScript ?? "", supportUrl: $0.supportUrl, supportPhone: $0.supportPhone, tips: []) }) {
                        claimScriptSection(script: script)
                    }

                    // Contact options
                    contactOptionsSection

                    // Tips section
                    if let script = viewModel.currentClaimScript, !script.tips.isEmpty {
                        tipsSection(tips: script.tips)
                    }

                    Spacer(minLength: MarketplaceTheme.Spacing.lg)

                    // Action buttons based on status
                    actionButtons
                }
                .padding(MarketplaceTheme.Spacing.md)
            }
            .navigationTitle("Claim Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showCopiedToast {
                    copiedToast
                }
            }
            .sheet(isPresented: $showApproveSheet) {
                approveSheet
            }
            .sheet(isPresented: $showDenySheet) {
                denySheet
            }
        }
    }

    // MARK: - Claim Status Header

    private var claimStatusHeader: some View {
        VStack(spacing: MarketplaceTheme.Spacing.md) {
            if let claim = viewModel.currentClaim {
                // Status badge
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Image(systemName: claim.status.icon)
                        .font(.system(size: 14))

                    Text(claim.status.displayName)
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                }
                .foregroundStyle(claim.status.color)
                .padding(.horizontal, MarketplaceTheme.Spacing.sm)
                .padding(.vertical, MarketplaceTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(claim.status.color.opacity(0.1))
                )

                // Provider and date
                VStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Text(claim.providerName)
                        .font(.system(size: MarketplaceTheme.Typography.title2, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    Text("\(claim.formattedOutageDate) • \(claim.formattedDuration) outage")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                // Amount
                VStack(spacing: 2) {
                    Text(claim.status == .approved ? "Credit Received" : "Estimated Credit")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text(claim.displayCredit)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(claim.status == .approved ? Color(hex: "#22C55E") : MarketplaceTheme.Colors.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(MarketplaceTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.xl)
                .fill(MarketplaceTheme.Colors.backgroundSecondary)
        )
    }

    // MARK: - Claim Script Section

    private func claimScriptSection(script: GeneratedClaimScript) -> some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            HStack {
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#8B5CF6"))

                    Text("Claim Script")
                        .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                }

                Spacer()

                Button {
                    copyToClipboard(script.script)
                } label: {
                    HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))

                        Text("Copy")
                            .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                    }
                    .foregroundStyle(Color(hex: "#8B5CF6"))
                    .padding(.horizontal, MarketplaceTheme.Spacing.sm)
                    .padding(.vertical, MarketplaceTheme.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.sm)
                            .fill(Color(hex: "#8B5CF6").opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }

            // Script text
            Text(script.script)
                .font(.system(size: MarketplaceTheme.Typography.callout))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                .padding(MarketplaceTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                        .fill(MarketplaceTheme.Colors.backgroundCard)
                        .stroke(Color(hex: "#8B5CF6").opacity(0.3), lineWidth: 1)
                )

            // Customize hint
            Text("Customize this script with your account number before contacting support.")
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
    }

    // MARK: - Contact Options

    private var contactOptionsSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            Text("Contact Support")
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                // Online support
                if let urlString = viewModel.currentClaim?.supportUrl ?? viewModel.currentClaimScript?.supportUrl,
                   let url = URL(string: urlString) {
                    Button {
                        openURL(url)
                    } label: {
                        VStack(spacing: MarketplaceTheme.Spacing.xs) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 20))

                            Text("Online Chat")
                                .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                        }
                        .foregroundStyle(Color(hex: "#3B82F6"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MarketplaceTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                .fill(Color(hex: "#3B82F6").opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Phone support
                if let phone = viewModel.currentClaim?.supportPhone ?? viewModel.currentClaimScript?.supportPhone,
                   let url = URL(string: "tel:\(phone.replacingOccurrences(of: "-", with: ""))") {
                    Button {
                        openURL(url)
                    } label: {
                        VStack(spacing: MarketplaceTheme.Spacing.xs) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 20))

                            Text("Call")
                                .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))

                            Text(phone)
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(Color(hex: "#22C55E"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MarketplaceTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                .fill(Color(hex: "#22C55E").opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Tips Section

    private func tipsSection(tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#F59E0B"))

                Text("Tips for Success")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
            }

            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xs) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: MarketplaceTheme.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#22C55E"))

                        Text(tip)
                            .font(.system(size: MarketplaceTheme.Typography.caption))
                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    }
                }
            }
            .padding(MarketplaceTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                    .fill(Color(hex: "#F59E0B").opacity(0.1))
            )
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            if let claim = viewModel.currentClaim {
                switch claim.status {
                case .detected, .confirmed, .scriptReady:
                    // Mark as submitted
                    Button {
                        Task {
                            await viewModel.markClaimSubmitted()
                        }
                    } label: {
                        HStack(spacing: MarketplaceTheme.Spacing.xs) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16))

                            Text("I've Submitted My Claim")
                                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MarketplaceTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                .fill(Color(hex: "#8B5CF6"))
                        )
                    }
                    .buttonStyle(.plain)

                case .submitted:
                    // Mark outcome
                    HStack(spacing: MarketplaceTheme.Spacing.sm) {
                        Button {
                            approvedAmount = String(format: "%.2f", claim.estimatedCredit)
                            showApproveSheet = true
                        } label: {
                            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))

                                Text("Approved")
                                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MarketplaceTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                    .fill(Color(hex: "#22C55E"))
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            showDenySheet = true
                        } label: {
                            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))

                                Text("Denied")
                                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MarketplaceTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                    .fill(Color(hex: "#EF4444"))
                            )
                        }
                        .buttonStyle(.plain)
                    }

                case .approved:
                    // Show integration options
                    integrationButtons

                case .denied:
                    // Show try again / switch provider options
                    VStack(spacing: MarketplaceTheme.Spacing.xs) {
                        Text("Claim was denied")
                            .font(.system(size: MarketplaceTheme.Typography.caption))
                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                        if let response = claim.providerResponse {
                            Text(response)
                                .font(.system(size: MarketplaceTheme.Typography.caption))
                                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                                .italic()
                        }
                    }
                    .padding(MarketplaceTheme.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                            .fill(Color(hex: "#EF4444").opacity(0.1))
                    )

                    integrationButtons

                default:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Integration Buttons

    private var integrationButtons: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Compare providers button
            Button {
                // TODO: Navigate to Marketplace
                dismiss()
            } label: {
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14))

                    Text("Compare Other Providers")
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .medium))
                }
                .foregroundStyle(Color(hex: "#8B5CF6"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(Color(hex: "#8B5CF6").opacity(0.1))
                )
            }
            .buttonStyle(.plain)

            // Set strike price button
            Button {
                // TODO: Navigate to Make Me Move
                dismiss()
            } label: {
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Image(systemName: "target")
                        .font(.system(size: 14))

                    Text("Set Strike Price to Switch")
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .medium))
                }
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MarketplaceTheme.Spacing.sm)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Approve Sheet

    private var approveSheet: some View {
        NavigationStack {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: "#22C55E"))

                Text("Credit Approved!")
                    .font(.system(size: MarketplaceTheme.Typography.title2, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                    Text("Enter the actual credit amount:")
                        .font(.system(size: MarketplaceTheme.Typography.body))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                    HStack {
                        Text("$")
                            .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        TextField("0.00", text: $approvedAmount)
                            .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                            .keyboardType(.decimalPad)
                    }
                    .padding(MarketplaceTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                            .fill(MarketplaceTheme.Colors.backgroundSecondary)
                    )
                }

                Spacer()

                Button {
                    if let amount = Double(approvedAmount) {
                        Task {
                            await viewModel.markClaimApproved(actualCredit: amount)
                            showApproveSheet = false
                        }
                    }
                } label: {
                    Text("Confirm")
                        .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MarketplaceTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                .fill(Color(hex: "#22C55E"))
                        )
                }
                .buttonStyle(.plain)
                .disabled(Double(approvedAmount) == nil)
            }
            .padding(MarketplaceTheme.Spacing.lg)
            .navigationTitle("Credit Approved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showApproveSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color(hex: "#F5F7F6"))
    }

    // MARK: - Deny Sheet

    private var denySheet: some View {
        NavigationStack {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: "#EF4444"))

                Text("Claim Denied")
                    .font(.system(size: MarketplaceTheme.Typography.title2, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                    Text("What reason did they give? (optional)")
                        .font(.system(size: MarketplaceTheme.Typography.body))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                    TextField("Enter reason...", text: $denyReason, axis: .vertical)
                        .lineLimit(3...5)
                        .font(.system(size: MarketplaceTheme.Typography.callout))
                        .padding(MarketplaceTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                .fill(MarketplaceTheme.Colors.backgroundSecondary)
                        )
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.markClaimDenied(reason: denyReason.isEmpty ? nil : denyReason)
                        showDenySheet = false
                    }
                } label: {
                    Text("Confirm")
                        .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MarketplaceTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                .fill(Color(hex: "#EF4444"))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(MarketplaceTheme.Spacing.lg)
            .navigationTitle("Claim Denied")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showDenySheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color(hex: "#F5F7F6"))
    }

    // MARK: - Copied Toast

    private var copiedToast: some View {
        VStack {
            Spacer()

            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))

                Text("Copied to clipboard")
                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, MarketplaceTheme.Spacing.lg)
            .padding(.vertical, MarketplaceTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
            .padding(.bottom, MarketplaceTheme.Spacing.xl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3), value: showCopiedToast)
    }

    // MARK: - Helpers

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        withAnimation {
            showCopiedToast = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                showCopiedToast = false
            }
        }
    }
}

// MARK: - Preview

struct GuidedClaimView_Previews: PreviewProvider {
    static var previews: some View {
        GuidedClaimView(viewModel: .preview)
    }
}
