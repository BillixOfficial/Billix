#!/usr/bin/env ruby
require 'xcodeproj'

# Open the Xcode project
project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Find the Features group under Billix
billix_group = project.main_group.find_subpath('Billix', true)
features_group = billix_group.find_subpath('Features', true)

# Helper to create group with path
def create_group_with_path(parent, name, path = nil)
  group = parent.new_group(name)
  group.path = path || name
  group.source_tree = '<group>'
  group
end

# Helper to add file to project and target (uses just the filename)
def add_file_to_group(group, filename, target)
  file_ref = group.new_reference(filename)
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added: #{filename}"
  file_ref
end

# Create Marketplace group structure
marketplace_group = create_group_with_path(features_group, 'Marketplace')

# Main Marketplace files
add_file_to_group(marketplace_group, 'MarketplaceTheme.swift', target)
add_file_to_group(marketplace_group, 'MarketplaceView.swift', target)

# Models group
models_group = create_group_with_path(marketplace_group, 'Models')
add_file_to_group(models_group, 'BillListing.swift', target)
add_file_to_group(models_group, 'Cluster.swift', target)
add_file_to_group(models_group, 'MarketplaceItems.swift', target)
add_file_to_group(models_group, 'MockMarketplaceData.swift', target)

# ViewModels group
viewmodels_group = create_group_with_path(marketplace_group, 'ViewModels')
add_file_to_group(viewmodels_group, 'MarketplaceViewModel.swift', target)

# Components group
components_group = create_group_with_path(marketplace_group, 'Components')

# Cards group
cards_group = create_group_with_path(components_group, 'Cards')

# BillCard group
billcard_group = create_group_with_path(cards_group, 'BillCard')
add_file_to_group(billcard_group, 'BillCardView.swift', target)
add_file_to_group(billcard_group, 'BillCardSideA.swift', target)
add_file_to_group(billcard_group, 'BillCardSideB.swift', target)
add_file_to_group(billcard_group, 'VSMeToggle.swift', target)

# Zones group
zones_group = create_group_with_path(billcard_group, 'Zones')
add_file_to_group(zones_group, 'TickerHeaderZone.swift', target)
add_file_to_group(zones_group, 'FinancialSpreadZone.swift', target)
add_file_to_group(zones_group, 'DynamicSpecsZone.swift', target)
add_file_to_group(zones_group, 'BlueprintTeaseZone.swift', target)
add_file_to_group(zones_group, 'SellerFooterZone.swift', target)

# Other cards
add_file_to_group(cards_group, 'BountyCard.swift', target)
add_file_to_group(cards_group, 'ClusterCard.swift', target)
add_file_to_group(cards_group, 'PredictionCard.swift', target)
add_file_to_group(cards_group, 'ScriptCard.swift', target)
add_file_to_group(cards_group, 'ServiceCard.swift', target)

# Sheets group
sheets_group = create_group_with_path(components_group, 'Sheets')
add_file_to_group(sheets_group, 'FilterSheetView.swift', target)
add_file_to_group(sheets_group, 'UnlockBlueprintSheet.swift', target)
add_file_to_group(sheets_group, 'AskOwnerSheet.swift', target)
add_file_to_group(sheets_group, 'PlaceBidSheet.swift', target)

# Common group (empty placeholder)
common_group = create_group_with_path(components_group, 'Common')

# Save the project
project.save

puts "\n✅ Successfully added Marketplace files to Xcode project!"
