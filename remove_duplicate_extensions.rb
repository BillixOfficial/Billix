#!/usr/bin/env ruby
# Remove duplicate extension files from Xcode project

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }

# Files to remove (duplicates of functionality in other files)
files_to_remove = [
  'Color+Hex.swift',  # Duplicate of ColorPalette.swift
  'NetworkError.swift'  # May be duplicate
]

removed_count = 0

# Find and remove
target.source_build_phase.files.each do |bf|
  ref = bf.file_ref
  next unless ref

  name = ref.name || File.basename(ref.path.to_s)
  if files_to_remove.include?(name)
    puts "Removing: #{name}"
    target.source_build_phase.files.delete(bf)
    ref.remove_from_project if ref.parent
    removed_count += 1
  end
end

project.save
puts "\nRemoved #{removed_count} duplicate files."
