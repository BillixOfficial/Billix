//
//  EconomyHeaderView.swift
//  Billix
//
//  Created by Claude Code on 1/19/26.
//  Header component for Economy feed with greeting and search
//

import SwiftUI

struct EconomyHeaderView: View {
    let greeting: String
    let userName: String
    @Binding var searchText: String
    @State private var isSearching = false

    // Design spec colors
    private let accentBlue = Color(hex: "#3B6CFF")
    private let metadataGrey = Color(hex: "#8E8E93")
    private let buttonBackground = Color(hex: "#F3F4F6")

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Profile Section (Left)
                HStack(spacing: 12) {
                    // Profile Avatar
                    Circle()
                        .fill(accentBlue.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(userName.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(accentBlue)
                        )

                    // Greeting Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.system(size: 14))
                            .foregroundColor(metadataGrey)

                        Text(userName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                    }
                }

                Spacer()

                // Search Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isSearching.toggle()
                        if !isSearching {
                            searchText = ""
                        }
                    }
                } label: {
                    Circle()
                        .fill(buttonBackground)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                        )
                }
            }
            .padding(.horizontal, 20)

            // Search Bar (expandable)
            if isSearching {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(metadataGrey)

                    TextField("Search news...", text: $searchText)
                        .font(.system(size: 16))
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(metadataGrey)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(buttonBackground)
                )
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .padding(.top, 8)
    }
}

struct EconomyHeaderView_Economy_Header_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        Color.white
        .ignoresSafeArea()
        
        VStack {
        EconomyHeaderView(
        greeting: "Good Morning",
        userName: "John",
        searchText: .constant("")
        )
        Spacer()
        }
        }
    }
}
