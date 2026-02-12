//
//  PrivacyInfoSheet.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  Privacy explanation sheet for marketplace data
//

import SwiftUI

/// Privacy information sheet explaining data anonymization
struct PrivacyInfoSheet: View {

    // MARK: - Properties

    @Binding var isPresented: Bool

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero icon
                    HStack {
                        Spacer()
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 60))
                            .foregroundColor(.billixPurple)
                        Spacer()
                    }
                    .padding(.top, 20)

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Privacy Matters")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("How we protect your data in the marketplace")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Privacy features
                    VStack(alignment: .leading, spacing: 20) {
                        PrivacyFeature(
                            icon: "lock.fill",
                            title: "100% Anonymous",
                            description: "Your personal information is never shared. We only show aggregated data from similar bills in your area."
                        )

                        PrivacyFeature(
                            icon: "person.2.fill",
                            title: "Aggregated Data",
                            description: "Price ranges require at least 5 similar bills to appear. Individual bills are never displayed."
                        )

                        PrivacyFeature(
                            icon: "blur",
                            title: "Fuzzy Visualization",
                            description: "Price ranges are intentionally blurred. Hold to reveal for comparison, then auto-hide after 2 seconds."
                        )

                        PrivacyFeature(
                            icon: "mappin.slash.circle.fill",
                            title: "Location Privacy",
                            description: "We only use the first 3 digits of your ZIP code (482, not 48201) to group similar areas."
                        )

                        PrivacyFeature(
                            icon: "checkmark.shield.fill",
                            title: "No Tracking",
                            description: "We don't track which bills you view or compare. Your browsing is completely private."
                        )
                    }

                    Divider()

                    // Learn more
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Questions?")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Read our full Privacy Policy or contact support for more information about how we handle your data.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
            }
            .background(Color.billixCreamBeige)
            .navigationTitle("Privacy & Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.billixPurple)
                }
            }
        }
    }
}

// MARK: - Privacy Feature Row

struct PrivacyFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.billixPurple)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.billixPurple.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Previews

struct PrivacyInfoSheet_Privacy_Info_Sheet_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyInfoSheet(isPresented: .constant(true))
    }
}
