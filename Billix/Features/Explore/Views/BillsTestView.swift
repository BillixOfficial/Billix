//
//  BillsTestView.swift
//  Billix
//
//  Created by Claude Code on 1/7/26.
//  Test view for Bills navigation
//

import SwiftUI

struct BillsTestView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "#F3F4F6")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Hi")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Button("Go Back") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.billixMediumGreen)
                .cornerRadius(12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Bills")
    }
}

struct BillsTestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
        BillsTestView()
        }
    }
}
