#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Components group
target = project.targets.first
components_group = project.main_group.find_subpath('Billix/Features/Rewards/Views/Components', true)

if components_group.nil?
  puts "Error: Could not find Components group"
  exit 1
end

# Files to add
new_files = [
  'GiftCardHeroSection.swift',
  'VirtualGoodsCarousel.swift',
  'GameBoostsGrid.swift',
  'WeeklyGiveawayCard.swift',
  'GiftCardsModal.swift'
]

# Add each file
new_files.each do |filename|
  file_path = "Billix/Features/Rewards/Views/Components/#{filename}"

  # Check if file already exists in project
  existing = components_group.files.find { |f| f.path == filename }

  if existing
    puts "⚠️  #{filename} already in project"
    next
  end

  # Add file reference
  file_ref = components_group.new_file(file_path)

  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)

  puts "✓ Added #{filename}"
end

# Save the project
project.save

puts "\nSuccessfully updated Xcode project!"
