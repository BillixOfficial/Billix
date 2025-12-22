#!/usr/bin/env python3
"""Fix project.pbxproj to add new component files correctly"""

import uuid
import re

def generate_uuid():
    """Generate a unique 24-character hex ID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

# Read project file
with open('/Users/jg_2030/Billix/Billix.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs
circ_ref = generate_uuid()
star_ref = generate_uuid()
card_ref = generate_uuid()

circ_build = generate_uuid()
star_build = generate_uuid()
card_build = generate_uuid()

# 1. Add to PBXFileReference section
file_ref_section = '/* End PBXFileReference section */'
new_refs = f'''\t\t{circ_ref} /* CircularProgressRing.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CircularProgressRing.swift; sourceTree = "<group>"; }};
\t\t{star_ref} /* StarDisplay.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = StarDisplay.swift; sourceTree = "<group>"; }};
\t\t{card_ref} /* SeasonCardLarge.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SeasonCardLarge.swift; sourceTree = "<group>"; }};
'''
content = content.replace(file_ref_section, new_refs + file_ref_section)

# 2. Add to PBXBuildFile section
build_file_section = '/* End PBXBuildFile section */'
new_builds = f'''\t\t{circ_build} /* CircularProgressRing.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {circ_ref} /* CircularProgressRing.swift */; }};
\t\t{star_build} /* StarDisplay.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {star_ref} /* StarDisplay.swift */; }};
\t\t{card_build} /* SeasonCardLarge.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {card_ref} /* SeasonCardLarge.swift */; }};
'''
content = content.replace(build_file_section, new_builds + build_file_section)

# 3. Add to Components group children
components_group_pattern = r'A6FF828A2EECA1C5008330C9 /\* Components \*/ = \{[^}]+children = \([^)]+\);'
match = re.search(components_group_pattern, content, re.DOTALL)
if match:
    old_group = match.group(0)
    # Find the closing of children array
    children_close = old_group.rindex(');')
    new_children = f'''\t\t\t\t{circ_ref} /* CircularProgressRing.swift */,
\t\t\t\t{star_ref} /* StarDisplay.swift */,
\t\t\t\t{card_ref} /* SeasonCardLarge.swift */,
'''
    new_group = old_group[:children_close] + new_children + old_group[children_close:]
    content = content.replace(old_group, new_group)

# 4. Add to PBXSourcesBuildPhase files array
sources_phase_pattern = r'files = \([^)]+\);[^}]+/\* PBXSourcesBuildPhase \*/'
match = re.search(sources_phase_pattern, content, re.DOTALL)
if match:
    old_phase = match.group(0)
    # Find the closing of files array
    files_close = old_phase.index(');')
    new_files = f'''\t\t\t\t{circ_build} /* CircularProgressRing.swift in Sources */,
\t\t\t\t{star_build} /* StarDisplay.swift in Sources */,
\t\t\t\t{card_build} /* SeasonCardLarge.swift in Sources */,
'''
    new_phase = old_phase[:files_close] + new_files + old_phase[files_close:]
    content = content.replace(old_phase, new_phase)

# Write back
with open('/Users/jg_2030/Billix/Billix.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ Successfully added files to project:")
print(f"   - CircularProgressRing.swift ({circ_ref})")
print(f"   - StarDisplay.swift ({star_ref})")
print(f"   - SeasonCardLarge.swift ({card_ref})")
