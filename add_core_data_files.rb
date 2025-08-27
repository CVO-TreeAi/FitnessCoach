#!/usr/bin/env ruby

require 'pathname'

project_path = "FitnessCoach.xcodeproj"
models_dir = "FitnessCoach/Core/Database/Models"

# Get all Swift files in the Models directory
model_files = Dir["#{models_dir}/*.swift"].map { |f| Pathname.new(f).relative_path_from(Pathname.new(".")) }

puts "Found #{model_files.length} Core Data model files:"
model_files.each { |f| puts "  #{f}" }

# For now, just print what we would do
puts "\nTo add these files to Xcode project:"
puts "1. Open FitnessCoach.xcodeproj in Xcode"
puts "2. Right-click on 'Core/Database' group"  
puts "3. Select 'Add Files to FitnessCoach'"
puts "4. Navigate to and select the Models folder"
puts "5. Make sure 'Create groups' is selected"
puts "6. Click 'Add'"

puts "\nAlternatively, drag the Models folder from Finder into the Xcode project navigator under Core/Database/"