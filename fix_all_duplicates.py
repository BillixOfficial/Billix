#!/usr/bin/env python3
"""
Remove all duplicate file references except from the CORRECT Components group.
The files should ONLY be in Rewards/Views/Components (UUID: A6FF822B2EDE3AD4008330C9).
"""

# Read the project file
with open('Billix.xcodeproj/project.pbxproj', 'r') as f:
    lines = f.readlines()

# The CORRECT Components group UUID where files should remain
CORRECT_GROUP_UUID = 'A6FF822B2EDE3AD4008330C9'

# The UUIDs of our three files
FILE_UUIDS = [
    '69DEDDF70B61491993119973',  # ContinuousHealthBar.swift
    '08EE7D81F35342AF942A8987',  # CompactTopHUD.swift
    '51D7BD2B736844D1A8CE5793',  # MinimalBottomDeck.swift
]

# Track which group we're in
current_group_uuid = None
in_group = False
new_lines = []
removed_count = 0

for i, line in enumerate(lines):
    # Check if we're entering a PBXGroup
    if '/* Components */ = {' in line or 'PBXGroup;' in line or 'children = (' in line:
        # Extract UUID from lines like "A6FF822B2EDE3AD4008330C9 /* Components */ = {"
        for word in line.split():
            if len(word) == 24 and word.isalnum():
                # This might be a UUID
                potential_uuid = word
                # Check if next part contains "/* Components */"
                if '/* Components */' in line:
                    current_group_uuid = potential_uuid
                    in_group = True
                    break
        new_lines.append(line)
        continue

    # Check if we're exiting a group
    if in_group and line.strip() in ['};', ');']:
        if line.strip() == '};':
            in_group = False
            current_group_uuid = None
        new_lines.append(line)
        continue

    # If we're in a group and it's NOT the correct group, remove our file references
    if in_group and current_group_uuid and current_group_uuid != CORRECT_GROUP_UUID:
        should_skip = False
        for uuid in FILE_UUIDS:
            if uuid in line:
                should_skip = True
                removed_count += 1
                print(f"Removing from group {current_group_uuid}: {line.strip()}")
                break

        if not should_skip:
            new_lines.append(line)
    else:
        new_lines.append(line)

# Write back
with open('Billix.xcodeproj/project.pbxproj', 'w') as f:
    f.writelines(new_lines)

print(f"\n✓ Removed {removed_count} duplicate file reference(s)")
print(f"✓ Files remain ONLY in correct group: {CORRECT_GROUP_UUID} (Rewards/Views/Components)")
