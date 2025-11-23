#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'LottoChecker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get the main group (LottoChecker folder)
main_group = project.main_group.find_subpath('LottoChecker')

# Files to add
files = [
  'MainTabView.swift',
  'RandomNumberGeneratorView.swift',
  'AnalysisView.swift',
  'ExpectedValueView.swift',
  'WinningCheckView.swift'
]

files.each do |filename|
  file_path = "LottoChecker/#{filename}"

  # Check if file already exists in project
  existing = main_group.files.find { |f| f.path == filename }
  next if existing

  # Add file reference
  file_ref = main_group.new_file(file_path)

  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)

  puts "Added #{filename}"
end

project.save
puts "Project updated successfully!"
