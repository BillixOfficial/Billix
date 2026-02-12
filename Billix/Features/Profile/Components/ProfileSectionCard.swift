//
//  ProfileSectionCard.swift
//  Billix
//
//  Created by Billix Team
//

import SwiftUI

/// Reusable white card container for profile sections (Uber-style)
struct ProfileSectionCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

/// Section header for profile cards
struct ProfileSectionHeader: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.billixDarkGreen)
            }

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.billixDarkGreen)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

/// Divider for separating rows in cards
struct ProfileDivider: View {
    var body: some View {
        Divider()
            .background(Color.gray.opacity(0.2))
            .padding(.leading, 16)
    }
}

// MARK: - Preview

struct ProfileSectionCard_Profile_Section_Card_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
        ProfileSectionCard {
        ProfileSectionHeader("Account Settings", icon: "person.circle.fill")
        
        VStack(spacing: 0) {
        SettingsRow(
        title: "Edit Profile",
        subtitle: "Update your name and photo",
        icon: "pencil",
        action: {}
        )
        
        ProfileDivider()
        
        SettingsRow(
        title: "Notifications",
        subtitle: "Manage your alerts",
        icon: "bell.fill",
        action: {}
        )
        }
        .padding(.bottom, 8)
        }
        
        ProfileSectionCard {
        VStack(alignment: .leading, spacing: 12) {
        Text("Simple Content")
        .font(.headline)
        
        Text("This is a basic card with custom content")
        .font(.subheadline)
        .foregroundColor(.gray)
        }
        .padding(16)
        }
        }
        .padding()
        .background(Color.billixLightGreen)
    }
}
