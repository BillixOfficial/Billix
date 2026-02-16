//
//  QuizView.swift
//  Billix
//
//  Created by Claude Code
//  Daily quiz interface for Quick Earnings
//

import SwiftUI

struct QuizView: View {
    @StateObject private var viewModel = QuizViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "#FAFAFA")
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if let quiz = viewModel.quizData {
                    if viewModel.isCompleted {
                        // Results screen
                        ResultsScreen(
                            quiz: quiz.quiz,
                            score: viewModel.score,
                            totalQuestions: quiz.questions.count,
                            onDismiss: {
                                dismiss()
                            }
                        )
                    } else {
                        // Quiz questions
                        QuizQuestionsView(viewModel: viewModel)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        Task {
                            await viewModel.loadQuiz()
                        }
                    }
                } else {
                    // No quiz available today
                    VStack(spacing: 16) {
                        Image(systemName: "graduationcap")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#6B7280"))

                        Text("No Quiz Today")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#1F2937"))

                        Text("Check back tomorrow for a new trivia quiz!")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                // Toast notification
                EmptyView()
            }
            .toast(
                isShowing: $viewModel.showToast,
                message: "Quiz completed!",
                points: 8
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "#6B7280"))
                    }
                }
            }
        }
        .task {
            await viewModel.loadQuiz()
        }
    }
}

// MARK: - Quiz Questions View

struct QuizQuestionsView: View {
    @ObservedObject var viewModel: QuizViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let currentQuestion = viewModel.currentQuestion,
                   let quiz = viewModel.quizData {

                    // Header
                    VStack(spacing: 8) {
                        Text("Daily Quiz")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .textCase(.uppercase)

                        Text(quiz.quiz.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#1F2937"))
                    }
                    .padding(.top, 20)

                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<quiz.questions.count, id: \.self) { index in
                            Circle()
                                .fill(index == viewModel.currentQuestionIndex
                                    ? Color(hex: "#F97316")
                                    : index < viewModel.currentQuestionIndex
                                        ? Color(hex: "#10B981")
                                        : Color(hex: "#D1D5DB"))
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.vertical, 8)

                    // Question number
                    Text("Question \(viewModel.currentQuestionIndex + 1) of \(quiz.questions.count)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#6B7280"))

                    // Question text
                    Text(currentQuestion.questionText)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#1F2937"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)

                    // Answer options
                    VStack(spacing: 12) {
                        QuizOptionButton(
                            option: "a",
                            text: currentQuestion.optionA,
                            isSelected: viewModel.selectedAnswers[currentQuestion.id] == "a",
                            action: { viewModel.selectAnswer(questionId: currentQuestion.id, option: "a") }
                        )

                        QuizOptionButton(
                            option: "b",
                            text: currentQuestion.optionB,
                            isSelected: viewModel.selectedAnswers[currentQuestion.id] == "b",
                            action: { viewModel.selectAnswer(questionId: currentQuestion.id, option: "b") }
                        )

                        QuizOptionButton(
                            option: "c",
                            text: currentQuestion.optionC,
                            isSelected: viewModel.selectedAnswers[currentQuestion.id] == "c",
                            action: { viewModel.selectAnswer(questionId: currentQuestion.id, option: "c") }
                        )

                        QuizOptionButton(
                            option: "d",
                            text: currentQuestion.optionD,
                            isSelected: viewModel.selectedAnswers[currentQuestion.id] == "d",
                            action: { viewModel.selectAnswer(questionId: currentQuestion.id, option: "d") }
                        )
                    }
                    .padding(.horizontal, 24)

                    // Next/Submit button
                    Button(action: {
                        Task {
                            await viewModel.nextQuestion()
                        }
                    }) {
                        HStack {
                            Text(viewModel.isLastQuestion ? "Submit Quiz" : "Next Question")
                                .font(.system(size: 17, weight: .semibold))

                            Image(systemName: viewModel.isLastQuestion ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: viewModel.canProceed
                                    ? [Color(hex: "#F97316"), Color(hex: "#E11D48")]
                                    : [Color(hex: "#D1D5DB"), Color(hex: "#9CA3AF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(!viewModel.canProceed)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}

// MARK: - Quiz Option Button

struct QuizOptionButton: View {
    let option: String
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Text(option.uppercased())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? Color(hex: "#F97316") : Color(hex: "#6B7280"))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? Color(hex: "#FEF3C7") : Color(hex: "#F3F4F6"))
                    )

                Text(text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#1F2937"))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#F97316"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: isSelected ? Color(hex: "#F97316").opacity(0.2) : Color.black.opacity(0.05), radius: isSelected ? 8 : 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "#F97316") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Results Screen

struct ResultsScreen: View {
    let quiz: Quiz
    let score: Int
    let totalQuestions: Int
    let onDismiss: () -> Void

    var percentage: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(score) / Double(totalQuestions) * 100.0
    }

    var emoji: String {
        switch percentage {
        case 100:
            return "🏆"
        case 67..<100:
            return "🎉"
        case 34..<67:
            return "👍"
        default:
            return "📚"
        }
    }

    var performanceMessage: String {
        switch percentage {
        case 100:
            return "Perfect Score!"
        case 67..<100:
            return "Great Job!"
        case 34..<67:
            return "Good Effort!"
        default:
            return "Keep Learning!"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 60)

                // Emoji
                Text(emoji)
                    .font(.system(size: 80))

                // Performance message
                Text(performanceMessage)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#1F2937"))

                // Score
                VStack(spacing: 8) {
                    Text("\(score)/\(totalQuestions)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#F97316"))

                    Text("\(Int(percentage))% Correct")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
                )
                .padding(.horizontal, 32)

                // Quiz info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(Color(hex: "#F97316"))
                        Text(quiz.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#1F2937"))
                    }

                    if let difficulty = quiz.difficulty {
                        HStack {
                            Image(systemName: "gauge.medium")
                                .foregroundColor(Color(hex: "#10B981"))
                            Text("Difficulty: \(difficulty.capitalized)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "#6B7280"))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 32)

                // Done button
                Button(action: onDismiss) {
                    HStack {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#F97316"), Color(hex: "#E11D48")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Error Loading Quiz")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#1F2937"))

            Text(message)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#6B7280"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - ViewModel

@MainActor
class QuizViewModel: ObservableObject {
    @Published var quizData: QuizWithQuestions?
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswers: [UUID: String] = [:]
    @Published var isCompleted = false
    @Published var score = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showToast = false

    private let quizService = QuizService.shared
    private let rewardsService = RewardsService()
    private let taskService = TaskTrackingService()
    private let authService = AuthService.shared

    var currentQuestion: QuizQuestion? {
        quizData?.questions[safe: currentQuestionIndex]
    }

    var isLastQuestion: Bool {
        guard let quizData = quizData else { return false }
        return currentQuestionIndex == quizData.questions.count - 1
    }

    var canProceed: Bool {
        guard let currentQuestion = currentQuestion else { return false }
        return selectedAnswers[currentQuestion.id] != nil
    }

    func loadQuiz() async {
        isLoading = true
        errorMessage = nil

        do {
            quizData = try await quizService.getQuizWithQuestions()
            isLoading = false

            // Check if already completed
            if quizData?.isCompleted == true {
                isCompleted = true
                if let attempt = quizData?.attempt {
                    score = attempt.score
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func selectAnswer(questionId: UUID, option: String) {
        selectedAnswers[questionId] = option

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func nextQuestion() async {
        guard let quizData = quizData else { return }

        if isLastQuestion {
            // Submit quiz
            await submitQuiz()
        } else {
            // Move to next question
            withAnimation {
                currentQuestionIndex += 1
            }
        }
    }

    func submitQuiz() async {
        guard let quizId = quizData?.quiz.id else { return }

        do {
            // 1. Submit quiz answers
            let submission = QuizSubmission(
                quizId: quizId,
                answers: selectedAnswers
            )

            let attempt = try await quizService.submitQuizAnswers(submission)
            score = attempt.score
            isCompleted = true

            // 2. Track task completion AND auto-claim
            if let userId = authService.currentUser?.id {
                // Mark as completed
                _ = try await taskService.incrementTaskProgress(
                    userId: userId,
                    taskKey: "daily_complete_quiz",
                    sourceId: quizId
                )

                // Auto-claim points
                let claimResult = try await taskService.claimTaskReward(
                    userId: userId,
                    taskKey: "daily_complete_quiz"
                )

                if claimResult.success {
                    // Award points via RewardsService
                    _ = try await rewardsService.addPoints(
                        userId: userId,
                        amount: claimResult.pointsAwarded,
                        type: "task_completion",
                        description: "Daily quiz completion"
                    )

                    // Notify RewardsViewModel to refresh
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PointsUpdated"),
                        object: nil
                    )

                    // Show toast notification
                    showToast = true

                    // Auto-dismiss toast after 2 seconds
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        showToast = false
                    }
                }
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview("Quiz") {
    QuizView()
}
