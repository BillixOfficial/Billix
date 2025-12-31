#!/usr/bin/env ruby
# Add all missing files to Xcode project

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Billix' }

# Get existing file paths in project
existing_paths = Set.new
target.source_build_phase.files.each do |build_file|
  ref = build_file.file_ref
  next unless ref
  existing_paths.add(ref.real_path.to_s) if ref.respond_to?(:real_path)
end

# Find all Swift files in the project
all_swift_files = Dir.glob('Billix/**/*.swift')

puts "Total Swift files on disk: #{all_swift_files.count}"
puts "Files in project: #{existing_paths.count}"

# Find main Services group and add missing services
services_group = project.main_group['Billix']['Services']
if services_group
  services_dir = 'Billix/Services'
  Dir.glob("#{services_dir}/*.swift").each do |file|
    filename = File.basename(file)
    # Check if already in project
    unless services_group.files.any? { |f| f.name == filename || f.path == filename }
      file_ref = services_group.new_reference(filename)
      file_ref.source_tree = '<group>'
      target.source_build_phase.add_file_reference(file_ref)
      puts "Added to Services: #{filename}"
    end
  end
end

# Find Explore ViewModels and add missing
explore_group = project.main_group['Billix']['Features']['Explore']
if explore_group
  vms_group = explore_group['ViewModels']
  if vms_group
    vms_dir = 'Billix/Features/Explore/ViewModels'
    Dir.glob("#{vms_dir}/*.swift").each do |file|
      filename = File.basename(file)
      unless vms_group.files.any? { |f| f.name == filename || f.path == filename }
        file_ref = vms_group.new_reference(filename)
        file_ref.source_tree = '<group>'
        target.source_build_phase.add_file_reference(file_ref)
        puts "Added to Explore/ViewModels: #{filename}"
      end
    end
  end

  # Add missing models
  models_group = explore_group['Models']
  if models_group
    models_dir = 'Billix/Features/Explore/Models'
    Dir.glob("#{models_dir}/*.swift").each do |file|
      filename = File.basename(file)
      unless models_group.files.any? { |f| f.name == filename || f.path == filename }
        file_ref = models_group.new_reference(filename)
        file_ref.source_tree = '<group>'
        target.source_build_phase.add_file_reference(file_ref)
        puts "Added to Explore/Models: #{filename}"
      end
    end
  end

  # Add missing services
  services_group = explore_group['Services']
  if services_group.nil?
    services_group = explore_group.new_group('Services', 'Services')
  end
  services_dir = 'Billix/Features/Explore/Services'
  if Dir.exist?(services_dir)
    Dir.glob("#{services_dir}/*.swift").each do |file|
      filename = File.basename(file)
      unless services_group.files.any? { |f| f.name == filename || f.path == filename }
        file_ref = services_group.new_reference(filename)
        file_ref.source_tree = '<group>'
        target.source_build_phase.add_file_reference(file_ref)
        puts "Added to Explore/Services: #{filename}"
      end
    end
  end
end

# Add Home Services
home_group = project.main_group['Billix']['Features']['Home']
if home_group
  services_group = home_group['Services']
  if services_group.nil?
    services_group = home_group.new_group('Services', 'Services')
  end
  services_dir = 'Billix/Features/Home/Services'
  if Dir.exist?(services_dir)
    Dir.glob("#{services_dir}/*.swift").each do |file|
      filename = File.basename(file)
      unless services_group.files.any? { |f| f.name == filename || f.path == filename }
        file_ref = services_group.new_reference(filename)
        file_ref.source_tree = '<group>'
        target.source_build_phase.add_file_reference(file_ref)
        puts "Added to Home/Services: #{filename}"
      end
    end
  end
end

project.save
puts "\nProject saved."
