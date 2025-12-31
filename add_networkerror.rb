#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }

# Find Core/Extensions group
core_group = project.main_group['Billix']['Core']
if core_group
  network_group = core_group['Network']
  if network_group
    file_ref = network_group.new_reference('NetworkError.swift')
    file_ref.source_tree = '<group>'
    target.source_build_phase.add_file_reference(file_ref)
    puts "Added NetworkError.swift"
  end
end

project.save
puts "Project saved."
