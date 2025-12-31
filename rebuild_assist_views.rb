#!/usr/bin/env ruby
# Complete rebuild of Assist Views and Models references

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Find the TrustLadder group
trust_ladder_group = project.main_group['Billix']['Features']['TrustLadder']

# --- Fix Assist Views ---
views_group = trust_ladder_group['Views']
assist_group = views_group['Assist']

if assist_group
  puts "Removing existing Assist view files..."
  assist_group.files.each do |file|
    puts "  Removing: #{file.name} (#{file.path})"
    target.source_build_phase.files.delete_if { |bf| bf.file_ref == file }
    file.remove_from_project
  end
  assist_group.remove_from_project
end

# Create new Assist group
assist_group = views_group.new_group('Assist')

# Add Assist views with correct paths
assist_dir = 'Billix/Features/TrustLadder/Views/Assist'
if Dir.exist?(assist_dir)
  swift_files = Dir.glob("#{assist_dir}/*.swift").sort

  puts "\nAdding #{swift_files.count} Assist view files..."
  swift_files.each do |full_path|
    filename = File.basename(full_path)
    file_ref = assist_group.new_reference(filename)
    file_ref.source_tree = '<group>'
    target.source_build_phase.add_file_reference(file_ref)
    puts "  Added: #{filename}"
  end
else
  puts "Assist directory not found: #{assist_dir}"
end

# --- Fix AssistRequestModels ---
models_group = trust_ladder_group['Models']

# Remove AssistRequestModels if it exists with bad path
models_group.files.each do |file|
  if file.name == 'AssistRequestModels.swift' || file.path.to_s.include?('AssistRequestModels')
    puts "\nRemoving AssistRequestModels: #{file.path}"
    target.source_build_phase.files.delete_if { |bf| bf.file_ref == file }
    file.remove_from_project
  end
end

# Add AssistRequestModels with correct path
models_file = 'Billix/Features/TrustLadder/Models/AssistRequestModels.swift'
if File.exist?(models_file)
  file_ref = models_group.new_reference('AssistRequestModels.swift')
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "\nAdded: AssistRequestModels.swift"
end

project.save
puts "\nDone! Project saved."
