#!/usr/bin/env ruby
require 'xcodeproj'

project_path = '/Users/falana/Desktop/Billix/Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Find the Features group
features_group = project.main_group.find_subpath('Billix/Features', true)

if features_group.nil?
  puts "ERROR: Features group not found"
  exit 1
end

puts "Found Features group"

# Create Store group if it doesn't exist
store_group = features_group.find_subpath('Store', false)
if store_group.nil?
  store_group = features_group.new_group('Store', 'Store')
  store_group.source_tree = '<group>'
  puts "Created Store group"
else
  puts "Store group already exists"
end

# Create Views subgroup
views_group = store_group.find_subpath('Views', false)
if views_group.nil?
  views_group = store_group.new_group('Views', 'Views')
  views_group.source_tree = '<group>'
  puts "Created Views subgroup"
end

# Add BillixStoreView.swift
file_name = 'BillixStoreView.swift'
existing = views_group.files.find { |f| f.path == file_name }
if existing
  puts "File #{file_name} already exists in group"
else
  file_ref = views_group.new_file(file_name)
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added #{file_name}"
end

project.save
puts "\nProject saved successfully!"
puts "You may need to restart Xcode to see the changes."
