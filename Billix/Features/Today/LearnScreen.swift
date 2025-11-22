import SwiftUI

struct LearnScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TodayViewModel()

    @State private var selectedCategory: String = "All"
    @State private var selectedDifficulty: LearnArticle.Difficulty? = nil

    private let categories = ["All", "Tips", "Basics", "Advanced"]

    var filteredArticles: [LearnArticle] {
        var articles = viewModel.learnArticles

        if selectedCategory != "All" {
            articles = articles.filter { $0.category == selectedCategory }
        }

        if let difficulty = selectedDifficulty {
            articles = articles.filter { $0.difficulty == difficulty }
        }

        return articles
    }

    var body: some View {
        ZStack {
            Color.billixLightGreen.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                LearnScreenHeader(dismiss: dismiss)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Filter Section
                        FilterSection(
                            selectedCategory: $selectedCategory,
                            selectedDifficulty: $selectedDifficulty,
                            categories: categories
                        )
                        .padding(.horizontal, 18)
                        .padding(.top, 11)

                        // Articles Grid
                        ArticlesGrid(articles: filteredArticles)
                            .padding(.horizontal, 18)
                            .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Header

struct LearnScreenHeader: View {
    let dismiss: DismissAction

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGray)
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Learn to Lower")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.billixDarkGray)

                Text("Tips to save on bills")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.billixDarkGray.opacity(0.6))
            }

            Spacer()

            Text("📚")
                .font(.system(size: 28))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.billixLightGreen)
    }
}

// MARK: - Filter Section

struct FilterSection: View {
    @Binding var selectedCategory: String
    @Binding var selectedDifficulty: LearnArticle.Difficulty?
    let categories: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            // Category Filters
            Text("Category")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.billixDarkGray.opacity(0.7))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(categories, id: \.self) { category in
                        CategoryFilterChip(
                            title: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }

            // Difficulty Filters
            Text("Difficulty")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.billixDarkGray.opacity(0.7))
                .padding(.top, 7)

            HStack(spacing: 9) {
                DifficultyFilterChip(
                    title: "All",
                    isSelected: selectedDifficulty == nil
                ) {
                    selectedDifficulty = nil
                }

                DifficultyFilterChip(
                    title: "Beginner",
                    isSelected: selectedDifficulty == .beginner
                ) {
                    selectedDifficulty = .beginner
                }

                DifficultyFilterChip(
                    title: "Intermediate",
                    isSelected: selectedDifficulty == .intermediate
                ) {
                    selectedDifficulty = .intermediate
                }

                DifficultyFilterChip(
                    title: "Advanced",
                    isSelected: selectedDifficulty == .advanced
                ) {
                    selectedDifficulty = .advanced
                }

                Spacer()
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(14)
    }
}

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .billixDarkGray)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(isSelected ? Color.billixLoginTeal : Color.billixLightGreen)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct DifficultyFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .billixDarkGray)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.billixLoginTeal : Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Articles Grid

struct ArticlesGrid: View {
    let articles: [LearnArticle]

    var body: some View {
        LazyVStack(spacing: 14) {
            if articles.isEmpty {
                EmptyArticlesView()
            } else {
                ForEach(articles) { article in
                    ArticleCard(article: article)
                }
            }
        }
    }
}

struct ArticleCard: View {
    let article: LearnArticle
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - always visible
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    // Icon
                    Text(article.icon)
                        .font(.system(size: 32))
                        .frame(width: 50, height: 50)
                        .background(Color.billixLightGreen)
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(article.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.billixDarkGray)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 7) {
                            // Category
                            Text(article.category)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.billixLoginTeal)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.billixLoginTeal.opacity(0.12))
                                .cornerRadius(6)

                            // Difficulty
                            Text(article.difficulty.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(difficultyColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(difficultyColor.opacity(0.12))
                                .cornerRadius(6)

                            Spacer()

                            // Read time
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text("\(article.readTime)m")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.billixDarkGray.opacity(0.6))
                        }
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixDarkGray.opacity(0.4))
                }
                .padding(16)
            }

            // Content - expandable
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.gray.opacity(0.2))
                        .padding(.horizontal, 16)

                    Text(article.content)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.billixDarkGray.opacity(0.8))
                        .lineSpacing(4)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }

    private var difficultyColor: Color {
        switch article.difficulty {
        case .beginner:
            return .billixMoneyGreen
        case .intermediate:
            return .billixPendingOrange
        case .advanced:
            return .red
        }
    }
}

struct EmptyArticlesView: View {
    var body: some View {
        VStack(spacing: 11) {
            Text("📖")
                .font(.system(size: 48))

            Text("No articles found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGray)

            Text("Try adjusting your filters")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.billixDarkGray.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    LearnScreen()
}
