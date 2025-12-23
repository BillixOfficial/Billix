#!/usr/bin/env python3
"""
Script to remove duplicate file references from Billix.xcodeproj
"""

import re

# Files that were duplicated (the ones we just added)
duplicate_uuids_to_remove = []

project_path = "Billix.xcodeproj/project.pbxproj"

print(f"Reading {project_path}...")
with open(project_path, 'r') as f:
    lines = f.readlines()

# Find duplicate file references by looking for files that appear multiple times
file_refs = {}
build_files = {}

# First pass: collect all file references
for i, line in enumerate(lines):
    # Match PBXFileReference lines
    ref_match = re.search(r'(\w{24}) /\* (\S+\.swift) \*/ = {isa = PBXFileReference', line)
    if ref_match:
        uuid = ref_match.group(1)
        filename = ref_match.group(2)
        if filename not in file_refs:
            file_refs[filename] = []
        file_refs[filename].append((uuid, i))

    # Match PBXBuildFile lines
    build_match = re.search(r'(\w{24}) /\* (\S+\.swift) in Sources \*/ = {isa = PBXBuildFile; fileRef = (\w{24})', line)
    if build_match:
        uuid = build_match.group(1)
        filename = build_match.group(2)
        ref_uuid = build_match.group(3)
        if filename not in build_files:
            build_files[filename] = []
        build_files[filename].append((uuid, ref_uuid, i))

# Find duplicates and decide which to remove
# We'll keep the SECOND entry (the one that was already there) and remove the FIRST (the one we just added)
uuids_to_remove = set()
filenames_with_duplicates = []

for filename, refs in file_refs.items():
    if len(refs) > 1:
        print(f"Found duplicate: {filename}")
        filenames_with_duplicates.append(filename)
        # Remove the FIRST occurrence (the one we just added at the top)
        uuid_to_remove = refs[0][0]
        uuids_to_remove.add(uuid_to_remove)
        print(f"  Will remove file ref UUID: {uuid_to_remove}")

        # Find corresponding build file entries
        if filename in build_files:
            for build_uuid, ref_uuid, line_num in build_files[filename]:
                if ref_uuid == uuid_to_remove:
                    uuids_to_remove.add(build_uuid)
                    print(f"  Will remove build file UUID: {build_uuid}")

# Second pass: remove lines containing these UUIDs
new_lines = []
removed_count = 0

for line in lines:
    should_remove = False
    for uuid in uuids_to_remove:
        if uuid in line:
            should_remove = True
            removed_count += 1
            print(f"Removing line: {line.strip()}")
            break

    if not should_remove:
        new_lines.append(line)

# Write back
print(f"\nWriting updated {project_path}...")
with open(project_path, 'w') as f:
    f.writelines(new_lines)

print(f"\n✓ Removed {removed_count} duplicate lines!")
print(f"✓ Fixed {len(filenames_with_duplicates)} duplicate files")
