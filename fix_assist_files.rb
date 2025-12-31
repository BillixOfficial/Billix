#!/usr/bin/env ruby
# Script to fix all Bill Assist file paths in Xcode project

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Helper to remove file from all build phases
def remove_file_from_project(file, target)
  return unless file

  target.source_build_phase.files.delete_if { |bf| bf.file_ref == file }
  target.resources_build_phase.files.delete_if { |bf| bf.file_ref == file }
  file.remove_from_project
end

# Find the TrustLadder group
trust_ladder_group = project.main_group['Billix']['Features']['TrustLadder']

# Clean up Services group
services_group = trust_ladder_group['Services']
if services_group
  files_to_remove = []
  services_group.files.each do |file|
    if ['AssistMessagingService.swift', 'AssistRequestService.swift', 'AssistStoreKitService.swift'].include?(file.name)
      puts "Removing bad path for #{file.name}: #{file.path}"
      files_to_remove << file
    end
  end
  files_to_remove.each { |f| remove_file_from_project(f, target) }
end

# Clean up Views/Assist group
views_group = trust_ladder_group['Views']
if views_group
  assist_group = views_group['Assist']
  if assist_group
    puts "Removing Assist group entirely"
    assist_group.files.each { |f| remove_file_from_project(f, target) }
    assist_group.groups.each { |g| g.remove_from_project }
    assist_group.remove_from_project
  end
end

# Clean up Models group
models_group = trust_ladder_group['Models']
if models_group
  models_group.files.each do |file|
    if file.name == 'AssistRequestModels.swift'
      puts "Removing bad path for #{file.name}: #{file.path}"
      remove_file_from_project(file, target)
    end
  end
end

project.save
puts "\nCleaned up bad file references."

# Now re-add the files with correct paths
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }
trust_ladder_group = project.main_group['Billix']['Features']['TrustLadder']
services_group = trust_ladder_group['Services']
views_group = trust_ladder_group['Views']
models_group = trust_ladder_group['Models']

# Add Services
service_files = [
  'AssistMessagingService.swift',
  'AssistRequestService.swift',
  'AssistStoreKitService.swift'
]

existing_service_names = services_group.files.map(&:name).compact

service_files.each do |filename|
  next if existing_service_names.include?(filename)

  # Use path relative to project root
  file_ref = services_group.new_file("../Services/#{filename}")
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added #{filename} to Services"
end

# Create Assist group under Views
assist_group = views_group.new_group('Assist')

# Add Assist views
assist_files = [
  'AssistFeedView.swift',
  'AssistNegotiationView.swift',
  'AssistRequestCard.swift',
  'CreateAssistRequestView.swift'
]

assist_files.each do |filename|
  file_ref = assist_group.new_file("../Views/Assist/#{filename}")
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added #{filename} to Views/Assist"
end

# Add AssistRequestModels
file_ref = models_group.new_file("../Models/AssistRequestModels.swift")
target.source_build_phase.add_file_reference(file_ref)
puts "Added AssistRequestModels.swift to Models"

project.save
puts "\nFiles re-added with correct paths."
