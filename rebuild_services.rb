#!/usr/bin/env ruby
# Complete rebuild of TrustLadder Services references

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Find the TrustLadder Services group
trust_ladder_group = project.main_group['Billix']['Features']['TrustLadder']
services_group = trust_ladder_group['Services']

# Remove ALL existing file references in Services group
puts "Removing all existing service files from project..."
services_group.files.each do |file|
  puts "  Removing: #{file.name} (#{file.path})"
  target.source_build_phase.files.delete_if { |bf| bf.file_ref == file }
  file.remove_from_project
end

# Also find and remove any orphaned build files for TrustLadder services
target.source_build_phase.files.each do |build_file|
  ref = build_file.file_ref
  next unless ref

  path = ref.path.to_s
  if path.include?('TrustLadder/Services') && path.include?('TrustLadder/Services/Billix')
    puts "  Removing orphaned build file: #{path}"
    target.source_build_phase.files.delete(build_file)
    ref.remove_from_project if ref.parent
  end
end

project.save
puts "\nCleaned up. Now re-adding files..."

# Re-open project
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }
trust_ladder_group = project.main_group['Billix']['Features']['TrustLadder']
services_group = trust_ladder_group['Services']

# Get all .swift files in the services directory
services_dir = 'Billix/Features/TrustLadder/Services'
swift_files = Dir.glob("#{services_dir}/*.swift").sort

puts "\nAdding #{swift_files.count} service files..."

swift_files.each do |full_path|
  filename = File.basename(full_path)

  # Create file reference with just the filename, path relative to group
  file_ref = services_group.new_reference(filename)
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "  Added: #{filename}"
end

project.save
puts "\nDone! Project saved."
