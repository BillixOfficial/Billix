//
//  ProfileHeaderView.swift
//  Billix
//
//  Created by Billix Team
//

import SwiftUI

/// Profile header with avatar, name, location, and verification (Uber-style)
struct ProfileHeaderView: View {
    let profile: UserProfile
    let onEditTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Avatar with edit button
            ZStack(alignment: .bottomTrailing) {
                // Avatar circle
                if let avatarURL = profile.avatarURL {
                    // In a real app, load from URL
                    AsyncImage(url: URL(string: avatarURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        avatarPlaceholder
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                }

                // Edit button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onEditTap()
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.billixMoneyGreen)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                        )
                }
                .offset(x: 4, y: 4)
            }
            .padding(.top, 8)

            // Name
            Text(profile.fullName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(Color.billixDarkGreen)

            // Location
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                Text(profile.locationString)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }

            // Verification badges
            HStack(spacing: 8) {
                if profile.isEmailVerified {
                    VerificationBadge(
                        icon: "envelope.fill",
                        text: "Email Verified",
                        color: .billixMoneyGreen
                    )
                }

                if profile.isPhoneVerified {
                    VerificationBadge(
                        icon: "phone.fill",
                        text: "Phone Verified",
                        color: .billixMoneyGreen
                    )
                }

                if !profile.isEmailVerified || !profile.isPhoneVerified {
                    VerificationBadge(
                        icon: "exclamationmark.triangle.fill",
                        text: "Verify Account",
                        color: .billixGoldenAmber
                    )
                }
            }

            // Member stats
            HStack(spacing: 24) {
                // Member since
                VStack(spacing: 4) {
                    Text(profile.memberSinceString)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Divider()
                    .frame(height: 16)

                // Bills uploaded
                VStack(spacing: 4) {
                    Text("\(profile.totalBillsUploaded) bills uploaded")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }

            // User badges
            if !profile.badges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(profile.badges, id: \.self) { badge in
                            BadgePill(badge: badge)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.billixMoneyGreen, Color.billixDarkGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)

            Text(profile.initials)
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

/// Verification badge chip
struct VerificationBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))

            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color)
        .cornerRadius(12)
    }
}

/// User badge pill
struct BadgePill: View {
    let badge: UserBadge

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: badge.icon)
                .font(.system(size: 12))

            Text(badge.rawValue)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(Color.billixDarkGreen)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.billixLightGreen)
        .cornerRadius(16)
    }
}

// MARK: - Preview

struct ProfileHeaderView_Profile_Header_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
        // Verified user
        ProfileHeaderView(
        profile: .preview,
        onEditTap: {}
        )
        
        // Unverified user
        ProfileHeaderView(
        profile: .previewUnverified,
        onEditTap: {}
        )
        
        // Power user
        ProfileHeaderView(
        profile: .previewPowerUser,
        onEditTap: {}
        )
        }
        .padding()
        .background(Color.billixLightGreen)
    }
}
