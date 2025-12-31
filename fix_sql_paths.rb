#!/usr/bin/env ruby
# Script to fix SQL file paths in Xcode project

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Find the TrustLadder Migrations group
trust_ladder_group = project.main_group['Billix']['Features']['TrustLadder']
migrations_group = trust_ladder_group['Migrations']

if migrations_group
  # Remove existing files
  migrations_group.files.each do |file|
    puts "Removing #{file.name} (path: #{file.path})"
    # Remove from build phase
    target.resources_build_phase.files.each do |build_file|
      if build_file.file_ref == file
        target.resources_build_phase.files.delete(build_file)
      end
    end
    file.remove_from_project
  end

  # Remove the group and recreate
  migrations_group.remove_from_project
end

# Create new group with correct path
migrations_group = trust_ladder_group.new_group('Migrations')

# Add SQL files with correct relative paths
sql_files = [
  { name: 'assist_tables.sql', path: 'Billix/Features/TrustLadder/Migrations/assist_tables.sql' },
  { name: 'phase4_multi_party_swaps.sql', path: 'Billix/Features/TrustLadder/Migrations/phase4_multi_party_swaps.sql' }
]

sql_files.each do |sql|
  if File.exist?(sql[:path])
    file_ref = migrations_group.new_reference(sql[:path])
    file_ref.name = sql[:name]
    target.resources_build_phase.add_file_reference(file_ref)
    puts "Added #{sql[:name]} with path #{sql[:path]}"
  else
    puts "Warning: #{sql[:path]} not found"
  end
end

project.save

puts "\nProject updated successfully!"
