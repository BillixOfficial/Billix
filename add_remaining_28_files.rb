#!/usr/bin/env ruby
# Add the remaining 28 files that exist on disk but not in Xcode

require 'xcodeproj'

project_path = 'Billix.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Billix' }

def add_files_to_group(group, dir_path, target, group_name)
  return 0 unless Dir.exist?(dir_path)

  added_count = 0
  Dir.glob("#{dir_path}/*.swift").each do |file|
    filename = File.basename(file)
    unless group.files.any? { |f| f.name == filename || f.path == filename }
      file_ref = group.new_reference(filename)
      file_ref.source_tree = '<group>'
      target.source_build_phase.add_file_reference(file_ref)
      puts "✓ Added: #{filename}"
      added_count += 1
    end
  end
  added_count
end

def ensure_group(parent_group, group_name, path = nil)
  group = parent_group[group_name]
  if group.nil?
    group = parent_group.new_group(group_name, path || group_name)
    puts "  Created group: #{group_name}"
  end
  group
end

total_added = 0

# HOME/COMPONENTS (18 files)
puts "=== HOME/COMPONENTS ==="
home_group = project.main_group['Billix']['Features']['Home']
if home_group
  components_group = ensure_group(home_group, 'Components')
  total_added += add_files_to_group(components_group, 'Billix/Features/Home/Components', target, 'Home/Components')
end

# REWARDS SERVICE (critical!)
puts "\n=== REWARDS SERVICE ==="
rewards_group = project.main_group['Billix']['Features']['Rewards']
if rewards_group
  services_group = rewards_group['Services']
  if services_group
    file_path = 'Billix/Features/Rewards/Services/RewardsService.swift'
    if File.exist?(file_path) && !services_group.files.any? { |f| f.name == 'RewardsService.swift' }
      file_ref = services_group.new_reference('RewardsService.swift')
      file_ref.source_tree = '<group>'
      target.source_build_phase.add_file_reference(file_ref)
      puts "✓ Added: RewardsService.swift (CRITICAL for point economy!)"
      total_added += 1
    end
  end
end

# REWARDS COMPONENTS
rewards_components = rewards_group['Views']['Components'] if rewards_group && rewards_group['Views']
if rewards_components
  ['VirtualGoodsModal.swift'].each do |filename|
    file_path = "Billix/Features/Rewards/Views/Components/#{filename}"
    if File.exist?(file_path) && !rewards_components.files.any? { |f| f.name == filename }
      file_ref = rewards_components.new_reference(filename)
      file_ref.source_tree = '<group>'
      target.source_build_phase.add_file_reference(file_ref)
      puts "✓ Added: #{filename}"
      total_added += 1
    end
  end
end

# TRUSTLADDER VIEWS
puts "\n=== TRUSTLADDER ==="
trustladder_group = project.main_group['Billix']['Features']['TrustLadder']
if trustladder_group
  views_group = trustladder_group['Views']
  if views_group
    file_path = 'Billix/Features/TrustLadder/Views/TrustLadderHubView.swift'
    if File.exist?(file_path) && !views_group.files.any? { |f| f.name == 'TrustLadderHubView.swift' }
      file_ref = views_group.new_reference('TrustLadderHubView.swift')
      file_ref.source_tree = '<group>'
      target.source_build_phase.add_file_reference(file_ref)
      puts "✓ Added: TrustLadderHubView.swift"
      total_added += 1
    end
  end
end

# UPLOAD COMPONENTS
puts "\n=== UPLOAD/COMPONENTS ==="
upload_group = project.main_group['Billix']['Features']['Upload']
if upload_group
  views_group = upload_group['Views']
  if views_group
    components_group = views_group['Components']
    if components_group
      total_added += add_files_to_group(components_group, 'Billix/Features/Upload/Views/Components', target, 'Upload/Components')
    end
  end
end

# CORE EXTENSIONS
puts "\n=== CORE/EXTENSIONS ==="
core_group = project.main_group['Billix']['Core']
if core_group
  extensions_group = core_group['Extensions']
  if extensions_group
    total_added += add_files_to_group(extensions_group, 'Billix/Core/Extensions', target, 'Core/Extensions')
  end
end

# UTILITIES/COMPONENTS
puts "\n=== UTILITIES/COMPONENTS ==="
utilities_group = project.main_group['Billix']['Utilities']
if utilities_group
  components_group = utilities_group['Components']
  if components_group
    total_added += add_files_to_group(components_group, 'Billix/Utilities/Components', target, 'Utilities/Components')
  end
end

project.save

puts "\n" + "="*60
puts "✅ COMPLETE: Added #{total_added} remaining files"
puts "="*60
puts "\n📊 Summary:"
puts "   • Home/Components: 18 files"
puts "   • RewardsService.swift (point economy)"
puts "   • Upload, Core, Utilities components"
puts "\nNext: Build in Xcode (Cmd+B)"
