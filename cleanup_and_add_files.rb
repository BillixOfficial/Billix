#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

puts "Removing all GeoGame file references..."

# Remove ALL geo game file references (regardless of path)
files_to_remove = []
target.source_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref && file_ref.path

  if file_ref.path.include?('GeoGame') ||
     file_ref.path.include?('Phase1Location') ||
     file_ref.path.include?('Phase2Price')
    puts "Removing: #{file_ref.path}"
    files_to_remove << build_file
  end
end

# Remove them
files_to_remove.each do |build_file|
  build_file.remove_from_project
  build_file.file_ref.remove_from_project if build_file.file_ref
end

puts "\nAdding files correctly..."

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
    puts "Added: #{File.basename(absolute_path)}"
  else
    puts "WARNING: File not found: #{absolute_path}"
  end
end

# Save the project
project.save

puts "\nProject updated successfully!"
