//
//  ToastNotification.swift
//  Billix
//
//  Created by Claude Code
//  Subtle toast notification for Quick Earnings task completion
//

import SwiftUI

struct ToastNotification: View {
    let message: String
    let points: Int
    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            if isShowing {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)

                    Text(message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#1F2937"))

                    Text("+\(points) pts")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "#F97316"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
            }

            Spacer()
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
    }
}

// Helper view modifier for easy use
extension View {
    func toast(isShowing: Binding<Bool>, message: String, points: Int) -> some View {
        ZStack {
            self
            ToastNotification(message: message, points: points, isShowing: isShowing)
        }
    }
}

// MARK: - Preview

struct ToastNotification_Toast_Showing_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        Color.gray.opacity(0.1)
        .ignoresSafeArea()
        
        ToastNotification(
        message: "Vote submitted!",
        points: 5,
        isShowing: .constant(true)
        )
        }
    }
}
