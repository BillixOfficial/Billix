#!/usr/bin/env python3
"""
Remove duplicate file references from Marketplace/Components group.
The files should only be in Rewards/Views/Components.
"""

# Read the project file
with open('Billix.xcodeproj/project.pbxproj', 'r') as f:
    lines = f.readlines()

# Find the Marketplace Components group (UUID: A4C6E83221EA5E2F1A2183B3)
# This spans approximately lines 673-686
# We need to remove lines 679-681 which contain our three files

# The UUIDs to remove from this group:
uuids_to_remove = [
    '69DEDDF70B61491993119973',  # ContinuousHealthBar.swift
    '08EE7D81F35342AF942A8987',  # CompactTopHUD.swift
    '51D7BD2B736844D1A8CE5793',  # MinimalBottomDeck.swift
]

# Track if we're inside the Marketplace Components group
in_marketplace_components = False
marketplace_start_line = None
new_lines = []

for i, line in enumerate(lines):
    # Check if we're entering the Marketplace Components group
    if 'A4C6E83221EA5E2F1A2183B3 /* Components */' in line:
        in_marketplace_components = True
        marketplace_start_line = i
        new_lines.append(line)
        continue

    # Check if we're exiting the group (closing brace at same indent level)
    if in_marketplace_components and line.strip() == '};':
        in_marketplace_components = False
        new_lines.append(line)
        continue

    # Skip lines containing our UUIDs if we're in the Marketplace Components group
    if in_marketplace_components:
        should_skip = False
        for uuid in uuids_to_remove:
            if uuid in line:
                should_skip = True
                print(f"Removing duplicate reference from Marketplace/Components: {line.strip()}")
                break

        if not should_skip:
            new_lines.append(line)
    else:
        new_lines.append(line)

# Write back
with open('Billix.xcodeproj/project.pbxproj', 'w') as f:
    f.writelines(new_lines)

print("\n✓ Removed duplicate file references from Marketplace/Components group")
print("✓ Files remain in correct location: Rewards/Views/Components")
