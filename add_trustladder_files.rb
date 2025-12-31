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

# Helper to add file to project and target
def add_file_to_group(group, filename, target)
  file_ref = group.new_reference(filename)
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added: #{filename}"
  file_ref
end

# Create TrustLadder group structure
trustladder_group = create_group_with_path(features_group, 'TrustLadder')

# Models group
models_group = create_group_with_path(trustladder_group, 'Models')
add_file_to_group(models_group, 'TrustLadderEnums.swift', target)
add_file_to_group(models_group, 'TrustLadderModels.swift', target)

# Services group
services_group = create_group_with_path(trustladder_group, 'Services')
add_file_to_group(services_group, 'TrustLadderService.swift', target)
add_file_to_group(services_group, 'BillPortfolioService.swift', target)
add_file_to_group(services_group, 'SwapMatchingService.swift', target)
add_file_to_group(services_group, 'SwapExecutionService.swift', target)
add_file_to_group(services_group, 'ScreenshotVerificationService.swift', target)
add_file_to_group(services_group, 'SwapStoreKitService.swift', target)

# ViewModels group
viewmodels_group = create_group_with_path(trustladder_group, 'ViewModels')
add_file_to_group(viewmodels_group, 'PortfolioSetupViewModel.swift', target)
add_file_to_group(viewmodels_group, 'SwapHubViewModel.swift', target)

# Views group
views_group = create_group_with_path(trustladder_group, 'Views')
add_file_to_group(views_group, 'PortfolioSetupView.swift', target)
add_file_to_group(views_group, 'SwapHubView.swift', target)
add_file_to_group(views_group, 'SwapExecutionView.swift', target)
add_file_to_group(views_group, 'FindMatchView.swift', target)

# Components group
components_group = create_group_with_path(views_group, 'Components')
add_file_to_group(components_group, 'SwapHubEntryCard.swift', target)

# Save the project
project.save

puts "\n✅ Successfully added TrustLadder files to Xcode project!"
