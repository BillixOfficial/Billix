#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Files that are incorrectly in Resources/Frameworks
problem_files = [
  'CircularProgressRing.swift',
  'StarDisplay.swift',
  'SeasonCardLarge.swift'
]

project.targets.each do |target|
  next unless target.name == 'Billix'

  puts "Fixing target: #{target.name}"

  # Remove from Resources build phase
  target.resources_build_phase.files.each do |build_file|
    file_ref = build_file.file_ref
    next unless file_ref && file_ref.path

    if problem_files.include?(file_ref.path)
      puts "  Removing #{file_ref.path} from Resources"
      build_file.remove_from_project
    end
  end

  # Remove from Frameworks build phase
  target.frameworks_build_phases.each do |frameworks_phase|
    frameworks_phase.files.to_a.each do |build_file|
      file_ref = build_file.file_ref
      next unless file_ref && file_ref.path

      if problem_files.include?(file_ref.path)
        puts "  Removing #{file_ref.path} from Frameworks"
        build_file.remove_from_project
      end
    end
  end

  # Ensure they're in Sources (they already should be)
  target.source_build_phase.files.each do |build_file|
    file_ref = build_file.file_ref
    next unless file_ref && file_ref.path

    if problem_files.include?(file_ref.path)
      puts "  ✓ #{file_ref.path} is in Sources (correct)"
    end
  end
end

project.save
puts "\n✅ Project file fixed!"
