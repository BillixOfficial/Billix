#!/usr/bin/env ruby
# Comprehensive duplicate removal - checks by file reference UUID

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }

puts "=== REMOVING ALL DUPLICATE FILE REFERENCES ==="

build_files = target.source_build_phase.files
file_ref_uuids_seen = {}
duplicates_removed = 0
removed_files = []

# Track by file_ref UUID (more accurate than name)
build_files_to_keep = []
build_files.each do |build_file|
  next unless build_file.file_ref

  file_ref_uuid = build_file.file_ref.uuid
  file_name = build_file.file_ref.display_name

  if file_ref_uuids_seen[file_ref_uuid]
    # Duplicate detected
    removed_files << file_name
    duplicates_removed += 1
    # Don't add to keep list - this will remove it
  else
    # First occurrence - keep it
    file_ref_uuids_seen[file_ref_uuid] = true
    build_files_to_keep << build_file
  end
end

# Clear all build files
target.source_build_phase.clear

# Re-add only the unique ones
build_files_to_keep.each do |build_file|
  target.source_build_phase.files << build_file
end

project.save

puts "\n✓ Removed #{duplicates_removed} duplicate references:"
removed_files.uniq.each do |name|
  count = removed_files.count(name)
  puts "  - #{name} (#{count} duplicate#{count > 1 ? 's' : ''})"
end

puts "\n" + "="*60
puts "✅ COMPLETE: Build phase cleaned"
puts "="*60
