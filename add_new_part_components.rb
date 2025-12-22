require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Find the Components group
rewards_group = project.main_group.find_subpath('Billix/Features/Rewards', true)
views_group = rewards_group.find_subpath('Views', true)
seasons_group = views_group.find_subpath('Seasons', true)
components_group = seasons_group.find_subpath('Components', true)

# Add the new files
files_to_add = [
  'Billix/Features/Rewards/Views/Seasons/Components/PartProgressRing.swift',
  'Billix/Features/Rewards/Views/Seasons/Components/ProgressPathConnector.swift'
]

files_to_add.each do |file_path|
  file_name = File.basename(file_path)

  # Check if file already exists in group
  existing_file = components_group.files.find { |f| f.display_name == file_name }

  unless existing_file
    # Add file to group
    file_ref = components_group.new_file(file_path)

    # Add to build phase
    target.source_build_phase.add_file_reference(file_ref)

    puts "Added #{file_name}"
  else
    puts "#{file_name} already exists in project"
  end
end

# Save the project
project.save

puts "Done! New components added to Xcode project."
