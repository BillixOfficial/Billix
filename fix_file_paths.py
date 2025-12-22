#!/usr/bin/env python3
"""
Script to fix file paths in Billix.xcodeproj and remove non-existent files
"""

import re

project_path = "Billix.xcodeproj/project.pbxproj"

print(f"Reading {project_path}...")
with open(project_path, 'r') as f:
    content = f.read()

# Files to remove (don't exist)
files_to_remove = [
    "GeoGameView.swift",
    "PhaseIndicatorView.swift",
    "ResultView.swift"
]

# Find and remove these file entries
uuids_to_remove = set()

# Find file reference UUIDs
for filename in files_to_remove:
    # Match: UUID /* filename */ = {isa = PBXFileReference
    pattern = r'([A-F0-9]{24}) /\* ' + re.escape(filename) + r' \*/'
    matches = re.findall(pattern, content)
    for uuid in matches:
        uuids_to_remove.add(uuid)
        print(f"Will remove {filename} with UUID {uuid}")

# Remove all lines containing these UUIDs
lines = content.split('\n')
new_lines = []
removed_count = 0

for line in lines:
    should_remove = False
    for uuid in uuids_to_remove:
        if uuid in line:
            should_remove = True
            removed_count += 1
            print(f"Removing: {line.strip()}")
            break

    if not should_remove:
        new_lines.append(line)

content = '\n'.join(new_lines)

# Now fix the paths for the files that DO exist
# These files need their path attribute updated to include the full path

fixes = [
    {
        'filename': 'AnalysisResultsTabbedView.swift',
        'path': 'Billix/Features/Upload/Views/Components/AnalysisResultsTabbedView.swift'
    },
    {
        'filename': 'AnalysisSummaryTab.swift',
        'path': 'Billix/Features/Upload/Views/Components/AnalysisSummaryTab.swift'
    },
    {
        'filename': 'BillAnalysisNewComponents.swift',
        'path': 'Billix/Features/Upload/Views/Components/BillAnalysisNewComponents.swift'
    }
]

for fix in fixes:
    filename = fix['filename']
    full_path = fix['path']

    # Find the PBXFileReference line for this file
    # Example: ABC123 /* AnalysisResultsTabbedView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AnalysisResultsTabbedView.swift; sourceTree = "<group>"; };

    # Pattern to match the file reference
    pattern = r'([A-F0-9]{24}) /\* ' + re.escape(filename) + r' \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = ' + re.escape(filename) + r'; sourceTree = "<group>"; \};'

    # Find it
    match = re.search(pattern, content)
    if match:
        old_line = match.group(0)
        uuid = match.group(1)

        # Build new line with full path
        new_line = f'{uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{full_path}"; sourceTree = SOURCE_ROOT; }};'

        content = content.replace(old_line, new_line)
        print(f"✓ Updated path for {filename}")
    else:
        print(f"⚠ Could not find file reference for {filename}")

# Write back
print(f"\nWriting updated {project_path}...")
with open(project_path, 'w') as f:
    f.write(content)

print(f"\n✓ Removed {removed_count} lines for non-existent files")
print(f"✓ Updated {len(fixes)} file paths")
