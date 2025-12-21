#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find all the incorrectly added file references and remove them
target.source_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref

  # Remove files with duplicate paths
  if file_ref.path && file_ref.path.include?('Billix/Features/Rewards/Models/Billix')
    puts "Removing incorrectly added file: #{file_ref.path}"
    build_file.remove_from_project
    file_ref.remove_from_project
  elsif file_ref.path && file_ref.path.include?('Billix/Features/Rewards/ViewModels/Billix')
    puts "Removing incorrectly added file: #{file_ref.path}"
    build_file.remove_from_project
    file_ref.remove_from_project
  elsif file_ref.path && file_ref.path.include?('Billix/Features/Rewards/Billix')
    puts "Removing incorrectly added file: #{file_ref.path}"
    build_file.remove_from_project
    file_ref.remove_from_project
  elsif file_ref.path && file_ref.path.include?('Billix/Features/Rewards/Views/Billix')
    puts "Removing incorrectly added file: #{file_ref.path}"
    build_file.remove_from_project
    file_ref.remove_from_project
  end
end

# Now add them correctly with absolute paths
files_to_add = [
  "#{Dir.pwd}/Billix/Features/Rewards/Models/GeoGameModels.swift",
  "#{Dir.pwd}/Billix/Features/Rewards/ViewModels/GeoGameViewModel.swift",
  "#{Dir.pwd}/Billix/Features/Rewards/Services/GeoGameDataService.swift",
  "#{Dir.pwd}/Billix/Features/Rewards/Views/GeoGame/GeoGameContainerView.swift",
  "#{Dir.pwd}/Billix/Features/Rewards/Views/GeoGame/GeoGameMapView.swift",
  "#{Dir.pwd}/Billix/Features/Rewards/Views/GeoGame/GeoGameFloatingCard.swift",
  "#{Dir.pwd}/Billix/Features/Rewards/Views/GeoGame/Phase1LocationView.swift",
  "#{Dir.pwd}/Billix/Features/Rewards/Views/GeoGame/Phase2PriceView.swift",
  "#{Dir.pwd}/Billix/Features/Rewards/Views/GeoGame/GeoGameResultView.swift"
]

files_to_add.each do |absolute_path|
  if File.exist?(absolute_path)
    file_ref = project.new_file(absolute_path)
    target.add_file_references([file_ref])
    puts "Added: #{absolute_path}"
  else
    puts "WARNING: File not found: #{absolute_path}"
  end
end

# Save the project
project.save

puts "\nSuccessfully fixed Geo Game files in Xcode project!"
