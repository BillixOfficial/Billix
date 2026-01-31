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
    @State private var showBillSwap = false
    @State private var showRelief = false
    @State private var showNegotiationScript = false

    private var savings: Double {
        max(0, regionalAverage - targetAmount)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary header
                    VStack(spacing: 12) {
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

                        if savings > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "#4CAF7A"))

                                Text("Potential savings: $\(Int(savings))/mo")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "#4CAF7A"))

                                Spacer()
                            }
                            .padding(14)
                            .background(Color(hex: "#4CAF7A").opacity(0.1))
                            .cornerRadius(12)
                        }
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

                    // Disclaimer
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                        Text("Savings estimates based on regional data and may vary")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Color(hex: "#8B9A94").opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

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
        .fullScreenCover(isPresented: $showBillSwap) {
            BillSwapView()
        }
        .fullScreenCover(isPresented: $showRelief) {
            ReliefFlowView()
        }
        .sheet(isPresented: $showNegotiationScript) {
            NegotiationScriptSheet(billType: billType, targetAmount: targetAmount)
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
        case .openBillSwap:
            showBillSwap = true
        case .showNegotiationScript:
            showNegotiationScript = true
        case .openRelief:
            showRelief = true
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

                VStack(alignment: .trailing, spacing: 4) {
                    if let savings = option.potentialSavings {
                        Text("-$\(Int(savings))/mo")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#4CAF7A"))
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#8B9A94").opacity(0.5))
                }
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

#Preview {
    PriceOptionsSheet(
        billType: PriceBillType.electric,
        targetAmount: 100,
        regionalAverage: 153,
        options: [
            PriceOption(type: .betterRate, title: "2 better rates found in your area", subtitle: "Compare plans from local providers", potentialSavings: 20, action: .viewRates),
            PriceOption(type: .billSwap, title: "3 BillSwap matches available", subtitle: "Split costs with others in your area", potentialSavings: 15, action: .openBillSwap),
            PriceOption(type: .negotiation, title: "Negotiation scripts ready", subtitle: "Call your provider with proven tactics", potentialSavings: 12, action: .showNegotiationScript)
        ]
    )
}
