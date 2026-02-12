//
//  SweepstakesOfficialRulesView.swift
//  Billix
//
//  Created by Claude Code
//  Legal-compliant official rules for Weekly Sweepstakes
//  Based on DoorDash and industry best practices
//

import SwiftUI

struct SweepstakesOfficialRulesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("Weekly Sweepstakes Official Rules")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.billixDarkGreen)
                        .padding(.bottom, 8)

                    // NO PURCHASE NECESSARY - Must be prominent
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NO PURCHASE NECESSARY")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.red)

                        Text("Purchase will not increase your chances of winning. Alternative free entry method available.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(12)

                    // 1. Eligibility
                    rulesSection(
                        number: "1",
                        title: "ELIGIBILITY",
                        content: "Open to legal residents of the 50 United States and District of Columbia who are 18 years of age or older at time of entry. Employees, contractors, and agents of Billix, Inc., and their immediate family members and household members, are not eligible. Subject to all federal, state, and local laws and regulations. Void where prohibited."
                    )

                    // 2. Sweepstakes Period
                    rulesSection(
                        number: "2",
                        title: "SWEEPSTAKES PERIOD",
                        content: "Weekly draw period: Monday 12:00:00 AM Eastern Time (\"ET\") through Sunday 8:00:00 PM ET. Winners will be selected and notified within 48 hours of draw closing."
                    )

                    // 3. How to Enter
                    VStack(alignment: .leading, spacing: 12) {
                        ruleSectionHeader(number: "3", title: "HOW TO ENTER")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Points Entry:")
                                .font(.system(size: 14, weight: .bold))
                            + Text(" Use earned Billix Rewards points to purchase sweepstakes entries. Each entry costs 100 points. Maximum 10 entries per person per weekly draw.")
                                .font(.system(size: 14))

                            Text("• Alternative Free Entry (AMOE):")
                                .font(.system(size: 14, weight: .bold))
                            + Text(" Send an email to sweepstakes@billixapp.com with your name, email address, and \"Weekly Sweepstakes Entry\" in the subject line. Limit one free entry per person per weekly draw.")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.primary)

                        Text("All entries have equal chance of winning regardless of entry method. Entries received after 8:00 PM ET on Sunday will apply to the following week's draw.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.top, 4)
                    }

                    // 4. Prize
                    VStack(alignment: .leading, spacing: 12) {
                        ruleSectionHeader(number: "4", title: "PRIZE")

                        Text("One (1) weekly prize: $50 payment toward winner's bill. Approximate Retail Value (\"ARV\"): $50.00 USD.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.billixMoneyGreen)

                        Text("Winner will be contacted via email to specify which bill to apply the $50 payment. Billix will pay the specified bill provider directly on winner's behalf via check or online guest payment (if available). Payment can be applied in full ($50) or partially toward the bill. No cash alternative. Prize is non-transferable.")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)

                        Text("Winner must provide valid bill account information within 7 days of notification. If bill amount is less than $50, payment will equal the bill amount (no excess cash given).")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    // 5. Winner Selection
                    rulesSection(
                        number: "5",
                        title: "WINNER SELECTION",
                        content: "Winner will be selected by random draw from all eligible entries received during the sweepstakes period. Drawing will be conducted within 48 hours after draw period ends on Sunday at 8:00 PM ET. Odds of winning depend on total number of eligible entries received."
                    )

                    // 6. Winner Notification
                    rulesSection(
                        number: "6",
                        title: "WINNER NOTIFICATION",
                        content: "Potential winner will be notified via email to the address associated with their Billix account within 48 hours of selection. Potential winner must respond within 72 hours of notification or prize may be forfeited. Winner's name may be posted in-app."
                    )

                    // 7. General Conditions
                    rulesSection(
                        number: "7",
                        title: "GENERAL CONDITIONS",
                        content: "By entering, participants agree to be bound by these Official Rules. Sponsor reserves the right to disqualify any entry that: (a) is submitted through automated entry devices; (b) violates these Official Rules; or (c) is deemed fraudulent."
                    )

                    // 8. Privacy
                    rulesSection(
                        number: "8",
                        title: "PRIVACY",
                        content: "Information collected from participants will be used in accordance with Billix's Privacy Policy. Winner's email address will be used solely for prize notification and fulfillment."
                    )

                    // 9. Sponsor
                    VStack(alignment: .leading, spacing: 8) {
                        ruleSectionHeader(number: "9", title: "SPONSOR")

                        Text("Billix, Inc.")
                            .font(.system(size: 14, weight: .semibold))

                        Text("Questions? Contact: sweepstakes@billixapp.com")
                            .font(.system(size: 14))
                            .foregroundColor(.billixMoneyGreen)
                    }

                    // Footer
                    Text("© 2026 Billix, Inc. All Rights Reserved.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    private func ruleSectionHeader(number: String, title: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.billixDarkGreen)

            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.billixDarkGreen)
        }
    }

    private func rulesSection(number: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ruleSectionHeader(number: number, title: title)

            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

struct SweepstakesOfficialRulesView_Previews: PreviewProvider {
    static var previews: some View {
        SweepstakesOfficialRulesView()
    }
}
