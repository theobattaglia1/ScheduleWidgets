#!/usr/bin/env python3
"""
Xcode Target Membership Checker
Checks which files are in which targets and reports what should be added/removed
"""

import re
import json
from pathlib import Path

# Define what SHOULD be in each target
MACOS_WIDGET_FILES = {
    # Core widget files
    "AMFScheduleWidget/Widgets/ScheduleWidgetProvider.swift",
    "AMFScheduleWidget/Widgets/ScheduleWidgetIntent.swift",
    "AMFScheduleWidget/Widgets/WeatherClusterView.swift",
    "AMFScheduleWidget/Widgets/AMFScheduleWidget.swift",
    
    # macOS widget definitions
    "AMFScheduleWidgetMAC/AMFScheduleWidgetMacBundle.swift",
    "AMFScheduleWidgetMAC/Widgets/MacWidgetDefinitions.swift",
    "AMFScheduleWidget/Widgets/Mac/MacAmbientAgendaWidget.swift",
    "AMFScheduleWidget/Widgets/Mac/MacNotificationCenterWidget.swift",
    
    # Interactive features
    "AMFScheduleWidget/Widgets/Intents/WidgetInteractionIntents.swift",
    
    # Supporting views
    "AMFScheduleWidget/Widgets/iPad/SwimlanesView.swift",
    "AMFScheduleWidget/Widgets/iPad/TimelineView.swift",
    
    # Shared models
    "Schedule Summary Widget Nov 26 2025/Shared/Models/ScheduleEvent.swift",
    "Schedule Summary Widget Nov 26 2025/Shared/Models/ClientCalendar.swift",
    "Schedule Summary Widget Nov 26 2025/Shared/Models/Summaries.swift",
    "Schedule Summary Widget Nov 26 2025/Shared/Models/WeatherModel.swift",
    "Schedule Summary Widget Nov 26 2025/Shared/Models/WidgetTheme.swift",
    
    # Shared services
    "Schedule Summary Widget Nov 26 2025/Shared/Services/AppGroupStore.swift",
    "Schedule Summary Widget Nov 26 2025/Shared/Services/WidgetThemeStore.swift",
    "Schedule Summary Widget Nov 26 2025/Shared/Services/CalendarService.swift",
    "Schedule Summary Widget Nov 26 2025/Shared/Services/WeatherService.swift",
    "Schedule Summary Widget Nov 26 2025/Shared/Services/GeminiSummarizer.swift",
    "Schedule Summary Widget Nov 26 2025/Shared/Services/GoogleCalendarAPI.swift",
}

MAIN_APP_ONLY_FILES = {
    "Schedule Summary Widget Nov 26 2025/AMFScheduleApp.swift",
    "Schedule Summary Widget Nov 26 2025/ContentView.swift",
    "Schedule Summary Widget Nov 26 2025/CalendarSettingsView.swift",
    "Schedule Summary Widget Nov 26 2025/PhotoBackgroundEditorView.swift",
    "Schedule Summary Widget Nov 26 2025/WidgetStudioView.swift",
    "Schedule Summary Widget Nov 26 2025/Shared/Services/BackgroundScheduler.swift",
}

IOS_WIDGET_ONLY_FILES = {
    "AMFScheduleWidget/AMFScheduleWidgetBundle.swift",
    "AMFScheduleWidget/Widgets/WidgetDefinitions.swift",
    "AMFScheduleWidget/Widgets/iPad/iPadDayboardWidget.swift",
    "AMFScheduleWidget/Widgets/iPad/LockScreenWidgets.swift",
}

def parse_pbxproj(project_path):
    """Parse the Xcode project file to extract file references and target memberships"""
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Extract file references (PBXFileReference)
    file_refs = {}
    file_ref_pattern = r'(\w+)\s*=\s*\{isa = PBXFileReference;.*?path = ([^;]+);.*?sourceTree = ([^;]+);'
    for match in re.finditer(file_ref_pattern, content, re.DOTALL):
        ref_id = match.group(1)
        path = match.group(2).strip().strip('"')
        source_tree = match.group(3).strip()
        file_refs[ref_id] = {'path': path, 'source_tree': source_tree}
    
    # Extract build files (PBXBuildFile)
    build_files = {}
    build_file_pattern = r'(\w+)\s*=\s*\{isa = PBXBuildFile; fileRef = (\w+)'
    for match in re.finditer(build_file_pattern, content):
        build_file_id = match.group(1)
        file_ref_id = match.group(2)
        build_files[build_file_id] = file_ref_id
    
    # Extract target build phases
    targets = {}
    target_pattern = r'(\w+)\s*=\s*\{isa = PBXNativeTarget;.*?name = ([^;]+);'
    for match in re.finditer(target_pattern, content, re.DOTALL):
        target_id = match.group(1)
        target_name = match.group(2).strip().strip('"')
        targets[target_id] = {'name': target_name, 'files': []}
    
    # Extract sources build phases
    sources_pattern = r'(\w+)\s*=\s*\{isa = PBXSourcesBuildPhase;.*?files = \((.*?)\);'
    for match in re.finditer(sources_pattern, content, re.DOTALL):
        phase_id = match.group(1)
        files_str = match.group(2)
        
        # Find which target this phase belongs to
        for target_id, target_info in targets.items():
            target_pattern_inner = rf'{target_id}.*?buildPhases = \((.*?)\);'
            target_match = re.search(target_pattern_inner, content, re.DOTALL)
            if target_match and phase_id in target_match.group(1):
                # Extract file references from this phase
                file_pattern = r'(\w+)\s*/\*.*?\*/'
                for file_match in re.finditer(file_pattern, files_str):
                    build_file_id = file_match.group(1)
                    if build_file_id in build_files:
                        file_ref_id = build_files[build_file_id]
                        if file_ref_id in file_refs:
                            file_path = file_refs[file_ref_id]['path']
                            targets[target_id]['files'].append(file_path)
    
    return targets, file_refs

def normalize_path(path):
    """Normalize file paths for comparison"""
    return path.replace('\\"', '').strip()

def check_target_membership(project_dir):
    """Check target membership and report issues"""
    project_path = Path(project_dir) / "Schedule Summary Widget Nov 26 2025.xcodeproj" / "project.pbxproj"
    
    if not project_path.exists():
        print(f"❌ Project file not found: {project_path}")
        return
    
    print("📋 Analyzing Xcode project file...")
    print("=" * 60)
    
    targets, file_refs = parse_pbxproj(project_path)
    
    # Find macOS widget target
    macos_widget_target = None
    for target_id, target_info in targets.items():
        if 'MAC' in target_info['name'] or 'Mac' in target_info['name']:
            macos_widget_target = target_info
            break
    
    if not macos_widget_target:
        print("⚠️  Could not find macOS widget target")
        print("Available targets:")
        for target_info in targets.values():
            print(f"  - {target_info['name']}")
        return
    
    print(f"\n✅ Found target: {macos_widget_target['name']}")
    print(f"   Files currently in target: {len(macos_widget_target['files'])}")
    print()
    
    # Check what's missing
    current_files = {normalize_path(f) for f in macos_widget_target['files']}
    expected_files = {normalize_path(f) for f in MACOS_WIDGET_FILES}
    
    missing = expected_files - current_files
    extra = current_files - expected_files
    
    print("=" * 60)
    print("📊 TARGET MEMBERSHIP REPORT")
    print("=" * 60)
    
    if missing:
        print(f"\n❌ MISSING FILES ({len(missing)}):")
        print("   These files SHOULD be in the macOS widget target but are NOT:")
        for file in sorted(missing):
            print(f"   - {file}")
    else:
        print("\n✅ All required files are in the target!")
    
    if extra:
        print(f"\n⚠️  EXTRA FILES ({len(extra)}):")
        print("   These files are in the target but might not be needed:")
        for file in sorted(extra):
            if any(excluded in file for excluded in MAIN_APP_ONLY_FILES | IOS_WIDGET_ONLY_FILES):
                print(f"   ⚠️  {file} (should NOT be in macOS widget target)")
            else:
                print(f"   ℹ️  {file} (may be okay)")
    
    print("\n" + "=" * 60)
    print("📝 SUMMARY")
    print("=" * 60)
    print(f"Expected files: {len(expected_files)}")
    print(f"Current files: {len(current_files)}")
    print(f"Missing: {len(missing)}")
    print(f"Extra: {len(extra)}")
    
    if missing:
        print("\n💡 TO FIX:")
        print("   1. Open Xcode")
        print("   2. For each missing file:")
        print("      - Select file in Project Navigator")
        print("      - Press ⌥⌘1 (File Inspector)")
        print("      - Check 'AMFScheduleWidgetMACExtension' under Target Membership")
    
    print()

if __name__ == "__main__":
    import sys
    
    # Get project directory
    script_dir = Path(__file__).parent
    project_dir = script_dir
    
    check_target_membership(project_dir)


