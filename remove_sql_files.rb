#!/usr/bin/env ruby
# Script to remove SQL files from Xcode project (they're migration scripts, not app resources)

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Find the TrustLadder Migrations group
trust_ladder_group = project.main_group['Billix']['Features']['TrustLadder']
migrations_group = trust_ladder_group['Migrations']

if migrations_group
  # Remove all files from Migrations group
  migrations_group.files.each do |file|
    puts "Removing #{file.name} from project"
    # Remove from build phase
    target.resources_build_phase.files.delete_if do |build_file|
      build_file.file_ref == file
    end
    file.remove_from_project
  end

  # Remove the empty Migrations group
  migrations_group.remove_from_project
  puts "Removed Migrations group"
end

project.save

puts "\nSQL migration files removed from project (they're still on disk)."
puts "These are Supabase migration scripts and don't need to be bundled with the app."
