#!/usr/bin/env python3
import sys
import uuid
import re

# Generate unique IDs for Xcode
def generate_uuid():
    return uuid.uuid4().hex[:24].upper()

# New files to add
new_files = [
    "GiftCardHeroSection.swift",
    "VirtualGoodsCarousel.swift",
    "GameBoostsGrid.swift",
    "WeeklyGiveawayCard.swift",
    "GiftCardsModal.swift"
]

project_file = "Billix.xcodeproj/project.pbxproj"

# Read the project file
with open(project_file, 'r') as f:
    content = f.read()

# Find the Components group (we'll add files there)
# Look for an existing component file to find the group
match = re.search(r'(/\* WalletHeaderView\.swift \*/ = \{isa = PBXFileReference; .+? path = WalletHeaderView\.swift;)', content)
if not match:
    print("Could not find Components group reference")
    sys.exit(1)

# Generate UUIDs for each file
file_refs = {}
build_files = {}
for filename in new_files:
    file_refs[filename] = generate_uuid()
    build_files[filename] = generate_uuid()

# Add PBXFileReference entries
pbx_file_ref_section = re.search(r'(/\* Begin PBXFileReference section \*/.*?/\* End PBXFileReference section \*/)', content, re.DOTALL)
if pbx_file_ref_section:
    insertion_point = pbx_file_ref_section.group(1).rfind('/* End PBXFileReference section */')
    base_pos = pbx_file_ref_section.start() + insertion_point

    new_entries = ""
    for filename in new_files:
        new_entries += f"\t\t{file_refs[filename]} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n"

    content = content[:base_pos] + new_entries + content[base_pos:]

# Add PBXBuildFile entries
pbx_build_file_section = re.search(r'(/\* Begin PBXBuildFile section \*/.*?/\* End PBXBuildFile section \*/)', content, re.DOTALL)
if pbx_build_file_section:
    insertion_point = pbx_build_file_section.group(1).rfind('/* End PBXBuildFile section */')
    base_pos = pbx_build_file_section.start() + insertion_point

    new_entries = ""
    for filename in new_files:
        new_entries += f"\t\t{build_files[filename]} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[filename]} /* {filename} */; }};\n"

    content = content[:base_pos] + new_entries + content[base_pos:]

# Add to Components group
# Find the Components group
components_group = re.search(r'([A-F0-9]{24}) /\* Components \*/ = \{[^}]+?children = \([^)]+?\);', content, re.DOTALL)
if components_group:
    children_end = components_group.group(0).rfind(');')
    base_pos = components_group.start() + children_end

    new_entries = ""
    for filename in new_files:
        new_entries += f"\t\t\t\t{file_refs[filename]} /* {filename} */,\n"

    content = content[:base_pos] + new_entries + content[base_pos:]

# Add to PBXSourcesBuildPhase
sources_phase = re.search(r'([A-F0-9]{24}) /\* Sources \*/ = \{[^}]+?files = \([^)]+?\);', content, re.DOTALL)
if sources_phase:
    files_end = sources_phase.group(0).rfind(');')
    base_pos = sources_phase.start() + files_end

    new_entries = ""
    for filename in new_files:
        new_entries += f"\t\t\t\t{build_files[filename]} /* {filename} in Sources */,\n"

    content = content[:base_pos] + new_entries + content[base_pos:]

# Write back
with open(project_file, 'w') as f:
    f.write(content)

print("Successfully added files to Xcode project:")
for filename in new_files:
    print(f"  ✓ {filename}")
