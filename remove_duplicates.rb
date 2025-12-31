#!/usr/bin/env ruby
# Script to remove duplicate file references from Xcode project

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Remove duplicates from source build phase
seen_files = {}
files_to_remove = []

target.source_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref

  name = file_ref.name || file_ref.path
  if seen_files[name]
    puts "Found duplicate: #{name}"
    files_to_remove << build_file
  else
    seen_files[name] = true
  end
end

files_to_remove.each do |build_file|
  target.source_build_phase.files.delete(build_file)
  puts "Removed duplicate build file"
end

# Also remove duplicate file references in groups
def remove_duplicate_refs(group, target)
  seen = {}
  to_remove = []

  group.files.each do |file|
    name = file.name || file.path
    if seen[name]
      puts "Found duplicate file ref: #{name}"
      to_remove << file
    else
      seen[name] = true
    end
  end

  to_remove.each do |file|
    # Remove from build phases
    target.source_build_phase.files.delete_if { |bf| bf.file_ref == file }
    target.resources_build_phase.files.delete_if { |bf| bf.file_ref == file }
    file.remove_from_project
    puts "Removed file ref"
  end

  # Recurse into subgroups
  group.groups.each { |g| remove_duplicate_refs(g, target) }
end

remove_duplicate_refs(project.main_group, target)

project.save
puts "\nDuplicates removed and project saved."
