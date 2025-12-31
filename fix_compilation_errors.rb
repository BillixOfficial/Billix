#!/usr/bin/env ruby
# Fix compilation errors by adding all missing Swift files to Xcode project

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

def add_files_to_group(group, dir_path, target)
  return unless group && Dir.exist?(dir_path)

  Dir.glob("#{dir_path}/*.swift").each do |file|
    filename = File.basename(file)
    # Check if already in project
    unless group.files.any? { |f| f.name == filename || f.path == filename }
      file_ref = group.new_reference(filename)
      file_ref.source_tree = '<group>'
      target.source_build_phase.add_file_reference(file_ref)
      puts "Added: #{file}"
    end
  end
end

def get_or_create_group(parent, name)
  existing = parent[name]
  return existing if existing
  parent.new_group(name, name)
end

puts "=== Adding Missing Files to Xcode Project ==="
puts ""

# 1. Add Services (OpenAIService, WeatherService, StreakService)
puts "--- Services ---"
services_group = project.main_group['Billix']['Services']
if services_group
  add_files_to_group(services_group, 'Billix/Services', target)
end

# 2. Add TrustLadder Models (BillixScoreModels, SubscriptionModels)
puts "\n--- TrustLadder Models ---"
trustladder_group = project.main_group['Billix']['Features']['TrustLadder']
if trustladder_group
  models_group = get_or_create_group(trustladder_group, 'Models')
  add_files_to_group(models_group, 'Billix/Features/TrustLadder/Models', target)
end

# 3. Add TrustLadder Services (BillixScoreService, SubscriptionService)
puts "\n--- TrustLadder Services ---"
if trustladder_group
  services_group = get_or_create_group(trustladder_group, 'Services')
  add_files_to_group(services_group, 'Billix/Features/TrustLadder/Services', target)
end

# 4. Add Marketplace Services (MarketplaceClustersService, MarketplaceSignalsService)
puts "\n--- Marketplace Services ---"
marketplace_group = project.main_group['Billix']['Features']['Marketplace']
if marketplace_group
  services_group = get_or_create_group(marketplace_group, 'Services')
  add_files_to_group(services_group, 'Billix/Features/Marketplace/Services', target)
end

# 5. Add Marketplace Components
puts "\n--- Marketplace Components ---"
if marketplace_group
  # Cards
  components_group = get_or_create_group(marketplace_group, 'Components')
  cards_group = get_or_create_group(components_group, 'Cards')
  add_files_to_group(cards_group, 'Billix/Features/Marketplace/Components/Cards', target)

  # Sheets
  sheets_group = get_or_create_group(components_group, 'Sheets')
  add_files_to_group(sheets_group, 'Billix/Features/Marketplace/Components/Sheets', target)

  # Activity Indicators
  add_files_to_group(components_group, 'Billix/Features/Marketplace/Components', target)
end

# 6. Add Explore ViewModels (OutageBotViewModel)
puts "\n--- Explore ViewModels ---"
explore_group = project.main_group['Billix']['Features']['Explore']
if explore_group
  vms_group = get_or_create_group(explore_group, 'ViewModels')
  add_files_to_group(vms_group, 'Billix/Features/Explore/ViewModels', target)
end

# 7. Add Explore Models (OutageBotModels, SimulationModels, ExploreCarouselModels)
puts "\n--- Explore Models ---"
if explore_group
  models_group = get_or_create_group(explore_group, 'Models')
  add_files_to_group(models_group, 'Billix/Features/Explore/Models', target)
end

# 8. Add Explore Services (OutageDetectionService, OutageDataService, etc.)
puts "\n--- Explore Services ---"
if explore_group
  services_group = get_or_create_group(explore_group, 'Services')
  add_files_to_group(services_group, 'Billix/Features/Explore/Services', target)
end

# 9. Add Explore Components
puts "\n--- Explore Components ---"
if explore_group
  components_group = get_or_create_group(explore_group, 'Components')
  add_files_to_group(components_group, 'Billix/Features/Explore/Components', target)
end

# 10. Add Explore Views
puts "\n--- Explore Views ---"
if explore_group
  views_group = get_or_create_group(explore_group, 'Views')
  add_files_to_group(views_group, 'Billix/Features/Explore/Views', target)
end

# 11. Add Home Components
puts "\n--- Home Components ---"
home_group = project.main_group['Billix']['Features']['Home']
if home_group
  components_group = get_or_create_group(home_group, 'Components')
  add_files_to_group(components_group, 'Billix/Features/Home/Components', target)

  services_group = get_or_create_group(home_group, 'Services')
  add_files_to_group(services_group, 'Billix/Features/Home/Services', target)
end

# 12. Add Models (HomeAlert, BillHealthScore, RecentActivity, SavingsOpportunity)
puts "\n--- Models ---"
models_group = project.main_group['Billix']['Models']
if models_group
  add_files_to_group(models_group, 'Billix/Models', target)
end

# 13. Add Utilities (CustomStyles, etc.)
puts "\n--- Utilities ---"
utilities_group = project.main_group['Billix']['Utilities']
if utilities_group
  add_files_to_group(utilities_group, 'Billix/Utilities', target)
end

project.save
puts "\n=== Project Saved Successfully ==="
puts "Please rebuild the project in Xcode."
