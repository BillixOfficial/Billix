#!/usr/bin/env ruby
# Fix Xcode project build phases

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Files that need to be added to compile sources
files_to_add = [
  'Billix/Services/StreakService.swift',
  'Billix/Services/WeatherService.swift',
  'Billix/Services/OpenAIService.swift',
  'Billix/Features/TrustLadder/Models/BillixScoreModels.swift',
  'Billix/Features/TrustLadder/Models/SubscriptionModels.swift',
  'Billix/Features/TrustLadder/Services/BillixScoreService.swift',
  'Billix/Features/TrustLadder/Services/SubscriptionService.swift',
  'Billix/Features/TrustLadder/Services/UnlockCreditsService.swift',
  'Billix/Features/Rewards/Views/Components/CustomDonationCard.swift',
  'Billix/Features/Rewards/Views/Components/CustomDonationRequestSheet.swift',
  'Billix/Features/Rewards/Views/Components/DonationImpactCard.swift',
  'Billix/Features/Rewards/Views/Components/DonationSheet.swift',
  'Billix/Features/Rewards/Models/DonationModels.swift',
  'Billix/Features/Home/HomeSetupQuestionsView.swift',
  'Billix/Features/Home/QuickActionViews.swift',
]

# Remove Swift files from Resources phase
resources_phase = target.resources_build_phase
files_to_remove = []

resources_phase.files.each do |build_file|
  if build_file.file_ref && build_file.file_ref.path && build_file.file_ref.path.end_with?('.swift')
    puts "Removing from Resources: #{build_file.file_ref.path}"
    files_to_remove << build_file
  end
end

files_to_remove.each { |f| resources_phase.remove_build_file(f) }

# Remove Swift files from Frameworks phase (shouldn't be there either)
frameworks_phase = target.frameworks_build_phase
files_to_remove = []

frameworks_phase.files.each do |build_file|
  if build_file.file_ref && build_file.file_ref.path && build_file.file_ref.path.end_with?('.swift')
    puts "Removing from Frameworks: #{build_file.file_ref.path}"
    files_to_remove << build_file
  end
end

files_to_remove.each { |f| frameworks_phase.remove_build_file(f) }

# Add missing files to project and compile sources
files_to_add.each do |file_path|
  full_path = File.join(Dir.pwd, file_path)

  if File.exist?(full_path)
    # Check if file is already in project
    existing = project.files.find { |f| f.path == file_path || f.real_path.to_s == full_path }

    if existing
      # Check if it's in compile sources
      in_sources = target.source_build_phase.files.any? { |bf| bf.file_ref == existing }
      unless in_sources
        puts "Adding to Sources: #{file_path}"
        target.source_build_phase.add_file_reference(existing)
      end
    else
      # Add file to project
      puts "Adding file to project: #{file_path}"

      # Find or create the group
      path_components = file_path.split('/')
      group = project.main_group

      path_components[0..-2].each do |component|
        child = group.children.find { |c| c.display_name == component }
        if child && child.is_a?(Xcodeproj::Project::Object::PBXGroup)
          group = child
        else
          group = group.new_group(component)
        end
      end

      file_ref = group.new_file(full_path)
      target.source_build_phase.add_file_reference(file_ref)
    end
  else
    puts "File not found: #{file_path}"
  end
end

project.save
puts "Project saved successfully!"
