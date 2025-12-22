#!/usr/bin/env python3
"""
Script to add missing Swift files to Billix.xcodeproj
"""

import uuid
import sys

# List of files that need to be added to the project
missing_files = [
    # Upload Components
    "Billix/Features/Upload/Views/Components/AnalysisResultsTabbedView.swift",
    "Billix/Features/Upload/Views/Components/AnalysisSummaryTab.swift",
    "Billix/Features/Upload/Views/Components/BillAnalysisNewComponents.swift",
    "Billix/Features/Upload/Views/AllUploadsView.swift",
    "Billix/Features/Upload/Views/UploadDetailView.swift",

    # Rewards - GeoGame Views
    "Billix/Features/Rewards/Views/GeoGame/GeoGameView.swift",
    "Billix/Features/Rewards/Views/GeoGame/GeoGameMapView.swift",
    "Billix/Features/Rewards/Views/GeoGame/Phase1LocationView.swift",
    "Billix/Features/Rewards/Views/GeoGame/Phase2PriceView.swift",
    "Billix/Features/Rewards/Views/GeoGame/ResultView.swift",
    "Billix/Features/Rewards/Views/GeoGame/PhaseIndicatorView.swift",

    # Rewards - Data & ViewModels
    "Billix/Features/Rewards/Models/GeoGameModels.swift",
    "Billix/Features/Rewards/ViewModels/GeoGameViewModel.swift",
    "Billix/Features/Rewards/Services/GeoGameDataService.swift",
    "Billix/Features/Rewards/Views/RewardsHubView.swift",
]

def generate_uuid():
    """Generate a unique 24-character hex ID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_project():
    """Add missing files to project.pbxproj"""

    project_path = "Billix.xcodeproj/project.pbxproj"

    print(f"Reading {project_path}...")
    with open(project_path, 'r') as f:
        content = f.read()

    # Generate UUIDs for each file (2 per file: one for PBXFileReference, one for PBXBuildFile)
    file_entries = []
    build_entries = []
    build_phase_entries = []

    for file_path in missing_files:
        # Check if file already exists in project
        if file_path in content:
            print(f"✓ {file_path} already in project")
            continue

        filename = file_path.split('/')[-1]
        file_ref_id = generate_uuid()
        build_file_id = generate_uuid()

        # PBXFileReference entry
        file_entry = f'\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};'
        file_entries.append((file_ref_id, file_entry, file_path))

        # PBXBuildFile entry
        build_entry = f'\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};'
        build_entries.append(build_entry)

        # Build phase entry
        build_phase_entry = f'\t\t\t\t{build_file_id} /* {filename} in Sources */,'
        build_phase_entries.append(build_phase_entry)

        print(f"+ Will add {filename}")

    if not file_entries:
        print("\nAll files already in project!")
        return

    # Find insertion points
    pbx_build_file_section = "/* Begin PBXBuildFile section */"
    pbx_file_ref_section = "/* Begin PBXFileReference section */"
    pbx_sources_build_phase = "/* Begin PBXSourcesBuildPhase section */"

    # Insert PBXBuildFile entries
    build_file_pos = content.find(pbx_build_file_section)
    if build_file_pos == -1:
        print("ERROR: Could not find PBXBuildFile section")
        return

    # Find end of first line
    build_file_insert_pos = content.find('\n', build_file_pos) + 1

    # Insert all build entries
    for entry in build_entries:
        content = content[:build_file_insert_pos] + entry + '\n' + content[build_file_insert_pos:]
        build_file_insert_pos += len(entry) + 1

    # Insert PBXFileReference entries
    file_ref_pos = content.find(pbx_file_ref_section)
    if file_ref_pos == -1:
        print("ERROR: Could not find PBXFileReference section")
        return

    file_ref_insert_pos = content.find('\n', file_ref_pos) + 1

    for file_ref_id, entry, file_path in file_entries:
        content = content[:file_ref_insert_pos] + entry + '\n' + content[file_ref_insert_pos:]
        file_ref_insert_pos += len(entry) + 1

    # Insert into Sources build phase
    sources_pos = content.find(pbx_sources_build_phase)
    if sources_pos == -1:
        print("ERROR: Could not find PBXSourcesBuildPhase section")
        return

    # Find the files = ( section
    files_section = content.find("files = (", sources_pos)
    if files_section == -1:
        print("ERROR: Could not find files section in PBXSourcesBuildPhase")
        return

    # Find end of line after "files = ("
    sources_insert_pos = content.find('\n', files_section) + 1

    for entry in build_phase_entries:
        content = content[:sources_insert_pos] + entry + '\n' + content[sources_insert_pos:]
        sources_insert_pos += len(entry) + 1

    # Write back
    print(f"\nWriting updated {project_path}...")
    with open(project_path, 'w') as f:
        f.write(content)

    print(f"\n✓ Added {len(file_entries)} files to project!")
    print("\nPlease open Xcode and verify the project builds correctly.")

if __name__ == "__main__":
    add_files_to_project()
