# Target Membership Fix - Step by Step

## iOS Extension Errors

The errors indicate that `AMFScheduleWidget.swift` is **NOT** in the `AMFScheduleWidgetExtension` (iOS) target.

### Fix for iOS Extension:

1. **Open Xcode**
2. **Select** `AMFScheduleWidget/Widgets/AMFScheduleWidget.swift` in the Project Navigator
3. **Open File Inspector** (⌥⌘1 or View → Inspectors → File)
4. **Under "Target Membership"**, **CHECK** the box for:
   - ✅ `AMFScheduleWidgetExtension` (iOS)
   - ❌ `AMFScheduleWidgetMACExtension` (Mac) - should be UNCHECKED

### Verify These Files Are in iOS Extension Target:

**Required for iOS:**
- ✅ `AMFScheduleWidget/Widgets/AMFScheduleWidget.swift` ← **THIS IS MISSING!**
- ✅ `AMFScheduleWidget/AMFScheduleWidgetBundle.swift`
- ✅ `AMFScheduleWidget/Widgets/WidgetDefinitions.swift`
- ✅ `AMFScheduleWidget/Widgets/ScheduleWidgetProvider.swift`
- ✅ `AMFScheduleWidget/Widgets/ScheduleWidgetIntent.swift`
- ✅ `AMFScheduleWidget/Widgets/WeatherClusterView.swift`
- ✅ All Shared Models and Services

## Mac Extension Errors

The Mac extension only has **deprecation warnings** (not errors), which won't prevent building. These are just warnings about using deprecated APIs.

### Optional: Fix Deprecation Warnings

The warnings are in `WeatherService.swift` about `CLGeocoder`. These are just warnings and won't prevent the build, but you can fix them later by updating to use MapKit instead.

## Quick Checklist

### For iOS Extension (`AMFScheduleWidgetExtension`):
- [ ] `AMFScheduleWidget.swift` IS checked ✅
- [ ] `AMFScheduleWidgetBundle.swift` IS checked ✅
- [ ] `WidgetDefinitions.swift` IS checked ✅
- [ ] All Shared files ARE checked ✅

### For Mac Extension (`AMFScheduleWidgetMACExtension`):
- [ ] `AMFScheduleWidget.swift` is NOT checked ❌
- [ ] `AMFScheduleWidgetBundle.swift` is NOT checked ❌
- [ ] `WidgetDefinitions.swift` is NOT checked ❌
- [ ] `AMFScheduleWidgetMacBundle.swift` IS checked ✅
- [ ] `MacWidgetDefinitions.swift` IS checked ✅
- [ ] All Shared files ARE checked ✅

## After Fixing

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Build iOS Extension**: Select "AMFScheduleWidgetExtension" scheme and build (⌘B)
3. **Build Mac Extension**: Select "AMFScheduleWidgetMACExtension" scheme and build (⌘B)

Both should build successfully after fixing the target memberships!
