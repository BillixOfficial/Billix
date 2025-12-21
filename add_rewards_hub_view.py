#!/usr/bin/env python3
import uuid
import re

# Read project file
with open('Billix.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# File to add
filename = 'RewardsHubView.swift'
build_uuid = str(uuid.uuid4()).replace('-', '')[:24].upper()
ref_uuid = str(uuid.uuid4()).replace('-', '')[:24].upper()

# 1. Add PBXBuildFile entry
build_files_section = re.search(r'/\* Begin PBXBuildFile section \*/\n', content)
if build_files_section:
    insert_pos = build_files_section.end()
    entry = f"\t\t{build_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref_uuid} /* {filename} */; }};\n"
    content = content[:insert_pos] + entry + content[insert_pos:]

# 2. Add PBXFileReference entry
file_ref_section = re.search(r'/\* Begin PBXFileReference section \*/\n', content)
if file_ref_section:
    insert_pos = file_ref_section.end()
    entry = f"\t\t{ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n"
    content = content[:insert_pos] + entry + content[insert_pos:]

# 3. Find the Views group (under Rewards)
# Look for the Views group that contains other view files like RewardCard.swift
views_group_match = re.search(r'([A-F0-9]{24}) /\* Views \*/ = \{[^}]+isa = PBXGroup;[^}]+children = \([^)]+RewardCard\.swift[^}]+\};', content, re.MULTILINE | re.DOTALL)
if not views_group_match:
    print("Could not find Views group containing RewardCard.swift")
    exit(1)

# Extract the full group block
group_text = views_group_match.group(0)
# Find where children array ends
children_end = group_text.rfind(')')
if children_end != -1:
    # Insert before the closing parenthesis
    group_start_in_content = views_group_match.start()
    insert_pos = group_start_in_content + children_end
    entry = f"\t\t\t\t{ref_uuid} /* {filename} */,\n"
    content = content[:insert_pos] + entry + content[insert_pos:]

# 4. Add to PBXSourcesBuildPhase
sources_phase_pattern = r'isa = PBXSourcesBuildPhase;[^}]+files = \([^)]+\);'
match = re.search(sources_phase_pattern, content, re.MULTILINE | re.DOTALL)
if match:
    # Find the closing parenthesis
    files_text = match.group(0)
    paren_pos = files_text.rfind(')')
    if paren_pos != -1:
        insert_pos = match.start() + paren_pos
        entry = f"\t\t\t\t{build_uuid} /* {filename} in Sources */,\n"
        content = content[:insert_pos] + entry + content[insert_pos:]

# Write back
with open('Billix.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print(f"Successfully added {filename} to Xcode project")
