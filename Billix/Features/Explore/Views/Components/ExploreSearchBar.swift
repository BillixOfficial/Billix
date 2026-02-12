//
//  ExploreSearchBar.swift
//  Billix
//
//  Created by Claude Code on 1/7/26.
//  Search bar with voice input for Explore landing screen
//

import SwiftUI

struct ExploreSearchBar: View {
    @Binding var searchQuery: String
    let onVoiceSearch: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Pill-shaped search field
            HStack(spacing: 12) {
                // Search icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#8B9A94"))

                // Text field
                TextField("Search financial news, trends, data...", text: $searchQuery)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#2D3B35"))
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

            // Separate circular mic button
            Button(action: onVoiceSearch) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .frame(width: 48, height: 48)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }
}

struct ExploreSearchBar_Search_Bar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
        ExploreSearchBar(
        searchQuery: .constant(""),
        onVoiceSearch: {}
        )
        
        ExploreSearchBar(
        searchQuery: .constant("New York"),
        onVoiceSearch: {}
        )
        }
        .padding()
        .background(Color.billixCreamBeige.opacity(0.3))
    }
}
