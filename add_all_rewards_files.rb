#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'Billix' }

files_to_add = [
  'Billix/Features/Rewards/Models/RewardsModels.swift',
  'Billix/Features/Rewards/ViewModels/RewardsViewModel.swift'
]

files_to_add.each do |file_path|
  existing_file = project.files.find { |f| f.path == file_path }

  if existing_file
    puts "Already in project: #{file_path}"
  else
    if File.exist?(file_path)
      file_ref = project.new_file(file_path)
      target.add_file_references([file_ref])
      puts "Added: #{file_path}"
    else
      puts "File not found: #{file_path}"
    end
  end
end

project.save

puts "✅ Project saved"
