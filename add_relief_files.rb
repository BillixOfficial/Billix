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

# Create Relief group if it doesn't exist
relief_group = features_group.find_subpath('Relief', false)
if relief_group.nil?
  relief_group = features_group.new_group('Relief', 'Relief')
  relief_group.source_tree = '<group>'
  puts "Created Relief group"
else
  puts "Relief group already exists"
end

# Create subgroups
subgroups = {
  'Models' => [
    'ReliefEnums.swift',
    'ReliefRequest.swift'
  ],
  'Services' => [
    'ReliefService.swift'
  ],
  'ViewModels' => [
    'ReliefFlowViewModel.swift'
  ],
  'Views' => [
    'ReliefFlowView.swift',
    'ReliefSuccessView.swift',
    'ReliefHistoryView.swift',
    'ReliefDetailView.swift'
  ],
  'Views/Steps' => [
    'ReliefStep1PersonalInfo.swift',
    'ReliefStep2BillInfo.swift',
    'ReliefStep3Situation.swift',
    'ReliefStep4Urgency.swift',
    'ReliefStep5Review.swift'
  ]
}

base_path = 'Billix/Features/Relief'

subgroups.each do |group_path, file_names|
  # Handle nested paths like 'Views/Steps'
  parts = group_path.split('/')
  current_group = relief_group

  parts.each do |part|
    sub = current_group.find_subpath(part, false)
    if sub.nil?
      sub = current_group.new_group(part, part)
      sub.source_tree = '<group>'
      puts "Created subgroup: #{part}"
    end
    current_group = sub
  end

  file_names.each do |file_name|
    # Construct the actual file path
    full_path = "#{base_path}/#{group_path}/#{file_name}"

    # Check if file exists
    unless File.exist?(full_path)
      puts "  WARNING: File #{full_path} does not exist on disk"
    end

    # Check if file reference already exists
    existing = current_group.files.find { |f| f.path == file_name }
    if existing
      puts "  File #{file_name} already exists in group"
      next
    end

    # Create file reference
    file_ref = current_group.new_file(file_name)
    file_ref.source_tree = '<group>'

    # Add to target's compile sources
    target.source_build_phase.add_file_reference(file_ref)

    puts "  Added #{file_name}"
  end
end

project.save
puts "\nProject saved successfully!"
puts "You may need to restart Xcode to see the changes."
