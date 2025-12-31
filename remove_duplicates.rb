#!/usr/bin/env ruby
# Remove duplicate file references from Xcode build phase

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }

puts "=== REMOVING DUPLICATE FILES FROM BUILD PHASE ==="

# Get all build files in the source build phase
build_files = target.source_build_phase.files
file_refs_seen = {}
duplicates_removed = 0

# Iterate through build files and track duplicates
build_files.each do |build_file|
  next unless build_file.file_ref

  file_name = build_file.file_ref.display_name

  if file_refs_seen[file_name]
    # This is a duplicate - remove it
    build_file.remove_from_project
    puts "✓ Removed duplicate: #{file_name}"
    duplicates_removed += 1
  else
    # First occurrence - track it
    file_refs_seen[file_name] = true
  end
end

project.save

puts "\n" + "="*60
puts "✅ COMPLETE: Removed #{duplicates_removed} duplicate file references"
puts "="*60
puts "\nNow build in Xcode (Cmd+B)"
