//
//  PropertySearchBar.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  ZIP code or address input field for property search
//

import SwiftUI

struct PropertySearchBar: View {
    @Binding var address: String
    let placeholder: String

    init(address: Binding<String>, placeholder: String = "ZIP code or address") {
        self._address = address
        self.placeholder = placeholder
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.billixDarkTeal)

            TextField(placeholder, text: $address)
                .font(.system(size: 16))
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .accessibilityLabel("Property search address")
                .accessibilityHint("Enter ZIP code or full address to search")

            if !address.isEmpty {
                Button {
                    address = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear address")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}

struct PropertySearchBar_Property_Search_Bar___Empty_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
        PropertySearchBar(address: .constant(""), placeholder: "ZIP code or address")
        PropertySearchBar(address: .constant("48067"), placeholder: "ZIP code or address")
        PropertySearchBar(address: .constant("418 N Center St, Royal Oak, MI 48067"), placeholder: "ZIP code or address")
        }
        .padding()
        .background(Color.billixCreamBeige)
    }
}
