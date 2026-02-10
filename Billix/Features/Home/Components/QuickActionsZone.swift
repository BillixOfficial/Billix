//
//  QuickActionsZone.swift
//  Billix
//

import SwiftUI

// MARK: - Quick Action Type

enum QuickActionType: String, Identifiable {
    case addBill = "Add Bill"
    case chat = "Chat"
    case connect = "Connect"
    case budget = "Budget"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .addBill: return "plus.circle.fill"
        case .chat: return "message.fill"
        case .connect: return "person.2.fill"
        case .budget: return "chart.pie.fill"
        }
    }

    var color: Color {
        switch self {
        case .addBill: return HomeTheme.accent
        case .chat: return HomeTheme.info
        case .connect: return Color.billixDarkTeal
        case .budget: return HomeTheme.warning
        }
    }

    var subtitle: String? {
        switch self {
        case .connect: return "Community"
        default: return nil
        }
    }
}

// MARK: - Quick Actions Zone

struct QuickActionsZone: View {
    @State private var showConnectionHub = false
    @State private var showAddBill = false
    @State private var showChat = false
    @State private var showBudget = false

    // Observe chat service for unread count
    @ObservedObject private var chatService = ChatService.shared

    private let actions: [QuickActionType] = [.addBill, .chat, .connect, .budget]

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

                            // Chat notification badge
                            if action == .chat && chatService.totalUnreadCount > 0 {
                                Text("\(chatService.totalUnreadCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Color(hex: "#DC4B3E"))
                                    .clipShape(Circle())
                                    .offset(x: 14, y: -14)
                            }
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
        .fullScreenCover(isPresented: $showConnectionHub) {
            BillConnectionView()
        }
        .sheet(isPresented: $showAddBill) {
            AddBillActionSheet()
        }
        .sheet(isPresented: $showChat) {
            ChatHubView()
        }
        .onChange(of: showChat) { _, isShowing in
            // Refresh unread count when chat is closed
            if !isShowing {
                Task {
                    await chatService.refreshUnreadCount()
                }
            }
        }
        .task {
            // Load unread count on appear
            await chatService.refreshUnreadCount()
        }
        .sheet(isPresented: $showBudget) {
            BudgetOverviewView()
        }
    }

    private func handleAction(_ action: QuickActionType) {
        switch action {
        case .connect: showConnectionHub = true
        case .addBill: showAddBill = true
        case .chat: showChat = true
        case .budget: showBudget = true
        }
    }
}
