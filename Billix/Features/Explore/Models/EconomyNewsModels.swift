//
//  EconomyNewsModels.swift
//  Billix
//
//  Created by Claude Code on 1/19/26.
//  Data models for Economy by AI news feed
//

import Foundation

// MARK: - Economy Article

struct EconomyArticle: Identifiable, Equatable {
    let id: String
    let title: String
    let summary: String
    let source: String
    let author: String
    let publishedAt: Date
    let imageURL: String?
    let category: EconomyCategory
    let isBreaking: Bool
    let content: String
    let sourceURL: URL?

    static func == (lhs: EconomyArticle, rhs: EconomyArticle) -> Bool {
        lhs.id == rhs.id
    }

    /// Initialize from Supabase response
    init(from dbArticle: EconomyArticleDB) {
        self.id = dbArticle.id
        self.title = dbArticle.title
        self.summary = dbArticle.summary ?? ""
        self.source = dbArticle.source
        self.author = "Billix AI" // AI-generated content
        self.publishedAt = dbArticle.publishedAt
        self.imageURL = dbArticle.imageUrl
        self.category = EconomyCategory.fromDBCategory(dbArticle.category)
        self.isBreaking = dbArticle.isBreaking
        self.content = dbArticle.content
        self.sourceURL = URL(string: dbArticle.sourceUrl)
    }

    /// Initialize for mock data (backward compatibility)
    init(id: String, title: String, summary: String, source: String, author: String, publishedAt: Date, imageURL: String?, category: EconomyCategory, isBreaking: Bool, content: String, sourceURL: URL? = nil) {
        self.id = id
        self.title = title
        self.summary = summary
        self.source = source
        self.author = author
        self.publishedAt = publishedAt
        self.imageURL = imageURL
        self.category = category
        self.isBreaking = isBreaking
        self.content = content
        self.sourceURL = sourceURL
    }
}

// MARK: - Database Model (matches Supabase table)

struct EconomyArticleDB: Codable {
    let id: String
    let externalId: String
    let title: String
    let summary: String?
    let content: String
    let source: String
    let sourceUrl: String
    let imageUrl: String?
    let category: String
    let isBreaking: Bool
    let publishedAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case externalId = "external_id"
        case title
        case summary
        case content
        case source
        case sourceUrl = "source_url"
        case imageUrl = "image_url"
        case category
        case isBreaking = "is_breaking"
        case publishedAt = "published_at"
        case createdAt = "created_at"
    }
}

// MARK: - Economy Category

enum EconomyCategory: String, CaseIterable, Identifiable {
    case all = "all"
    case home = "home"           // housing + utilities
    case prices = "prices"       // groceries + transportation + general
    case insurance = "insurance"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .home:
            return "Home"
        case .prices:
            return "Prices"
        case .insurance:
            return "Insurance"
        }
    }

    var icon: String {
        switch self {
        case .all:
            return "newspaper.fill"
        case .home:
            return "house.fill"
        case .prices:
            return "tag.fill"
        case .insurance:
            return "shield.fill"
        }
    }

    /// Map database category string to enum
    static func fromDBCategory(_ dbCategory: String) -> EconomyCategory {
        switch dbCategory.lowercased() {
        case "housing", "utilities":
            return .home
        case "groceries", "transportation", "general":
            return .prices
        case "insurance":
            return .insurance
        default:
            return .prices
        }
    }

    /// Convert to database category string
    var dbValue: String {
        rawValue
    }
}

// MARK: - Mock Data

