#!/usr/bin/env python3
import re

project_file = 'FitnessCoach.xcodeproj/project.pbxproj'

# Read project file
with open(project_file, 'r') as f:
    content = f.read()

# Check if already added
if 'QuickComponents.swift' in content:
    print("QuickComponents.swift already in project")
    exit(0)

# Generate UUIDs
file_uuid = 'A1B2C3D4E5F67890ABCDEF12'
build_uuid = 'F1E2D3C4B5A69780FEDCBA21'

# Add file reference
file_ref = f'\t\t{file_uuid} /* QuickComponents.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = QuickComponents.swift; sourceTree = "<group>"; }};'
marker = "/* End PBXFileReference section */"
content = content.replace(marker, file_ref + '\n' + marker)

# Add build file
build_file = f'\t\t{build_uuid} /* QuickComponents.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* QuickComponents.swift */; }};'
marker = "/* End PBXBuildFile section */"
content = content.replace(marker, build_file + '\n' + marker)

# Add to sources
source_line = f'\t\t\t\t{build_uuid} /* QuickComponents.swift in Sources */,'
marker = "/* Sources */,"
sources_pos = content.find(marker)
if sources_pos != -1:
    files_pos = content.find("files = (", sources_pos)
    if files_pos != -1:
        end_pos = content.find(");", files_pos)
        content = content[:end_pos] + source_line + '\n' + content[end_pos:]

# Write back
with open(project_file, 'w') as f:
    f.write(content)

print("Added QuickComponents.swift to project")
