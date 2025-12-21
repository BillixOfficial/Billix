#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Files to add
files_to_add = [
  'Billix/Features/Rewards/Views/RewardsHubView.swift',
  'Billix/Features/Rewards/Views/Components/GameBoostsModal.swift',
  'Billix/Features/Rewards/Views/Components/VirtualGoodsModal.swift'
]

files_to_add.each do |file_path|
  # Check if file already exists in project
  existing_file = project.files.find { |f| f.path == file_path }

  if existing_file
    puts "File already in project: #{file_path}"
  else
    # Add file to project
    file_ref = project.new_file(file_path)

    # Add to target's sources build phase
    target.add_file_references([file_ref])

    puts "Added file: #{file_path}"
  end
end

project.save

puts "✅ Project saved successfully"
