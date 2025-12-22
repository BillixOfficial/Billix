//
//  TypographyStyles.swift
//  Billix
//
//  Created by Claude Code
//  Typography scale and spacing system for consistent design
//

import SwiftUI

// MARK: - Typography Scale

extension Font {
    /// Large title for main screens (34pt, bold, rounded)
    static let seasonLargeTitle = Font.system(size: 34, weight: .bold, design: .rounded)

    /// Title for sections and headers (28pt, bold, rounded)
    static let seasonTitle = Font.system(size: 28, weight: .bold, design: .rounded)

    /// Card title for season/chapter cards (22pt, bold, rounded)
    static let seasonCardTitle = Font.system(size: 22, weight: .bold, design: .rounded)

    /// Subtitle text (17pt, medium)
    static let seasonSubtitle = Font.system(size: 17, weight: .medium)

    /// Caption text for descriptions (13pt, medium)
    static let seasonCaption = Font.system(size: 13, weight: .medium)

    /// Footnote for small labels and stats (11pt, semibold)
    static let seasonFootnote = Font.system(size: 11, weight: .semibold)
}

// MARK: - Spacing System

enum Spacing {
    /// Extra small spacing (4pt) - for tight elements
    static let xs: CGFloat = 4

    /// Small spacing (8pt) - for closely related elements
    static let sm: CGFloat = 8

    /// Medium spacing (12pt) - for related groups
    static let md: CGFloat = 12

    /// Large spacing (16pt) - for standard padding
    static let lg: CGFloat = 16

    /// Extra large spacing (24pt) - for section separation
    static let xl: CGFloat = 24

    /// Extra extra large spacing (32pt) - for major sections
    static let xxl: CGFloat = 32
}
