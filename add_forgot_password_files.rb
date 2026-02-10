#!/usr/bin/env ruby
# Script to add forgot password files to the Xcode project

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }
unless target
  puts "Error: Could not find target 'Billix'"
  exit 1
end

# Files to add
files_to_add = [
  { path: 'Billix/Features/Auth/ForgotPasswordView.swift', group_path: 'Billix/Features/Auth' },
  { path: 'Billix/Features/Auth/SetNewPasswordView.swift', group_path: 'Billix/Features/Auth' }
]

def find_or_create_group(project, group_path)
  components = group_path.split('/')
  current_group = project.main_group

  components.each do |component|
    found_group = current_group.groups.find { |g| g.name == component || g.path == component }
    if found_group
      current_group = found_group
    else
      current_group = current_group.new_group(component, component)
    end
  end

  current_group
end

files_to_add.each do |file_info|
  file_path = file_info[:path]
  group_path = file_info[:group_path]

  # Check if file exists
  unless File.exist?(file_path)
    puts "Warning: File does not exist: #{file_path}"
    next
  end

  # Find or create the group
  group = find_or_create_group(project, group_path)

  # Check if file is already in project
  existing_ref = group.files.find { |f| f.path == File.basename(file_path) }
  if existing_ref
    puts "File already in project: #{file_path}"
    next
  end

  # Add file reference
  file_ref = group.new_file(file_path)

  # Add to target's compile sources
  target.source_build_phase.add_file_reference(file_ref)

  puts "Added: #{file_path}"
end

project.save
puts "Project saved successfully!"
