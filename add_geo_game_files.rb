#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find the Rewards group
rewards_group = project.main_group.find_subpath('Billix/Features/Rewards', true)

# Add Models
models_group = rewards_group['Models'] || rewards_group.new_group('Models')
geo_models = models_group.new_file('Billix/Features/Rewards/Models/GeoGameModels.swift')
target.add_file_references([geo_models])

# Add ViewModels
viewmodels_group = rewards_group['ViewModels'] || rewards_group.new_group('ViewModels')
geo_viewmodel = viewmodels_group.new_file('Billix/Features/Rewards/ViewModels/GeoGameViewModel.swift')
target.add_file_references([geo_viewmodel])

# Add Services
services_group = rewards_group['Services'] || rewards_group.new_group('Services')
geo_service = services_group.new_file('Billix/Features/Rewards/Services/GeoGameDataService.swift')
target.add_file_references([geo_service])

# Add Views/GeoGame folder
views_group = rewards_group['Views'] || rewards_group.new_group('Views')
geogame_group = views_group['GeoGame'] || views_group.new_group('GeoGame')

# Add all GeoGame view files
geogame_files = [
  'Billix/Features/Rewards/Views/GeoGame/GeoGameContainerView.swift',
  'Billix/Features/Rewards/Views/GeoGame/GeoGameMapView.swift',
  'Billix/Features/Rewards/Views/GeoGame/GeoGameFloatingCard.swift',
  'Billix/Features/Rewards/Views/GeoGame/Phase1LocationView.swift',
  'Billix/Features/Rewards/Views/GeoGame/Phase2PriceView.swift',
  'Billix/Features/Rewards/Views/GeoGame/GeoGameResultView.swift'
]

geogame_files.each do |file_path|
  file_ref = geogame_group.new_file(file_path)
  target.add_file_references([file_ref])
end

# Save the project
project.save

puts "Successfully added Geo Game files to Xcode project!"
