#!/usr/bin/env python3
import uuid
import re

# Generate unique IDs
def generate_id():
    return ''.join([format(int(x, 16), 'X') for x in str(uuid.uuid4()).replace('-', '')[:24]])

# Read the project file
with open('LottoChecker.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# New files to add
new_files = [
    'MainTabView.swift',
    'RandomNumberGeneratorView.swift',
    'AnalysisView.swift',
    'ExpectedValueView.swift',
    'WinningCheckView.swift'
]

# Generate IDs for each file
file_refs = {}
build_files = {}
for filename in new_files:
    file_refs[filename] = generate_id()
    build_files[filename] = generate_id()

# Add to PBXBuildFile section
build_file_section = "/* Begin PBXBuildFile section */"
build_file_entries = []
for filename in new_files:
    entry = f"\t\t{build_files[filename]} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[filename]} /* {filename} */; }};"
    build_file_entries.append(entry)

insertion_point = content.find("/* End PBXBuildFile section */")
new_build_files = '\n'.join(build_file_entries) + '\n'
content = content[:insertion_point] + new_build_files + content[insertion_point:]

# Add to PBXFileReference section
file_ref_entries = []
for filename in new_files:
    entry = f"\t\t{file_refs[filename]} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};"
    file_ref_entries.append(entry)

insertion_point = content.find("/* End PBXFileReference section */")
new_file_refs = '\n'.join(file_ref_entries) + '\n'
content = content[:insertion_point] + new_file_refs + content[insertion_point:]

# Add to PBXGroup section (LottoChecker folder)
group_entries = []
for filename in new_files:
    entry = f"\t\t\t\t{file_refs[filename]} /* {filename} */,"
    group_entries.append(entry)

# Find the LottoChecker group and add files
pattern = r'(F1A2B3C4D5E6F7A8B9C0D1E2 /\* LottoChecker \*/ = {[^}]+children = \([^)]+)(B3C4D5E6F7A8B9C0D1E2F3A4 /\* Assets.xcassets \*/,)'
replacement = r'\1' + '\n'.join(group_entries) + '\n\t\t\t\t\\2'
content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Add to PBXSourcesBuildPhase section
source_entries = []
for filename in new_files:
    entry = f"\t\t\t\t{build_files[filename]} /* {filename} in Sources */,"
    source_entries.append(entry)

pattern = r'(D2E3F4A5B6C7D8E9F0A1B2C3 /\* Sources \*/ = {[^}]+files = \([^)]+)(A6B7C8D9E0F1A2B3C4D5E6F7 /\* LottoViewModel.swift in Sources \*/,)'
replacement = r'\1\2\n' + '\n'.join(source_entries)
content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Write back
with open('LottoChecker.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("Successfully updated project.pbxproj!")
print(f"Added {len(new_files)} files to the project:")
for filename in new_files:
    print(f"  - {filename}")
