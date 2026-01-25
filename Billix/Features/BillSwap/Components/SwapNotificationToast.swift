//
//  SwapNotificationToast.swift
//  Billix
//
//  In-app toast notification for BillSwap events
//

import SwiftUI

struct SwapNotificationToast: View {
    let notification: SwapNotificationData
    let onTap: (() -> Void)?
    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            if isShowing {
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: notification.type.iconColor))

                    VStack(alignment: .leading, spacing: 2) {
                        // Title
                        Text(notification.type.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "#1F2937"))

                        // Message
                        Text(notification.message)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .lineLimit(2)
                    }

                    Spacer()

                    // Chevron if tappable
                    if notification.swapId != nil {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                )
                .onTapGesture {
                    if notification.swapId != nil {
                        onTap?()
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
            }

            Spacer()
        }
        .padding(.top, 60)
        .padding(.horizontal, 16)
    }
}

// MARK: - View Modifier

extension View {
    /// Show a swap notification toast overlay
    func swapNotificationToast(
        notification: Binding<SwapNotificationData?>,
        onTap: (() -> Void)? = nil
    ) -> some View {
        ZStack {
            self

            if let notificationData = notification.wrappedValue {
                SwapNotificationToast(
                    notification: notificationData,
                    onTap: onTap,
                    isShowing: Binding(
                        get: { notification.wrappedValue != nil },
                        set: { if !$0 { notification.wrappedValue = nil } }
                    )
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Match Found") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        SwapNotificationToast(
            notification: SwapNotificationData(
                type: .matchFound,
                swapId: UUID(),
                message: "A $150 swap is available. Tap to view details."
            ),
            onTap: { print("Tapped!") },
            isShowing: .constant(true)
        )
    }
}

#Preview("Partner Committed") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        SwapNotificationToast(
            notification: SwapNotificationData(
                type: .partnerCommitted,
                swapId: UUID(),
                message: "Your partner committed! Chat is now unlocked."
            ),
            onTap: nil,
            isShowing: .constant(true)
        )
    }
}

#Preview("Bill Paid") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        SwapNotificationToast(
            notification: SwapNotificationData(
                type: .billPaid,
                swapId: UUID(),
                message: "Your partner paid your $85 bill!"
            ),
            onTap: { print("Tapped!") },
            isShowing: .constant(true)
        )
    }
}

#Preview("Swap Complete") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        SwapNotificationToast(
            notification: SwapNotificationData(
                type: .swapComplete,
                swapId: nil,
                message: "Swap complete! You both saved money."
            ),
            onTap: nil,
            isShowing: .constant(true)
        )
    }
}
