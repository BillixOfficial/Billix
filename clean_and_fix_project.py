#!/usr/bin/env python3
"""Clean up and fix project.pbxproj"""

import re
import uuid

def generate_uuid():
    """Generate a unique 24-character hex ID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

# Read project file
with open('/Users/jg_2030/Billix/Billix.xcodeproj/project.pbxproj', 'r') as f:
    lines = f.readlines()

# Remove all references to the three new files (both old and new UUIDs)
files_to_remove = [
    'CircularProgressRing.swift',
    'StarDisplay.swift',
    'SeasonCardLarge.swift',
    '569EADE396C943AD9D3937CF',
    'F1FDD63808364F348FAD6289',
    '8A93B90B05D34029BD725D92',
    '4E9836B2BD75402BAE66BB4E',
    '36B5F280B23F41E3A9F9CD00',
    '274F2D96A7DB4A9C9BA11F0A',
    '50E1A5C0F97E44C4BA03DC44',
    'F6AA3A55ECD74CD18996DD4A',
    '8C0A82CBBF5D4E6FBAFB8A37'
]

cleaned_lines = []
for line in lines:
    should_keep = True
    for pattern in files_to_remove:
        if pattern in line and ('PBXBuildFile' in line or 'PBXFileReference' in line or 'in Sources' in line):
            should_keep = False
            break
    if should_keep:
        cleaned_lines.append(line)

content = ''.join(cleaned_lines)

# Now add them correctly
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

# 3. Add to Components group - find the line with SeasonCard.swift and add after it
content = re.sub(
    r'(A6FF82892EECA1C5008330C9 /\* SeasonCard\.swift \*/,)',
    rf'\1\n\t\t\t\t{circ_ref} /* CircularProgressRing.swift */,\n\t\t\t\t{star_ref} /* StarDisplay.swift */,\n\t\t\t\t{card_ref} /* SeasonCardLarge.swift */,',
    content
)

# 4. Add to PBXSourcesBuildPhase - find any existing Sources entry and add nearby
# Find the PBXSourcesBuildPhase section
sources_match = re.search(r'/\* Begin PBXSourcesBuildPhase section \*/.*?files = \((.*?)\);', content, re.DOTALL)
if sources_match:
    files_section = sources_match.group(1)
    # Add our build file references
    new_sources = f'''{circ_build} /* CircularProgressRing.swift in Sources */,
\t\t\t\t{star_build} /* StarDisplay.swift in Sources */,
\t\t\t\t{card_build} /* SeasonCardLarge.swift in Sources */,
'''
    # Insert before the closing
    content = content.replace(
        'files = (',
        f'files = (\n\t\t\t\t{new_sources}'
    )

# Write back
with open('/Users/jg_2030/Billix/Billix.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ Successfully cleaned and added files:")
print(f"   - CircularProgressRing.swift ({circ_ref})")
print(f"   - StarDisplay.swift ({star_ref})")
print(f"   - SeasonCardLarge.swift ({card_ref})")
