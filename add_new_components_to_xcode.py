#!/usr/bin/env python3

import os
import re
import uuid
import sys

def generate_xcode_uuid():
    """Generate a UUID in Xcode format (24 hex characters)"""
    return ''.join(str(uuid.uuid4()).upper().replace('-', '')[:24])

def add_files_to_xcode_project():
    """Add new Swift files to the Xcode project"""
    
    # Files to add
    files_to_add = [
        # Component files
        ('FitnessCoach/Shared/Components/Core/ThemedComponents.swift', 'Components'),
        ('FitnessCoach/Shared/Components/Charts/ChartComponents.swift', 'Components'),
        ('FitnessCoach/Shared/Components/Input/SearchBar.swift', 'Components'),
        ('FitnessCoach/Shared/Components/Workout/WorkoutComponents.swift', 'Components'),
        
        # Feature models
        ('Features/Dashboard/DashboardModels.swift', 'Dashboard'),
        ('Features/Workouts/WorkoutModels.swift', 'Workouts'),
        ('Features/Nutrition/NutritionModels.swift', 'Nutrition'),
        ('Features/Nutrition/NutritionViewModel.swift', 'Nutrition'),
    ]
    
    project_file = 'FitnessCoach.xcodeproj/project.pbxproj'
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Track what we're adding
    file_refs_section = []
    build_files_section = []
    group_children = {}
    sources_build_phase = []
    
    for file_path, group_name in files_to_add:
        if not os.path.exists(file_path):
            print(f"Warning: {file_path} does not exist")
            continue
            
        filename = os.path.basename(file_path)
        file_uuid = generate_xcode_uuid()
        build_uuid = generate_xcode_uuid()
        
        # Check if file already in project
        if filename in content:
            print(f"Skipping {filename} - already in project")
            continue
        
        # Create file reference
        file_ref = f'\t\t{file_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};'
        file_refs_section.append(file_ref)
        
        # Create build file
        build_file = f'\t\t{build_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {filename} */; }};'
        build_files_section.append(build_file)
        
        # Track for group
        if group_name not in group_children:
            group_children[group_name] = []
        group_children[group_name].append(f'\t\t\t\t{file_uuid} /* {filename} */,')
        
        # Add to sources build phase
        sources_build_phase.append(f'\t\t\t\t{build_uuid} /* {filename} in Sources */,')
        
        print(f"Adding: {filename} to {group_name} group")
    
    if not file_refs_section:
        print("No new files to add")
        return
    
    # Insert file references
    file_ref_marker = "/* End PBXFileReference section */"
    if file_ref_marker in content:
        insert_pos = content.find(file_ref_marker)
        content = content[:insert_pos] + '\n'.join(file_refs_section) + '\n' + content[insert_pos:]
    
    # Insert build files
    build_file_marker = "/* End PBXBuildFile section */"
    if build_file_marker in content:
        insert_pos = content.find(build_file_marker)
        content = content[:insert_pos] + '\n'.join(build_files_section) + '\n' + content[insert_pos:]
    
    # Insert into sources build phase
    sources_marker = "/* Sources */,"
    if sources_marker in content:
        # Find the files = ( section after Sources marker
        sources_pos = content.find(sources_marker)
        files_pos = content.find("files = (", sources_pos)
        if files_pos != -1:
            end_bracket_pos = content.find(");", files_pos)
            content = content[:end_bracket_pos] + '\n'.join(sources_build_phase) + '\n' + content[end_bracket_pos:]
    
    # Write back the modified project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"\nSuccessfully added {len(file_refs_section)} files to Xcode project")
    print("\nNote: You may need to manually organize files into groups in Xcode")
    
    # Print group organization hints
    for group, files in group_children.items():
        print(f"\nFiles for {group} group:")
        for file_entry in files:
            print(f"  {file_entry}")

if __name__ == "__main__":
    add_files_to_xcode_project()