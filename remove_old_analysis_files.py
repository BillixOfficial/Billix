#!/usr/bin/env python3
"""
Remove old analysis file references from project.pbxproj
"""

import re

project_path = "Billix.xcodeproj/project.pbxproj"

# Files we just deleted (old location)
old_files = [
    "AnalysisBreakdownTab.swift",
    "AnalysisCompareTab.swift",
    "AnalysisComponents.swift",
    "AnalysisDetailsTab.swift",
    "AnalysisResultsSimpleView.swift",
    "AnalysisResultsView.swift",
    "BillGaugeView.swift",
    "MetricCardView.swift"
]

print(f"Reading {project_path}...")
with open(project_path, 'r') as f:
    lines = f.readlines()

# Find UUIDs for these files
uuids_to_remove = set()

for i, line in enumerate(lines):
    for filename in old_files:
        # Look for file references
        if f'/* {filename} */' in line:
            # Extract UUID
            match = re.search(r'([A-F0-9]{24})', line)
            if match:
                uuid = match.group(1)
                uuids_to_remove.add(uuid)
                print(f"Found UUID {uuid} for {filename}")

print(f"\nRemoving {len(uuids_to_remove)} UUIDs...")

# Remove lines containing these UUIDs
new_lines = []
removed = 0

for line in lines:
    should_remove = False
    for uuid in uuids_to_remove:
        if uuid in line:
            should_remove = True
            removed += 1
            break

    if not should_remove:
        new_lines.append(line)

print(f"Writing {project_path}...")
with open(project_path, 'w') as f:
    f.writelines(new_lines)

print(f"✓ Removed {removed} lines")
