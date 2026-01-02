//
//  QuickActionsZone.swift
//  Billix
//

import SwiftUI

// MARK: - Quick Action Type

enum QuickActionType: String, Identifiable {
    case addBill = "Add Bill"
    case chat = "Chat"
    case compare = "Swap"
    case budget = "Budget"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .addBill: return "plus.circle.fill"
        case .chat: return "message.fill"
        case .compare: return "arrow.left.arrow.right.circle.fill"
        case .budget: return "chart.pie.fill"
        }
    }

    var color: Color {
        switch self {
        case .addBill: return HomeTheme.accent
        case .chat: return HomeTheme.info
        case .compare: return HomeTheme.purple
        case .budget: return HomeTheme.warning
        }
    }

    var subtitle: String? {
        switch self {
        case .compare: return "Bill Swap"
        default: return nil
        }
    }
}

// MARK: - Quick Actions Zone

struct QuickActionsZone: View {
    @State private var showSwapHub = false
    @State private var showAddBill = false
    @State private var showChat = false
    @State private var showBudget = false

    private let actions: [QuickActionType] = [.addBill, .chat, .compare, .budget]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(actions) { action in
                Button {
                    haptic()
                    handleAction(action)
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(action.color.opacity(0.12))
                                .frame(width: 52, height: 52)

                            Image(systemName: action.icon)
                                .font(.system(size: 22))
                                .foregroundColor(action.color)
                        }

                        VStack(spacing: 2) {
                            Text(action.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(HomeTheme.primaryText)

                            if let subtitle = action.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(action.color)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(14)
        .background(HomeTheme.cardBackground)
        .cornerRadius(HomeTheme.cornerRadius)
        .shadow(color: HomeTheme.shadowColor, radius: HomeTheme.shadowRadius, x: 0, y: 2)
        .padding(.horizontal, HomeTheme.horizontalPadding)
        .fullScreenCover(isPresented: $showSwapHub) {
            SwapHubView()
        }
        .sheet(isPresented: $showAddBill) {
            AddBillActionSheet()
        }
        .sheet(isPresented: $showChat) {
            ChatHubView()
        }
        .sheet(isPresented: $showBudget) {
            BudgetOverviewView()
        }
    }

    private func handleAction(_ action: QuickActionType) {
        switch action {
        case .compare: showSwapHub = true
        case .addBill: showAddBill = true
        case .chat: showChat = true
        case .budget: showBudget = true
        }
    }
}
