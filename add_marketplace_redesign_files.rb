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

# Helper to add file to project and target
def add_file_to_group(group, filename, target)
  existing = group.files.find { |f| f.path == filename }
  if existing
    puts "Skipping: #{filename} (already exists)"
    return existing
  end

  file_ref = group.new_reference(filename)
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added: #{filename}"
  file_ref
end

# Helper to create group if it doesn't exist
def find_or_create_group(parent, name, path = nil)
  existing = parent.find_subpath(name, false)
  return existing if existing

  new_group = parent.new_group(name)
  new_group.path = path || name
  new_group.source_tree = '<group>'
  puts "Created group: #{name}"
  new_group
end

# Find/create Components group
components_group = find_or_create_group(marketplace_group, 'Components')

# Find/create Cards subgroup
cards_group = find_or_create_group(components_group, 'Cards')

# Find/create Sheets subgroup
sheets_group = find_or_create_group(components_group, 'Sheets')

# Find/create Services group
services_group = find_or_create_group(marketplace_group, 'Services')

# Add new card files
puts "\nAdding new card components..."
add_file_to_group(cards_group, 'ProviderAggregateCard.swift', target)
add_file_to_group(cards_group, 'FeaturedDealCard.swift', target)
add_file_to_group(cards_group, 'SignalCard.swift', target)

# Add ActivityIndicators to Components
puts "\nAdding activity indicators..."
add_file_to_group(components_group, 'ActivityIndicators.swift', target)

# Add new sheet files
puts "\nAdding new sheet components..."
add_file_to_group(sheets_group, 'ClusterSheets.swift', target)
add_file_to_group(sheets_group, 'ShareDealSheet.swift', target)

# Add new service files (if not already added)
puts "\nAdding new services..."
add_file_to_group(services_group, 'MarketplaceDealsService.swift', target)
add_file_to_group(services_group, 'MarketplaceClustersService.swift', target)
add_file_to_group(services_group, 'MarketplaceSignalsService.swift', target)

# Save the project
project.save

puts "\n✅ Successfully added Marketplace redesign files to Xcode project!"
puts "\nNew files added:"
puts "  - Cards: ProviderAggregateCard, FeaturedDealCard, SignalCard"
puts "  - Components: ActivityIndicators"
puts "  - Sheets: ClusterSheets, ShareDealSheet"
puts "  - Services: MarketplaceDealsService, MarketplaceClustersService, MarketplaceSignalsService"
