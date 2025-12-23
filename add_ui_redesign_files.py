#!/usr/bin/env python3
"""
Add UI Redesign files to Xcode project
"""

import uuid

# Files that need to be added (with full paths from project root)
redesign_files = [
    "Billix/Utilities/TypographyStyles.swift",
    "Billix/Utilities/AnimationModifiers.swift",
    "Billix/Features/Rewards/Views/Seasons/Components/SeasonThemeBackground.swift",
    "Billix/Features/Rewards/Views/Seasons/Components/SectionHeader.swift",
]

def generate_uuid():
    """Generate a unique 24-character hex ID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

project_path = "Billix.xcodeproj/project.pbxproj"

print(f"Reading {project_path}...")
with open(project_path, 'r') as f:
    content = f.read()

# Generate entries
file_ref_entries = []
build_file_entries = []
build_phase_entries = []

for file_path in redesign_files:
    # Check if already in project
    filename = file_path.split('/')[-1]
    if filename in content:
        print(f"✓ {filename} already in project")
        continue

    file_ref_id = generate_uuid()
    build_file_id = generate_uuid()

    # PBXFileReference with full path from SOURCE_ROOT
    file_ref_entry = f'\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{file_path}"; sourceTree = SOURCE_ROOT; }};'
    file_ref_entries.append(file_ref_entry)

    # PBXBuildFile
    build_file_entry = f'\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};'
    build_file_entries.append(build_file_entry)

    # Build phase entry
    build_phase_entry = f'\t\t\t\t{build_file_id} /* {filename} in Sources */,'
    build_phase_entries.append(build_phase_entry)

    print(f"+ Will add {filename}")

if not file_ref_entries:
    print("\nAll files already in project!")
    exit(0)

# Insert entries
pbx_build_file_section = "/* Begin PBXBuildFile section */"
pbx_file_ref_section = "/* Begin PBXFileReference section */"
pbx_sources_build_phase = "/* Begin PBXSourcesBuildPhase section */"

# Insert PBXBuildFile entries
build_file_pos = content.find(pbx_build_file_section)
build_file_insert_pos = content.find('\n', build_file_pos) + 1

for entry in build_file_entries:
    content = content[:build_file_insert_pos] + entry + '\n' + content[build_file_insert_pos:]
    build_file_insert_pos += len(entry) + 1

# Insert PBXFileReference entries
file_ref_pos = content.find(pbx_file_ref_section)
file_ref_insert_pos = content.find('\n', file_ref_pos) + 1

for entry in file_ref_entries:
    content = content[:file_ref_insert_pos] + entry + '\n' + content[file_ref_insert_pos:]
    file_ref_insert_pos += len(entry) + 1

# Insert into Sources build phase
sources_pos = content.find(pbx_sources_build_phase)
files_section = content.find("files = (", sources_pos)
sources_insert_pos = content.find('\n', files_section) + 1

for entry in build_phase_entries:
    content = content[:sources_insert_pos] + entry + '\n' + content[sources_insert_pos:]
    sources_insert_pos += len(entry) + 1

print(f"\nWriting {project_path}...")
with open(project_path, 'w') as f:
    f.write(content)

print(f"✓ Added {len(file_ref_entries)} files to project!")
