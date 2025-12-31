#!/usr/bin/env ruby
# Script to add missing service files to Xcode project

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Find the TrustLadder Services group
trust_ladder_group = project.main_group['Billix']['Features']['TrustLadder']
services_group = trust_ladder_group['Services']

# Files to add to Services
service_files = [
  'AssistMessagingService.swift',
  'AssistRequestService.swift',
  'AssistStoreKitService.swift'
]

# Check existing files
existing_files = services_group.files.map { |f| f.name }.compact

service_files.each do |filename|
  if existing_files.include?(filename)
    puts "#{filename} already exists, skipping..."
    next
  end

  file_path = "Billix/Features/TrustLadder/Services/#{filename}"
  if File.exist?(file_path)
    file_ref = services_group.new_file(file_path)
    target.source_build_phase.add_file_reference(file_ref)
    puts "Added #{filename}"
  else
    puts "Warning: #{filename} not found at #{file_path}"
  end
end

# Find or create Assist views group
views_group = trust_ladder_group['Views']
assist_group = views_group['Assist']

unless assist_group
  assist_group = views_group.new_group('Assist', 'Billix/Features/TrustLadder/Views/Assist')
  puts "Created Assist group"
end

# Assist view files
assist_view_files = [
  'AssistFeedView.swift',
  'AssistNegotiationView.swift',
  'AssistRequestCard.swift',
  'CreateAssistRequestView.swift'
]

existing_assist_files = assist_group.files.map { |f| f.name }.compact

assist_view_files.each do |filename|
  if existing_assist_files.include?(filename)
    puts "#{filename} already exists, skipping..."
    next
  end

  file_path = "Billix/Features/TrustLadder/Views/Assist/#{filename}"
  if File.exist?(file_path)
    file_ref = assist_group.new_file(file_path)
    target.source_build_phase.add_file_reference(file_ref)
    puts "Added #{filename}"
  else
    puts "Warning: #{filename} not found at #{file_path}"
  end
end

# Find or create Migrations group
migrations_group = trust_ladder_group['Migrations']

unless migrations_group
  migrations_group = trust_ladder_group.new_group('Migrations', 'Billix/Features/TrustLadder/Migrations')
  puts "Created Migrations group"
end

# Migration files (add as resources, not sources)
migration_files = [
  'assist_tables.sql',
  'phase4_multi_party_swaps.sql'
]

existing_migration_files = migrations_group.files.map { |f| f.name }.compact

migration_files.each do |filename|
  if existing_migration_files.include?(filename)
    puts "#{filename} already exists, skipping..."
    next
  end

  file_path = "Billix/Features/TrustLadder/Migrations/#{filename}"
  if File.exist?(file_path)
    file_ref = migrations_group.new_file(file_path)
    # Add SQL files to resources
    target.resources_build_phase.add_file_reference(file_ref)
    puts "Added #{filename} to resources"
  else
    puts "Warning: #{filename} not found at #{file_path}"
  end
end

# Find or create Models group
models_group = trust_ladder_group['Models']

# Add AssistRequestModels.swift
assist_models_file = 'AssistRequestModels.swift'
existing_model_files = models_group.files.map { |f| f.name }.compact

unless existing_model_files.include?(assist_models_file)
  file_path = "Billix/Features/TrustLadder/Models/#{assist_models_file}"
  if File.exist?(file_path)
    file_ref = models_group.new_file(file_path)
    target.source_build_phase.add_file_reference(file_ref)
    puts "Added #{assist_models_file}"
  else
    puts "Warning: #{assist_models_file} not found at #{file_path}"
  end
else
  puts "#{assist_models_file} already exists, skipping..."
end

project.save

puts "\nProject updated successfully!"
puts "Please open Xcode and build the project to verify."
