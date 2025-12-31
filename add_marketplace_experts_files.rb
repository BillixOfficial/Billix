#!/usr/bin/env ruby
require 'xcodeproj'

# Open the Xcode project
project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Find the Marketplace group
billix_group = project.main_group.find_subpath('Billix', true)
features_group = billix_group.find_subpath('Features', true)
marketplace_group = features_group.find_subpath('Marketplace', true)
components_group = marketplace_group.find_subpath('Components', true)
sheets_group = components_group.find_subpath('Sheets', true)

# Helper to create group with path
def create_group_with_path(parent, name, path = nil)
  group = parent.new_group(name)
  group.path = path || name
  group.source_tree = '<group>'
  group
end

# Helper to add file to project and target
def add_file_to_group(group, filename, target)
  file_ref = group.new_reference(filename)
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added: #{filename}"
  file_ref
end

# Create Services group if it doesn't exist
services_group = marketplace_group.find_subpath('Services', false)
if services_group.nil?
  services_group = create_group_with_path(marketplace_group, 'Services')
  puts "Created Services group"
end

# Add new service file
add_file_to_group(services_group, 'MarketplaceExpertsService.swift', target)

# Add new sheet files
add_file_to_group(sheets_group, 'PostBountySheet.swift', target)
add_file_to_group(sheets_group, 'OfferServiceSheet.swift', target)

# Also add TakeoverCard if it's missing
cards_group = components_group.find_subpath('Cards', true)
begin
  add_file_to_group(cards_group, 'TakeoverCard.swift', target)
rescue
  puts "TakeoverCard.swift already exists, skipping"
end

# Save the project
project.save

puts "\n✅ Successfully added new Marketplace Experts files to Xcode project!"
