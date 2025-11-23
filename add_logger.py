#!/usr/bin/env python3
import re
import uuid

# 파일 읽기
with open('LottoChecker.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# 추가할 파일
new_files = ['AppLogger.swift']

# 이미 추가된 파일 확인
existing_files = set(re.findall(r'([A-Za-z0-9_]+\.swift)', content))
files_to_add = [f for f in new_files if f not in existing_files]

if not files_to_add:
    print("All files are already in the project!")
    exit(0)

# UUID 생성 함수
def generate_uuid():
    return uuid.uuid4().hex[:24].upper()

# 새로운 항목들 생성
new_build_files = []
new_file_refs = []
new_group_refs = []
new_source_refs = []

for filename in files_to_add:
    file_uuid = generate_uuid()
    build_uuid = generate_uuid()

    # PBXBuildFile 엔트리
    new_build_files.append(f"\t\t{build_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {filename} */; }};")

    # PBXFileReference 엔트리
    new_file_refs.append(f"\t\t{file_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};")

    # PBXGroup 엔트리
    new_group_refs.append(f"\t\t\t\t{file_uuid} /* {filename} */,")

    # PBXSourcesBuildPhase 엔트리
    new_source_refs.append(f"\t\t\t\t{build_uuid} /* {filename} in Sources */,")

# 콘텐츠 업데이트
# 1. PBXBuildFile 섹션에 추가
build_file_end = content.find('/* End PBXBuildFile section */')
content = content[:build_file_end] + '\n'.join(new_build_files) + '\n' + content[build_file_end:]

# 2. PBXFileReference 섹션에 추가
file_ref_end = content.find('/* End PBXFileReference section */')
content = content[:file_ref_end] + '\n'.join(new_file_refs) + '\n' + content[file_ref_end:]

# 3. PBXGroup 섹션에 추가
group_match = re.search(r'(/\* LottoChecker \*/.*?children = \()(.*?)(\);)', content, re.DOTALL)
if group_match:
    group_start = group_match.start(2)
    group_end = group_match.end(2)
    current_children = content[group_start:group_end]
    new_children = current_children.rstrip() + '\n' + '\n'.join(new_group_refs) + '\n\t\t\t'
    content = content[:group_start] + new_children + content[group_end:]

# 4. PBXSourcesBuildPhase 섹션에 추가
sources_match = re.search(r'(/\* Sources \*/.*?isa = PBXSourcesBuildPhase;.*?files = \()(.*?)(\);)', content, re.DOTALL)
if sources_match:
    sources_start = sources_match.start(2)
    sources_end = sources_match.end(2)
    current_files = content[sources_start:sources_end]
    new_files_content = current_files.rstrip() + '\n' + '\n'.join(new_source_refs) + '\n\t\t\t'
    content = content[:sources_start] + new_files_content + content[sources_end:]

# 파일 쓰기
with open('LottoChecker.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("Successfully updated project.pbxproj!")
print(f"Added {len(files_to_add)} files to the project:")
for filename in files_to_add:
    print(f"  - {filename}")
