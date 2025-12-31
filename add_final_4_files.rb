#!/usr/bin/env ruby
# Add the final 4 missing files

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }

def ensure_group(parent_group, group_name, path = nil)
  group = parent_group[group_name]
  if group.nil?
    group = parent_group.new_group(group_name, path || group_name)
    puts "  Created group: #{group_name}"
  end
  group
end

def add_file(group, file_path, target)
  filename = File.basename(file_path)
  if File.exist?(file_path) && !group.files.any? { |f| f.name == filename }
    file_ref = group.new_reference(filename)
    file_ref.source_tree = '<group>'
    target.source_build_phase.add_file_reference(file_ref)
    puts "✓ Added: #{filename}"
    return 1
  end
  0
end

total_added = 0

# CORE/EXTENSIONS - Color+Hex.swift
puts "=== CORE/EXTENSIONS ==="
core_group = project.main_group['Billix']['Core']
if core_group
  extensions_group = ensure_group(core_group, 'Extensions')
  total_added += add_file(extensions_group, 'Billix/Core/Extensions/Color+Hex.swift', target)
end

# UTILITIES/COMPONENTS - 3 files
puts "\n=== UTILITIES/COMPONENTS ==="
utilities_group = project.main_group['Billix']['Utilities']
if utilities_group
  components_group = ensure_group(utilities_group, 'Components')

  total_added += add_file(components_group, 'Billix/Utilities/Components/AnimatedBackground.swift', target)
  total_added += add_file(components_group, 'Billix/Utilities/Components/CountUp.swift', target)
  total_added += add_file(components_group, 'Billix/Utilities/Components/Sparkline.swift', target)
end

project.save

puts "\n" + "="*60
puts "✅ COMPLETE: Added #{total_added} files"
puts "="*60
puts "\nAll files from main merge are now in Xcode!"
puts "Total: 315 + #{total_added} = #{315 + total_added} files"
