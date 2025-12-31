#!/usr/bin/env ruby
# Comprehensive script to sync all Swift files to Xcode project

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }

# Get all existing file paths in project
existing_paths = Set.new
target.source_build_phase.files.each do |bf|
  ref = bf.file_ref
  next unless ref
  if ref.real_path
    existing_paths.add(ref.real_path.to_s)
  end
end

puts "Files currently in project: #{existing_paths.count}"

# Helper to find or create group hierarchy
def find_or_create_group(project, path_components)
  current = project.main_group
  path_components.each do |component|
    found = current.groups.find { |g| g.name == component || g.path == component }
    if found
      current = found
    else
      current = current.new_group(component, component)
    end
  end
  current
end

# Find all Swift files
all_swift_files = Dir.glob('Billix/**/*.swift').reject { |f| f.include?('.build') }
puts "Swift files on disk: #{all_swift_files.count}"

added_count = 0

all_swift_files.each do |file_path|
  full_path = File.expand_path(file_path)

  # Skip if already in project
  next if existing_paths.include?(full_path)

  # Parse path to find group
  # e.g., "Billix/Features/Home/Services/StreakService.swift"
  parts = file_path.split('/')
  filename = parts.pop  # Remove filename

  # Find or create the group
  group = find_or_create_group(project, parts)

  # Check if file already exists in group
  if group.files.any? { |f| f.name == filename || f.path == filename }
    next
  end

  # Add file
  file_ref = group.new_reference(filename)
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added: #{file_path}"
  added_count += 1
end

project.save
puts "\nAdded #{added_count} files to project."
