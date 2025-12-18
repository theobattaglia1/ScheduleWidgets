# macOS Widget Target Cleanup Guide

## ❌ REMOVE THESE (Should NOT be in macOS widget target)

### Main App Files (App-only, not widgets)
1. **MenuBarApp.swift** ❌
   - This is a menu bar app, not a widget
   - Should only be in main app target

2. **CalendarSettingsView.swift** ❌
   - Main app UI
   - Should only be in main app target

3. **PhotoBackgroundEditorView.swift** ❌
   - Main app UI
   - Should only be in main app target

4. **WidgetStudioView.swift** ❌
   - Main app UI
   - Should only be in main app target

### iOS-Only Widget Files
5. **AMFScheduleWidgetBundle.swift** ❌
   - This is the iOS widget bundle
   - macOS has its own bundle: `AMFScheduleWidgetMacBundle.swift`

6. **WidgetDefinitions.swift** ❌
   - Contains iOS-only widgets (`AMFLockScreenWidget`, `AMFDayboardWidget`)
   - macOS widgets are in `MacWidgetDefinitions.swift`

7. **iPadDayboardWidget.swift** ❌
   - iPad-specific widget
   - Not needed for macOS

8. **LockScreenWidgets.swift** ❌
   - iOS lock screen widgets only
   - Not available on macOS

### Auto-Generated Template Files (Replace with real code)
9. **AMFScheduleWidgetMAC.swift** ❌
   - Auto-generated template file
   - We use `ScheduleWidgetProvider.swift` instead

10. **AMFScheduleWidgetMACControl.swift** ❌
    - Auto-generated template file
    - Not needed for our widgets

11. **AppIntent.swift** ❌
    - Auto-generated template file
    - We use `ScheduleWidgetIntent.swift` instead

---

## ✅ KEEP THESE (Should be in macOS widget target)

### Core Widget Files
- ✅ ScheduleWidgetProvider.swift
- ✅ ScheduleWidgetIntent.swift
- ✅ WeatherClusterView.swift
- ✅ AMFScheduleWidget.swift (for shared views like MarkdownText, CompactEventRow)

### macOS Widget Definitions
- ✅ AMFScheduleWidgetMacBundle.swift
- ✅ MacWidgetDefinitions.swift
- ✅ MacAmbientAgendaWidget.swift
- ✅ MacNotificationCenterWidget.swift

### Interactive Features
- ✅ WidgetInteractionIntents.swift

### Supporting Views
- ✅ SwimlanesView.swift
- ✅ TimelineView.swift

### Shared Models
- ✅ ClientCalendar.swift
- ✅ ScheduleEvent.swift
- ✅ Summaries.swift
- ✅ WeatherModel.swift
- ✅ WidgetTheme.swift

### Shared Services
- ✅ AppGroupStore.swift
- ✅ WidgetThemeStore.swift
- ✅ CalendarService.swift
- ✅ WeatherService.swift
- ✅ GeminiSummarizer.swift
- ✅ GoogleCalendarAPI.swift

### Shared Configuration
- ✅ Configuration.swift

---

## 📋 Summary

**Remove 11 files:**
- 4 main app files
- 4 iOS-only widget files
- 3 auto-generated template files

**Keep 22 files:**
- All the core widget, macOS widget, shared models, and shared services files

---

## 🔧 How to Remove Files from Target

1. Select the file in Project Navigator
2. Press ⌥⌘1 (File Inspector)
3. Under "Target Membership", **uncheck** `AMFScheduleWidgetMACExtension`
4. Repeat for each file listed above

---

## ⚠️ Important Notes

- **Don't delete the files** - just remove them from the macOS widget target
- The main app target should still have access to MenuBarApp.swift, CalendarSettingsView.swift, etc.
- The iOS widget target should still have access to AMFScheduleWidgetBundle.swift, WidgetDefinitions.swift, etc.


