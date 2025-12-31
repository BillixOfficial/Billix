#!/usr/bin/env ruby
# Fix Assist group path

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Find the TrustLadder group
trust_ladder_group = project.main_group['Billix']['Features']['TrustLadder']
views_group = trust_ladder_group['Views']
assist_group = views_group['Assist']

if assist_group
  # Remove existing files
  puts "Removing existing Assist view files..."
  assist_group.files.each do |file|
    target.source_build_phase.files.delete_if { |bf| bf.file_ref == file }
    file.remove_from_project
  end
  assist_group.remove_from_project
end

# Create Assist group with proper path
assist_group = views_group.new_group('Assist', 'Assist')
assist_group.source_tree = '<group>'

# Add files with just the filename (relative to group path)
assist_files = [
  'AssistFeedView.swift',
  'AssistNegotiationView.swift',
  'AssistRequestCard.swift',
  'CreateAssistRequestView.swift'
]

puts "\nAdding Assist view files..."
assist_files.each do |filename|
  file_ref = assist_group.new_reference(filename)
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "  Added: #{filename}"
end

project.save
puts "\nProject saved."
