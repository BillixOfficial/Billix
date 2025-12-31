#!/usr/bin/env ruby
# Add Color+Hex.swift to Utilities (no Core group exists)

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }

puts "=== ADDING Color+Hex.swift ==="
utilities_group = project.main_group['Billix']['Utilities']

if utilities_group
  file_path = 'Billix/Core/Extensions/Color+Hex.swift'
  filename = 'Color+Hex.swift'

  if File.exist?(file_path) && !utilities_group.files.any? { |f| f.name == filename }
    # Add reference with actual file path
    file_ref = utilities_group.new_file(file_path)
    target.source_build_phase.add_file_reference(file_ref)
    puts "✓ Added: Color+Hex.swift to Utilities"
    puts "  (File is in Billix/Core/Extensions/ but added to Utilities group)"

    project.save
    puts "\n✅ Done!"
  else
    puts "Already exists or file not found"
  end
else
  puts "❌ Utilities group not found"
end
