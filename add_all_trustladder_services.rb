#!/usr/bin/env ruby
# Script to add all TrustLadder services to Xcode project

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Find the TrustLadder Services group
trust_ladder_group = project.main_group['Billix']['Features']['TrustLadder']
services_group = trust_ladder_group['Services']

# Get all .swift files in the services directory
services_dir = 'Billix/Features/TrustLadder/Services'
swift_files = Dir.glob("#{services_dir}/*.swift").map { |f| File.basename(f) }

# Get already added files
existing_files = services_group.files.map(&:name).compact

puts "Files in directory: #{swift_files.count}"
puts "Files in project: #{existing_files.count}"
puts ""

swift_files.each do |filename|
  if existing_files.include?(filename)
    puts "#{filename} - already in project"
  else
    file_ref = services_group.new_reference("#{services_dir}/#{filename}")
    file_ref.name = filename
    target.source_build_phase.add_file_reference(file_ref)
    puts "#{filename} - ADDED"
  end
end

project.save
puts "\nProject saved."
