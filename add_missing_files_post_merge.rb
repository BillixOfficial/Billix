#!/usr/bin/env ruby
# Add all missing files from main merge to Xcode project

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }

def add_files_to_group(group, dir_path, target, group_name)
  return unless Dir.exist?(dir_path)

  added_count = 0
  Dir.glob("#{dir_path}/*.swift").each do |file|
    filename = File.basename(file)
    # Check if already in project
    unless group.files.any? { |f| f.name == filename || f.path == filename }
      file_ref = group.new_reference(filename)
      file_ref.source_tree = '<group>'
      target.source_build_phase.add_file_reference(file_ref)
      puts "✓ Added to #{group_name}: #{filename}"
      added_count += 1
    end
  end
  added_count
end

def ensure_group(parent_group, group_name, path = nil)
  group = parent_group[group_name]
  if group.nil?
    group = parent_group.new_group(group_name, path || group_name)
    puts "  Created group: #{group_name}"
  end
  group
end

total_added = 0

# HOME FEATURE
puts "\n=== HOME FEATURE ==="
home_group = project.main_group['Billix']['Features']['Home']
if home_group
  # Add HomeViewModel.swift and QuickTasksScreen.swift to Home root
  ['HomeViewModel.swift', 'QuickTasksScreen.swift'].each do |filename|
    file_path = "Billix/Features/Home/#{filename}"
    if File.exist?(file_path) && !home_group.files.any? { |f| f.name == filename }
      file_ref = home_group.new_reference(filename)
      file_ref.source_tree = '<group>'
      target.source_build_phase.add_file_reference(file_ref)
      puts "✓ Added to Home: #{filename}"
      total_added += 1
    end
  end

  # Home/Services
  services_group = ensure_group(home_group, 'Services')
  total_added += add_files_to_group(services_group, 'Billix/Features/Home/Services', target, 'Home/Services')

  # Home/Components
  components_group = home_group['Components']
  if components_group
    total_added += add_files_to_group(components_group, 'Billix/Features/Home/Components', target, 'Home/Components')
  end
end

# TRUSTLADDER FEATURE
puts "\n=== TRUSTLADDER FEATURE ==="
trustladder_group = project.main_group['Billix']['Features']['TrustLadder']
if trustladder_group
  views_group = trustladder_group['Views']
  if views_group
    # Assist subgroup
    assist_group = ensure_group(views_group, 'Assist')
    total_added += add_files_to_group(assist_group, 'Billix/Features/TrustLadder/Views/Assist', target, 'TrustLadder/Views/Assist')

    # Engagement subgroup
    engagement_group = ensure_group(views_group, 'Engagement')
    total_added += add_files_to_group(engagement_group, 'Billix/Features/TrustLadder/Views/Engagement', target, 'TrustLadder/Views/Engagement')

    # Legal subgroup
    legal_group = ensure_group(views_group, 'Legal')
    total_added += add_files_to_group(legal_group, 'Billix/Features/TrustLadder/Views/Legal', target, 'TrustLadder/Views/Legal')

    # Subscription subgroup
    subscription_group = ensure_group(views_group, 'Subscription')
    total_added += add_files_to_group(subscription_group, 'Billix/Features/TrustLadder/Views/Subscription', target, 'TrustLadder/Views/Subscription')

    # Swaps subgroup
    swaps_group = ensure_group(views_group, 'Swaps')
    total_added += add_files_to_group(swaps_group, 'Billix/Features/TrustLadder/Views/Swaps', target, 'TrustLadder/Views/Swaps')

    # Trust subgroup
    trust_group = ensure_group(views_group, 'Trust')
    total_added += add_files_to_group(trust_group, 'Billix/Features/TrustLadder/Views/Trust', target, 'TrustLadder/Views/Trust')
  end

  # TrustLadder Services
  services_group = trustladder_group['Services']
  if services_group
    total_added += add_files_to_group(services_group, 'Billix/Features/TrustLadder/Services', target, 'TrustLadder/Services')
  end

  # TrustLadder Models
  models_group = trustladder_group['Models']
  if models_group
    total_added += add_files_to_group(models_group, 'Billix/Features/TrustLadder/Models', target, 'TrustLadder/Models')
  end
end

# MARKETPLACE FEATURE
puts "\n=== MARKETPLACE FEATURE ==="
marketplace_group = project.main_group['Billix']['Features']['Marketplace']
if marketplace_group
  components_group = marketplace_group['Components']
  if components_group
    # Cards subgroup
    cards_group = ensure_group(components_group, 'Cards')
    total_added += add_files_to_group(cards_group, 'Billix/Features/Marketplace/Components/Cards', target, 'Marketplace/Components/Cards')

    # Sheets subgroup
    sheets_group = ensure_group(components_group, 'Sheets')
    total_added += add_files_to_group(sheets_group, 'Billix/Features/Marketplace/Components/Sheets', target, 'Marketplace/Components/Sheets')
  end
end

# EXPLORE FEATURE
puts "\n=== EXPLORE FEATURE ==="
explore_group = project.main_group['Billix']['Features']['Explore']
if explore_group
  # Explore/Components
  components_group = explore_group['Components']
  if components_group
    total_added += add_files_to_group(components_group, 'Billix/Features/Explore/Components', target, 'Explore/Components')
  end

  # Explore/Services
  services_group = ensure_group(explore_group, 'Services')
  total_added += add_files_to_group(services_group, 'Billix/Features/Explore/Services', target, 'Explore/Services')
end

# CORE & UTILITIES
puts "\n=== CORE & UTILITIES ==="

# Core/Extensions
core_group = project.main_group['Billix']['Core']
if core_group
  extensions_group = core_group['Extensions']
  if extensions_group
    total_added += add_files_to_group(extensions_group, 'Billix/Core/Extensions', target, 'Core/Extensions')
  end
end

# Models (top level)
models_group = project.main_group['Billix']['Models']
if models_group
  total_added += add_files_to_group(models_group, 'Billix/Models', target, 'Models')
end

# Utilities
utilities_group = project.main_group['Billix']['Utilities']
if utilities_group
  # Utilities root files
  total_added += add_files_to_group(utilities_group, 'Billix/Utilities', target, 'Utilities')

  # Utilities/Components
  components_group = utilities_group['Components']
  if components_group
    total_added += add_files_to_group(components_group, 'Billix/Utilities/Components', target, 'Utilities/Components')
  end
end

# Save the project
project.save

puts "\n" + "="*50
puts "✅ COMPLETE: Added #{total_added} files to Xcode project"
puts "="*50
puts "\nNext steps:"
puts "1. Open Billix.xcodeproj in Xcode"
puts "2. Clean Build Folder (Cmd+Shift+K)"
puts "3. Build the project (Cmd+B)"
