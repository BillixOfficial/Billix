#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }

# Read all missing files
files = File.readlines('/tmp/rewards_files.txt').map(&:strip)

added_count = 0
skipped_count = 0

files.each do |file_path|
  existing_file = project.files.find { |f| f.path == file_path }

  if existing_file
    skipped_count += 1
  else
    if File.exist?(file_path)
      file_ref = project.new_file(file_path)
      target.add_file_references([file_ref])
      added_count += 1
    end
  end
end

project.save

puts "✅ Added #{added_count} files, skipped #{skipped_count} existing"
