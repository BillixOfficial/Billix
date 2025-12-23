#!/usr/bin/env python3
"""Add Phase 1 Season UI components to Xcode project"""

import uuid
import sys

def generate_uuid():
    """Generate a unique 24-character hex ID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_project(project_path):
    """Add new component files to Xcode project"""

    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()

    # Files to add with their paths
    files_to_add = [
        {
            'name': 'CircularProgressRing.swift',
            'path': 'Billix/Features/Rewards/Views/Seasons/Components/CircularProgressRing.swift'
        },
        {
            'name': 'StarDisplay.swift',
            'path': 'Billix/Features/Rewards/Views/Seasons/Components/StarDisplay.swift'
        },
        {
            'name': 'SeasonCardLarge.swift',
            'path': 'Billix/Features/Rewards/Views/Seasons/Components/SeasonCardLarge.swift'
        }
    ]

    # Generate UUIDs for each file
    file_refs = []
    build_files = []

    for file_info in files_to_add:
        file_ref_id = generate_uuid()
        build_file_id = generate_uuid()

        file_refs.append({
            'id': file_ref_id,
            'name': file_info['name'],
            'path': file_info['path']
        })

        build_files.append({
            'id': build_file_id,
            'file_ref': file_ref_id
        })

    # Find the PBXFileReference section
    file_ref_section_start = content.find('/* Begin PBXFileReference section */')
    if file_ref_section_start == -1:
        print("Error: Could not find PBXFileReference section")
        return False

    # Find the end of the section
    file_ref_section_end = content.find('/* End PBXFileReference section */', file_ref_section_start)

    # Add file references
    new_file_refs = []
    for ref in file_refs:
        # Extract just the directory part relative to the file
        path_parts = ref["path"].split('/')
        file_name = path_parts[-1]
        new_file_refs.append(f'\t\t{ref["id"]} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};\n')

    content = content[:file_ref_section_end] + ''.join(new_file_refs) + content[file_ref_section_end:]

    # Find the PBXBuildFile section
    build_file_section_start = content.find('/* Begin PBXBuildFile section */')
    if build_file_section_start == -1:
        print("Error: Could not find PBXBuildFile section")
        return False

    build_file_section_end = content.find('/* End PBXBuildFile section */', build_file_section_start)

    # Add build files
    new_build_files = []
    for build in build_files:
        file_name = next(ref['name'] for ref in file_refs if ref['id'] == build['file_ref'])
        new_build_files.append(f'\t\t{build["id"]} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {build["file_ref"]} /* {file_name} */; }};\n')

    content = content[:build_file_section_end] + ''.join(new_build_files) + content[build_file_section_end:]

    # Find the Components group (where SeasonCard.swift and other components are)
    # Search for the group that contains SeasonCard.swift or SeasonThemeBackground.swift
    components_group_pattern = 'name = Components;'
    components_group_start = content.find(components_group_pattern)

    if components_group_start == -1:
        print("Warning: Could not find Components group, will create it")
        # If no Components group, find Seasons group instead
        seasons_pattern = 'name = Seasons;'
        seasons_start = content.find(seasons_pattern)
        if seasons_start != -1:
            # Find the children array for Seasons group
            children_start = content.find('children = (', seasons_start - 200)
            children_end = content.find(');', children_start)

            # Add file references to the group
            for ref in file_refs:
                insert_pos = children_end
                new_child = f'\t\t\t\t{ref["id"]} /* {ref["name"]} */,\n'
                content = content[:insert_pos] + new_child + content[insert_pos:]
                children_end += len(new_child)
    else:
        # Find the children array for Components group
        children_start = content.find('children = (', components_group_start - 200)
        if children_start != -1:
            children_end = content.find(');', children_start)

            # Add file references to the group
            for ref in file_refs:
                insert_pos = children_end
                new_child = f'\t\t\t\t{ref["id"]} /* {ref["name"]} */,\n'
                content = content[:insert_pos] + new_child + content[insert_pos:]
                children_end += len(new_child)

    # Find PBXSourcesBuildPhase section and add build files
    sources_phase_start = content.find('/* Begin PBXSourcesBuildPhase section */')
    if sources_phase_start != -1:
        # Find the files array
        files_start = content.find('files = (', sources_phase_start)
        if files_start != -1:
            files_end = content.find(');', files_start)

            # Add build files
            for build in build_files:
                file_name = next(ref['name'] for ref in file_refs if ref['id'] == build['file_ref'])
                insert_pos = files_end
                new_file = f'\t\t\t\t{build["id"]} /* {file_name} in Sources */,\n'
                content = content[:insert_pos] + new_file + content[insert_pos:]
                files_end += len(new_file)

    # Write the updated project file
    with open(project_path, 'w') as f:
        f.write(content)

    print(f"✅ Successfully added {len(files_to_add)} files to Xcode project:")
    for file_info in files_to_add:
        print(f"   - {file_info['name']}")

    return True

if __name__ == '__main__':
    project_path = '/Users/jg_2030/Billix/Billix.xcodeproj/project.pbxproj'

    if add_files_to_project(project_path):
        print("\n✅ Project file updated successfully!")
        sys.exit(0)
    else:
        print("\n❌ Failed to update project file")
        sys.exit(1)
