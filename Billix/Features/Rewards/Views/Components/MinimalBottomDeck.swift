//
//  MinimalBottomDeck.swift
//  Billix
//
//  Created by Claude Code
//  Minimal bottom deck with drag-to-expand functionality
//  Replaces GeoGameFloatingCard for maximized map visibility
//  Minimal: 80pt, Expanded: 200-220pt
//

import SwiftUI

struct MinimalBottomDeck: View {
    @ObservedObject var viewModel: GeoGameViewModel

    // State management
    @State private var isExpanded: Bool = false
    @State private var dragOffset: CGFloat = 0

    // Heights
    let minimalHeight: CGFloat = 80

    var expandedHeight: CGFloat {
        // Fixed height for all phases - no size changes during transitions
        // 340pt provides ample space for all content types
        return 340
    }

    var deckHeight: CGFloat {
        isExpanded ? expandedHeight : minimalHeight
    }

    // Phase labels
    var phaseLabel: String {
        switch viewModel.questionPhase {
        case .phase1Location:
            return "Identify Location"
        case .phase2Price:
            return "Guess Price"
        case .phase1Feedback:
            return viewModel.gameState.isLocationCorrect ? "Correct!" : "Try Again"
        case .phase2Feedback, .questionComplete:
            return "Result"
        default:
            return "Loading..."
        }
    }

    var hint: String {
        switch viewModel.questionPhase {
        case .phase1Location:
            return "Drag up to see answer options"
        case .phase2Price:
            return "Drag up to set price"
        case .phase1Feedback, .phase2Feedback, .questionComplete:
            return "Drag up to see details"
        default:
            return ""
        }
    }

    // Question text for the header
    var questionText: String {
        if let question = viewModel.currentQuestion {
            switch viewModel.questionPhase {
            case .phase1Location:
                return "Where is this landmark located?"
            case .phase2Price:
                return "\(question.subject) in \(question.location)"
            default:
                return ""
            }
        }
        return "Loading question..."
    }

    // Question header view (grey bar with question only - timer moved to top HUD)
    var questionHeader: some View {
        Text(questionText)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color(hex: "#1F2937"))
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "#F9FAFB"))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle pill
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)

            if !isExpanded {
                // Minimal state: Label + hint
                VStack(spacing: 4) {
                    Text(phaseLabel)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)

                    Text(hint)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 12)
            } else {
                // Expanded state: Question header + Phase content
                VStack(spacing: 0) {
                    // Question context header (grey bar) - only for Phase 1
                    // Phase 2 has question built into its view to avoid duplication
                    if viewModel.questionPhase == .phase1Location || viewModel.questionPhase == .phase1Feedback {
                        questionHeader
                    }

                    // Phase-specific content
                    Group {
                        switch viewModel.questionPhase {
                        case .phase1Location, .phase1Feedback:
                            Phase1LocationView(viewModel: viewModel)
                        case .phase2Price:
                            Phase2PriceView(viewModel: viewModel)
                        case .phase2Feedback, .questionComplete:
                            GeoGameResultView(viewModel: viewModel)
                        default:
                            loadingView
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .frame(height: deckHeight)
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.2), radius: 12, y: -4)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .gesture(dragGesture)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: deckHeight)
        .onChange(of: isExpanded) { _, expanded in
            // Notify map to adjust camera position
            notifyMapCameraAdjustment()
        }
        .onChange(of: viewModel.questionPhase) { _, _ in
            // Auto-expand when phase changes to show new content
            withAnimation(.spring()) {
                isExpanded = true
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                let threshold: CGFloat = 50

                if value.translation.height < -threshold {
                    // Drag up: Expand
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded = true
                    }
                } else if value.translation.height > threshold {
                    // Drag down: Collapse
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                }

                // Reset drag offset
                dragOffset = 0
            }
    }

    // MARK: - Helpers

    private func notifyMapCameraAdjustment() {
        // Calculate screen height (assume iPhone 14 Pro height as default)
        let screenHeight: CGFloat = UIScreen.main.bounds.height

        // Notify ViewModel to adjust camera
        Task {
            await MainActor.run {
                viewModel.adjustCameraForCardState(
                    cardHeight: deckHeight,
                    screenHeight: screenHeight
                )
            }
        }
    }
}

// MARK: - Custom Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

struct MinimalBottomDeck_Minimal_Bottom_Deck___Minimal_State_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        Color.green.opacity(0.3)
        .ignoresSafeArea()
        
        VStack {
        Spacer()
        
        MinimalBottomDeck(viewModel: {
        let vm = GeoGameViewModel()
        vm.questionPhase = .phase1Location
        return vm
        }())
        }
        }
    }
}

struct MinimalBottomDeck_Minimal_Bottom_Deck___Expanded_State_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        Color.blue.opacity(0.3)
        .ignoresSafeArea()
        
        VStack {
        Spacer()
        
        MinimalBottomDeck(viewModel: {
        let vm = GeoGameViewModel()
        vm.questionPhase = .phase1Location
        return vm
        }())
        .onAppear {
        // Simulate expanded state
        Task { @MainActor in
        try? await Task.sleep(nanoseconds: 500_000_000)
        // Note: This won't work in preview, just for visual reference
        }
        }
        }
        }
    }
}
