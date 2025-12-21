#!/usr/bin/env python3
import uuid
import re

# Read project file
with open('Billix.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Files to add
files = [
    'Billix/Features/Rewards/Views/Components/GameBoostsModal.swift',
    'Billix/Features/Rewards/Views/Components/VirtualGoodsModal.swift'
]

# Generate UUIDs for each file (2 per file: one for PBXBuildFile, one for PBXFileReference)
file_refs = {}
for file_path in files:
    filename = file_path.split('/')[-1]
    file_refs[filename] = {
        'build_uuid': str(uuid.uuid4()).replace('-', '')[:24].upper(),
        'ref_uuid': str(uuid.uuid4()).replace('-', '')[:24].upper(),
        'path': file_path
    }

# Find the Components group UUID
components_match = re.search(r'([A-F0-9]{24}) /\* Components \*/ = \{', content)
if not components_match:
    print("Could not find Components group")
    exit(1)

components_uuid = components_match.group(1)

# Find where to insert PBXBuildFile entries (after a similar entry)
build_files_section = re.search(r'/\* Begin PBXBuildFile section \*/\n', content)
if build_files_section:
    insert_pos = build_files_section.end()
    build_entries = []
    for filename, data in file_refs.items():
        entry = f"\t\t{data['build_uuid']} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {data['ref_uuid']} /* {filename} */; }};\n"
        build_entries.append(entry)

    content = content[:insert_pos] + ''.join(build_entries) + content[insert_pos:]

# Find where to insert PBXFileReference entries
file_ref_section = re.search(r'/\* Begin PBXFileReference section \*/\n', content)
if file_ref_section:
    insert_pos = file_ref_section.end()
    ref_entries = []
    for filename, data in file_refs.items():
        entry = f"\t\t{data['ref_uuid']} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n"
        ref_entries.append(entry)

    content = content[:insert_pos] + ''.join(ref_entries) + content[insert_pos:]

# Add files to Components group
# Find the Components group children section
components_group_pattern = f'{components_uuid} /\\* Components \\*/ = {{[^}}]+children = \\('
match = re.search(components_group_pattern, content)
if match:
    # Find the closing parenthesis of the children array
    start_pos = match.end()
    paren_depth = 1
    current_pos = start_pos

    while paren_depth > 0 and current_pos < len(content):
        if content[current_pos] == '(':
            paren_depth += 1
        elif content[current_pos] == ')':
            paren_depth -= 1
        current_pos += 1

    # Insert before the closing parenthesis
    insert_pos = current_pos - 1
    group_entries = []
    for filename, data in file_refs.items():
        entry = f"\t\t\t\t{data['ref_uuid']} /* {filename} */,\n"
        group_entries.append(entry)

    content = content[:insert_pos] + ''.join(group_entries) + content[insert_pos:]

# Add to PBXSourcesBuildPhase (compile sources)
sources_phase_pattern = r'(isa = PBXSourcesBuildPhase;[^}]+files = \()'
match = re.search(sources_phase_pattern, content, re.MULTILINE | re.DOTALL)
if match:
    insert_pos = match.end()
    # Find the closing parenthesis
    paren_depth = 1
    current_pos = insert_pos

    while paren_depth > 0 and current_pos < len(content):
        if content[current_pos] == '(':
            paren_depth += 1
        elif content[current_pos] == ')':
            paren_depth -= 1
        current_pos += 1

    # Insert before closing
    insert_pos = current_pos - 1
    build_phase_entries = []
    for filename, data in file_refs.items():
        entry = f"\t\t\t\t{data['build_uuid']} /* {filename} in Sources */,\n"
        build_phase_entries.append(entry)

    content = content[:insert_pos] + ''.join(build_phase_entries) + content[insert_pos:]

# Write back
with open('Billix.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("Successfully added modal files to Xcode project")
for filename, data in file_refs.items():
    print(f"  - {filename}")
