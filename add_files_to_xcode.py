#!/usr/bin/env python3

import os
import uuid
import glob

def generate_xcode_uuid():
    """Generate a UUID in Xcode format (24 hex characters)"""
    return ''.join(str(uuid.uuid4()).upper().replace('-', '')[:24])

def find_core_data_files():
    """Find all Core Data model files"""
    model_files = glob.glob("FitnessCoach/Core/Database/Models/*.swift")
    return model_files

def main():
    # Find all Core Data model files
    model_files = find_core_data_files()
    
    print(f"Found {len(model_files)} Core Data model files:")
    
    file_refs = []
    build_files = []
    
    for file_path in sorted(model_files):
        filename = os.path.basename(file_path)
        file_uuid = generate_xcode_uuid()
        build_uuid = generate_xcode_uuid()
        
        # Create file reference entry
        file_ref = f'\t\t{file_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{filename}"; sourceTree = "<group>"; }};'
        file_refs.append(file_ref)
        
        # Create build file entry
        build_file = f'\t\t{build_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {filename} */; }};'
        build_files.append(build_file)
        
        print(f"  {filename} -> {file_uuid}")
    
    print("\n=== FILE REFERENCES TO ADD ===")
    for ref in file_refs:
        print(ref)
    
    print("\n=== BUILD FILES TO ADD ===") 
    for build in build_files:
        print(build)
        
    print("\n=== GROUP ENTRIES TO ADD ===")
    print("Add these to the Database group:")
    for file_path in sorted(model_files):
        filename = os.path.basename(file_path)
        file_uuid = [ref for ref in file_refs if filename in ref][0].split()[0]
        print(f'\t\t\t\t{file_uuid} /* {filename} */,')
        
    print("\n=== BUILD PHASE ENTRIES TO ADD ===")
    print("Add these to PBXSourcesBuildPhase:")
    for build in build_files:
        build_uuid = build.split()[0]
        filename = build.split('/*')[1].split('*/')[0].strip()
        print(f'\t\t\t\t{build_uuid} /* {filename} */,')

if __name__ == "__main__":
    main()