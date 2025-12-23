#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

files_to_remove = [
  'Billix/Features/Rewards/Views/Components/GameBoostsModal.swift',
  'Billix/Features/Rewards/Views/Components/VirtualGoodsModal.swift'
]

files_to_remove.each do |file_path|
  file_ref = project.files.find { |f| f.path == file_path }

  if file_ref
    file_ref.remove_from_project
    puts "Removed: #{file_path}"
  else
    puts "Not found: #{file_path}"
  end
end

project.save

puts "✅ Project saved"
