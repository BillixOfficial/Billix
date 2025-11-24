//
//  QuickAddStep1BillType.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct QuickAddStep1BillType: View {
    @ObservedObject var viewModel: QuickAddViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("What type of bill do you want to add?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.billTypes) { billType in
                            BillTypeCard(billType: billType, isSelected: viewModel.selectedBillType?.id == billType.id)
                                .onTapGesture {
                                    viewModel.selectBillType(billType)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

struct BillTypeCard: View {
    let billType: BillType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: billType.icon)
                .font(.system(size: 40))
                .foregroundColor(isSelected ? .white : .billixMoneyGreen)

            Text(billType.name)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.billixMoneyGreen : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.billixMoneyGreen : Color.clear, lineWidth: 2)
        )
    }
}
