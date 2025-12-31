#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }

files_to_add = [
  'Billix/Features/Explore/Models/ExploreCarouselModels.swift',
  'Billix/Features/Explore/Views/ExploreCarouselCard.swift',
  'Billix/Features/Explore/Views/ExploreSubFeatureSheet.swift'
]

added = []
skipped = []

files_to_add.each do |file_path|
  existing = project.files.find { |f| f.path == file_path }

  if existing
    skipped << file_path
  elsif File.exist?(file_path)
    file_ref = project.new_file(file_path)
    target.add_file_references([file_ref])
    added << file_path
  else
    puts "File not found: #{file_path}"
  end
end

project.save

puts "Added #{added.length} files"
added.each { |f| puts "  + #{f}" }
puts "Skipped #{skipped.length} existing files"
