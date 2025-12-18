# CRITICAL: Target Membership Fix Required

## The Problem

Files are in the wrong targets, causing duplicate declarations. The errors show:
- `MacWidgetDefinitions.swift` is in the **iOS** target (should be Mac ONLY)
- `WidgetDefinitions.swift` might still be in the **Mac** target (should be iOS ONLY)

## Step-by-Step Fix in Xcode

### 1. Remove MacWidgetDefinitions.swift from iOS Target

1. Select `AMFScheduleWidgetMac/Widgets/MacWidgetDefinitions.swift` in Project Navigator
2. Open File Inspector (⌥⌘1)
3. Under "Target Membership":
   - ❌ **UNCHECK** `AMFScheduleWidgetExtension` (iOS)
   - ✅ **CHECK** `AMFScheduleWidgetMACExtension` (Mac)

### 2. Remove WidgetDefinitions.swift from Mac Target

1. Select `AMFScheduleWidget/Widgets/WidgetDefinitions.swift` in Project Navigator
2. Open File Inspector (⌥⌘1)
3. Under "Target Membership":
   - ✅ **CHECK** `AMFScheduleWidgetExtension` (iOS)
   - ❌ **UNCHECK** `AMFScheduleWidgetMACExtension` (Mac)

### 3. Verify AMFScheduleWidget.swift is in BOTH Targets

1. Select `AMFScheduleWidget/Widgets/AMFScheduleWidget.swift` in Project Navigator
2. Open File Inspector (⌥⌘1)
3. Under "Target Membership":
   - ✅ **CHECK** `AMFScheduleWidgetExtension` (iOS)
   - ✅ **CHECK** `AMFScheduleWidgetMACExtension` (Mac)

This is CORRECT - this file is shared, but the duplicate types are wrapped in `#if !os(macOS)` guards.

## Summary of Target Memberships

### iOS Extension ONLY (`AMFScheduleWidgetExtension`):
- ✅ `AMFScheduleWidget/AMFScheduleWidgetBundle.swift`
- ✅ `AMFScheduleWidget/Widgets/WidgetDefinitions.swift`
- ❌ `AMFScheduleWidgetMac/Widgets/MacWidgetDefinitions.swift` ← **REMOVE THIS**

### Mac Extension ONLY (`AMFScheduleWidgetMACExtension`):
- ✅ `AMFScheduleWidgetMac/AMFScheduleWidgetMacBundle.swift`
- ✅ `AMFScheduleWidgetMac/Widgets/MacWidgetDefinitions.swift`
- ❌ `AMFScheduleWidget/Widgets/WidgetDefinitions.swift` ← **REMOVE THIS**

### BOTH Extensions:
- ✅ `AMFScheduleWidget/Widgets/AMFScheduleWidget.swift` (with platform guards)
- ✅ `AMFScheduleWidget/Widgets/ScheduleWidgetProvider.swift`
- ✅ `AMFScheduleWidget/Widgets/ScheduleWidgetIntent.swift`
- ✅ `AMFScheduleWidget/Widgets/WeatherClusterView.swift`
- ✅ All Shared Models and Services

## After Fixing

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Build iOS Extension**: Select "AMFScheduleWidgetExtension" → Build (⌘B)
3. **Build Mac Extension**: Select "AMFScheduleWidgetMACExtension" → Build (⌘B)

Both should build successfully!
