# Mac Widget Extension Build Fixes - Complete Guide

## Issues Fixed in Code

### ✅ 1. Duplicate `widgetGlassBackground` Extension
**Fixed:** Made the extension platform-specific:
- `WidgetDefinitions.swift`: Extension wrapped in `#if !os(macOS)`
- `MacWidgetDefinitions.swift`: Extension wrapped in `#if os(macOS)`

### ✅ 2. Missing `DayboardExtraLargeView` Reference
**Fixed:** Updated `iPadDayboardView` to use existing ExtraLarge views from `AMFScheduleWidget.swift`

## Issues That Need Xcode Configuration

### ❌ CRITICAL: Remove iOS Bundle from Mac Target

**Problem:** `AMFScheduleWidgetBundle.swift` is being compiled for macOS, but it references `AMFScheduleWidget` which is not in the Mac target (and shouldn't be).

**Solution in Xcode:**
1. Open the project in Xcode
2. Select `AMFScheduleWidget/AMFScheduleWidgetBundle.swift` in the Project Navigator
3. Open the **File Inspector** (⌥⌘1 or View → Inspectors → File)
4. Under **"Target Membership"**, **UNCHECK** the box for `AMFScheduleWidgetMACExtension`
5. Make sure it's only checked for `AMFScheduleWidgetExtension` (iOS)

### ❌ Remove `WidgetDefinitions.swift` from Mac Target (if present)

**Problem:** `WidgetDefinitions.swift` contains iOS-only widget definitions that shouldn't be compiled for macOS.

**Solution in Xcode:**
1. Select `AMFScheduleWidget/Widgets/WidgetDefinitions.swift` in the Project Navigator
2. Open the **File Inspector** (⌥⌘1)
3. Under **"Target Membership"**, **UNCHECK** the box for `AMFScheduleWidgetMACExtension`
4. Make sure it's only checked for `AMFScheduleWidgetExtension` (iOS)

### ✅ Verify Required Files Are in Mac Target

Ensure these files ARE checked for `AMFScheduleWidgetMACExtension`:

**Core Widget Files:**
- ✅ `AMFScheduleWidget/Widgets/ScheduleWidgetProvider.swift`
- ✅ `AMFScheduleWidget/Widgets/ScheduleWidgetIntent.swift`
- ✅ `AMFScheduleWidget/Widgets/WeatherClusterView.swift`

**Mac Widget Files:**
- ✅ `AMFScheduleWidgetMac/AMFScheduleWidgetMacBundle.swift`
- ✅ `AMFScheduleWidgetMac/Widgets/MacWidgetDefinitions.swift`
- ✅ `AMFScheduleWidget/Widgets/Mac/MacAmbientAgendaWidget.swift`
- ✅ `AMFScheduleWidget/Widgets/Mac/MacNotificationCenterWidget.swift`

**Interactive Widget Features:**
- ✅ `AMFScheduleWidget/Widgets/Intents/WidgetInteractionIntents.swift`

**Supporting Views:**
- ✅ `AMFScheduleWidget/Widgets/iPad/SwimlanesView.swift`
- ✅ `AMFScheduleWidget/Widgets/iPad/TimelineView.swift` (contains `HourTickBar` and `CalendarColors`)

**Shared Models (ALL):**
- ✅ `Schedule Summary Widget Nov 26 2025/Shared/Models/ScheduleEvent.swift`
- ✅ `Schedule Summary Widget Nov 26 2025/Shared/Models/ClientCalendar.swift`
- ✅ `Schedule Summary Widget Nov 26 2025/Shared/Models/Summaries.swift`
- ✅ `Schedule Summary Widget Nov 26 2025/Shared/Models/WeatherModel.swift`
- ✅ `Schedule Summary Widget Nov 26 2025/Shared/Models/WidgetTheme.swift`

**Shared Services (ALL):**
- ✅ `Schedule Summary Widget Nov 26 2025/Shared/Services/AppGroupStore.swift`
- ✅ `Schedule Summary Widget Nov 26 2025/Shared/Services/WidgetThemeStore.swift`
- ✅ `Schedule Summary Widget Nov 26 2025/Shared/Services/CalendarService.swift`
- ✅ `Schedule Summary Widget Nov 26 2025/Shared/Services/WeatherService.swift`
- ✅ `Schedule Summary Widget Nov 26 2025/Shared/Services/GeminiSummarizer.swift`
- ✅ `Schedule Summary Widget Nov 26 2025/Shared/Services/GoogleCalendarAPI.swift`

### ❌ Remove iOS-Only Files from Mac Target

These files should NOT be in the Mac extension target:

- ❌ `AMFScheduleWidget/AMFScheduleWidgetBundle.swift` (iOS bundle)
- ❌ `AMFScheduleWidget/Widgets/WidgetDefinitions.swift` (iOS widgets)
- ❌ `AMFScheduleWidget/Widgets/AMFScheduleWidget.swift` (iOS main widget - Mac has its own)
- ❌ `AMFScheduleWidget/Widgets/iPad/iPadDayboardWidget.swift` (iOS only)
- ❌ `AMFScheduleWidget/Widgets/iPad/LockScreenWidgets.swift` (iOS only)

## Quick Fix Checklist

1. [ ] Remove `AMFScheduleWidgetBundle.swift` from `AMFScheduleWidgetMACExtension` target
2. [ ] Remove `WidgetDefinitions.swift` from `AMFScheduleWidgetMACExtension` target (if present)
3. [ ] Verify `WidgetInteractionIntents.swift` IS in `AMFScheduleWidgetMACExtension` target
4. [ ] Verify all Shared Models and Services are in `AMFScheduleWidgetMACExtension` target
5. [ ] Clean build folder: Product → Clean Build Folder (⇧⌘K)
6. [ ] Build Mac extension: Select "AMFScheduleWidgetMACExtension" scheme and build (⌘B)

## After Fixing

Once you've made these changes in Xcode, the Mac extension should build successfully. The Mac widgets will appear as:
- **Ambient Agenda** - Desktop timeline widget
- **Next Up** - Quick glance widget
- **Interactive Schedule** - With buttons

These will be native macOS widgets (not "From iPhone").
