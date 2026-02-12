//
//  CreatePostSheet.swift
//  Billix
//
//  Created by Claude Code on 1/25/26.
//  Modal sheet for creating community posts
//  UX Best Practices: Modal bottom sheet, minimal fields, clear actions
//

import SwiftUI

struct CreatePostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var postContent = ""
    @State private var selectedTopic: PostTopic = .general
    @State private var selectedGroup: CommunityGroup?
    @State private var isAnonymous = false
    @FocusState private var isTextFieldFocused: Bool

    let availableGroups: [CommunityGroup]
    let preselectedGroup: CommunityGroup?
    let onPost: (String, PostTopic, CommunityGroup?, Bool) -> Void

    init(
        availableGroups: [CommunityGroup] = CommunityGroup.mockGroups,
        preselectedGroup: CommunityGroup? = nil,
        onPost: @escaping (String, PostTopic, CommunityGroup?, Bool) -> Void
    ) {
        self.availableGroups = availableGroups
        self.preselectedGroup = preselectedGroup
        self.onPost = onPost
        self._selectedGroup = State(initialValue: preselectedGroup)
    }

    private var canPost: Bool {
        !postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var characterCount: Int {
        postContent.count
    }

    private let maxCharacters = 500

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Text Input
                    textInputSection

                    // Topic Selection
                    topicSelectionSection

                    // Group Selection (if multiple groups available)
                    if availableGroups.count > 1 {
                        groupSelectionSection
                    }

                    // Anonymous Toggle
                    anonymousToggleSection

                    // Character Count
                    HStack {
                        Spacer()
                        Text("\(characterCount)/\(maxCharacters)")
                            .font(.system(size: 13))
                            .foregroundColor(characterCount > maxCharacters ? .red : Color(hex: "#9CA3AF"))
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "#F5F5F7"))
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#6B7280"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        onPost(postContent, selectedTopic, selectedGroup, isAnonymous)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canPost ? Color.billixDarkTeal : Color(hex: "#9CA3AF"))
                    .disabled(!canPost || characterCount > maxCharacters)
                }
            }
            .onAppear {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    isTextFieldFocused = true
                }
            }
        }
    }

    // MARK: - Text Input Section

    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's on your mind?")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#374151"))

            TextEditor(text: $postContent)
                .font(.system(size: 16))
                .frame(minHeight: 80)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($isTextFieldFocused)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isTextFieldFocused ? Color.billixDarkTeal : Color(hex: "#E5E7EB"), lineWidth: 1)
                )
        }
    }

    // MARK: - Topic Selection Section

    private var topicSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Topic")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#374151"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PostTopic.allCases, id: \.self) { topic in
                        topicChip(topic)
                    }
                }
            }
        }
    }

    private func topicChip(_ topic: PostTopic) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTopic = topic
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: topic.icon)
                    .font(.system(size: 12))

                Text(topic.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(selectedTopic == topic ? .white : Color(hex: "#4B5563"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                selectedTopic == topic ? Color.billixDarkTeal : Color.white
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Group Selection Section

    private var groupSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Post to")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#374151"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // General Feed option
                    groupChip(nil, name: "General Feed", icon: "globe")

                    // Available groups
                    ForEach(availableGroups.filter { $0.isJoined }) { group in
                        groupChip(group, name: group.name, icon: group.icon)
                    }
                }
            }
        }
    }

    private func groupChip(_ group: CommunityGroup?, name: String, icon: String) -> some View {
        let isSelected = (group == nil && selectedGroup == nil) || (group?.id == selectedGroup?.id)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedGroup = group
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))

                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : Color(hex: "#4B5563"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected ? Color.billixDarkTeal : Color.white
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Anonymous Toggle Section

    private var anonymousToggleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 18))
                    .foregroundColor(isAnonymous ? Color.billixDarkTeal : Color(hex: "#9CA3AF"))
                    .frame(width: 24)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Post anonymously")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#374151"))

                    Text("Your name will be hidden from others")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }

                Spacer()

                // Toggle
                Toggle("", isOn: $isAnonymous)
                    .toggleStyle(SwitchToggleStyle(tint: Color.billixDarkTeal))
                    .labelsHidden()
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Post Topic Enum

enum PostTopic: String, CaseIterable {
    case general = "General"
    case savings = "Savings"
    case tips = "Tips"
    case question = "Question"
    case milestone = "Milestone"
    case bills = "Bills"

    var icon: String {
        switch self {
        case .general: return "bubble.left"
        case .savings: return "banknote"
        case .tips: return "lightbulb"
        case .question: return "questionmark.circle"
        case .milestone: return "star"
        case .bills: return "doc.text"
        }
    }
}

// MARK: - Preview

struct CreatePostSheet_Create_Post_Sheet_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostSheet(
        availableGroups: CommunityGroup.mockGroups,
        preselectedGroup: nil
        ) { content, topic, group, isAnonymous in
        print("Posted: \(content), topic: \(topic.rawValue), group: \(group?.name ?? "General"), anonymous: \(isAnonymous)")
        }
    }
}
