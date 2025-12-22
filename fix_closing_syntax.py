#!/usr/bin/env python3
"""
Fix malformed closing syntax: ,); should be split into:
,
);
"""

# Read the project file
with open('Billix.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Find and replace the malformed closing
# Replace ",);" with ",\n\t\t\t);" (assuming tabs for indentation)
fixes_made = 0

# For the Components group (line 955 area)
if ',);' in content:
    lines = content.split('\n')
    new_lines = []

    for i, line in enumerate(lines):
        if 'MinimalBottomDeck.swift' in line and ',);' in line:
            # Split this into two lines
            # Extract the indentation
            indent = line[:len(line) - len(line.lstrip())]
            # Remove the ");
 " part and keep just the comma
            fixed_line = line.replace(',);', ',')
            new_lines.append(fixed_line)
            # Add the closing parenthesis on next line
            new_lines.append(indent + ');')
            fixes_made += 1
            print(f"Fixed line {i+1}: {line.strip()} → split into two lines")
        else:
            new_lines.append(line)

    content = '\n'.join(new_lines)

# Write back
with open('Billix.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print(f"\n✓ Fixed {fixes_made} malformed closing(s)")
