#!/usr/bin/env ruby
# Add only Bill Assist files to Xcode project

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }

# Bill Assist specific files
bill_assist_files = [
  'Billix/Features/TrustLadder/Models/AssistRequestModels.swift',
  'Billix/Features/TrustLadder/Services/AssistRequestService.swift',
  'Billix/Features/TrustLadder/Services/AssistMessagingService.swift',
  'Billix/Features/TrustLadder/Services/AssistStoreKitService.swift',
  'Billix/Features/TrustLadder/Views/Assist/AssistFeedView.swift',
  'Billix/Features/TrustLadder/Views/Assist/AssistRequestCard.swift',
  'Billix/Features/TrustLadder/Views/Assist/CreateAssistRequestView.swift',
  'Billix/Features/TrustLadder/Views/Assist/AssistNegotiationView.swift'
]

# Get existing file paths
existing_files = Set.new
target.source_build_phase.files.each do |bf|
  ref = bf.file_ref
  next unless ref
  name = ref.name || File.basename(ref.path.to_s)
  existing_files.add(name)
end

# Helper to find group by path
def find_group(project, path_parts)
  current = project.main_group
  path_parts.each do |part|
    found = current.groups.find { |g| g.name == part || g.path == part }
    return nil unless found
    current = found
  end
  current
end

added = 0
bill_assist_files.each do |file_path|
  filename = File.basename(file_path)

  # Skip if already in project
  if existing_files.include?(filename)
    puts "Already exists: #{filename}"
    next
  end

  # Parse path to find parent group
  parts = file_path.split('/')
  parts.pop  # Remove filename

  # Find or create the Assist group for views
  group = find_group(project, parts)

  if group.nil?
    # Create the Assist group if needed
    parent_parts = parts[0...-1]
    parent = find_group(project, parent_parts)
    if parent
      group = parent.new_group(parts.last, parts.last)
      puts "Created group: #{parts.last}"
    else
      puts "Cannot find parent group for: #{file_path}"
      next
    end
  end

  # Add file reference
  file_ref = group.new_reference(filename)
  file_ref.source_tree = '<group>'
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added: #{filename}"
  added += 1
end

project.save
puts "\nAdded #{added} Bill Assist files to project."
