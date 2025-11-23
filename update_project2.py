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
new_swift_file = 'QRCodeScannerView.swift'
info_plist_file = 'Info.plist'

# Generate IDs
swift_file_ref = generate_id()
swift_build_file = generate_id()
plist_file_ref = generate_id()

# Add QRCodeScannerView.swift to PBXBuildFile section
build_file_entry = f"\t\t{swift_build_file} /* {new_swift_file} in Sources */ = {{isa = PBXBuildFile; fileRef = {swift_file_ref} /* {new_swift_file} */; }};"
insertion_point = content.find("/* End PBXBuildFile section */")
content = content[:insertion_point] + build_file_entry + '\n' + content[insertion_point:]

# Add to PBXFileReference section
file_ref_swift = f"\t\t{swift_file_ref} /* {new_swift_file} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {new_swift_file}; sourceTree = \"<group>\"; }};"
file_ref_plist = f"\t\t{plist_file_ref} /* {info_plist_file} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = {info_plist_file}; sourceTree = \"<group>\"; }};"
insertion_point = content.find("/* End PBXFileReference section */")
content = content[:insertion_point] + file_ref_swift + '\n' + file_ref_plist + '\n' + content[insertion_point:]

# Add to PBXGroup section (LottoChecker folder)
# Find the LottoChecker group and add files
pattern = r'(F1A2B3C4D5E6F7A8B9C0D1E2 /\* LottoChecker \*/ = {[^}]+children = \([^)]+)(B3C4D5E6F7A8B9C0D1E2F3A4 /\* Assets.xcassets \*/,)'
replacement = f'\\1\t\t\t\t{swift_file_ref} /* {new_swift_file} */,\n\t\t\t\t{plist_file_ref} /* {info_plist_file} */,\n\t\t\t\t\\2'
content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Add to PBXSourcesBuildPhase section
source_entry = f"\t\t\t\t{swift_build_file} /* {new_swift_file} in Sources */,"
pattern = r'(D2E3F4A5B6C7D8E9F0A1B2C3 /\* Sources \*/ = {[^}]+files = \([^)]+624A15EBC7894001B6412A62 /\* MainTabView.swift in Sources \*/,)'
replacement = f'\\1\n{source_entry}'
content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Update build settings to use Info.plist
# Find the Debug configuration and add INFOPLIST_FILE setting
pattern = r'(C6D7E8F9A0B1C2D3E4F5A6B7 /\* Debug \*/ = {[^}]+buildSettings = {[^}]+)(DEVELOPMENT_ASSET_PATHS = "";)'
replacement = r'\1INFOPLIST_FILE = LottoChecker/Info.plist;\n\t\t\t\t\2'
content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Do the same for Release configuration
pattern = r'(C7D8E9F0A1B2C3D4E5F6A7B8 /\* Release \*/ = {[^}]+buildSettings = {[^}]+)(DEVELOPMENT_ASSET_PATHS = "";)'
replacement = r'\1INFOPLIST_FILE = LottoChecker/Info.plist;\n\t\t\t\t\2'
content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Also need to change GENERATE_INFOPLIST_FILE to NO
content = re.sub(r'GENERATE_INFOPLIST_FILE = YES;', 'GENERATE_INFOPLIST_FILE = NO;', content)

# Write back
with open('LottoChecker.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("Successfully updated project.pbxproj!")
print(f"Added {new_swift_file}")
print(f"Added {info_plist_file}")
print("Updated build settings to use custom Info.plist")
