# Target Membership Checklist for AMFScheduleWidgetMACExtension

## ✅ CHECK THESE (Add to macOS Widget Target)

### Core Widget Files
- [ ] `AMFScheduleWidget/Widgets/ScheduleWidgetProvider.swift`
- [ ] `AMFScheduleWidget/Widgets/ScheduleWidgetIntent.swift`
- [ ] `AMFScheduleWidget/Widgets/WeatherClusterView.swift`
- [ ] `AMFScheduleWidget/Widgets/AMFScheduleWidget.swift` (for shared views like `MarkdownText`, `CompactEventRow`, etc.)

### macOS Widget Definitions
- [ ] `AMFScheduleWidgetMAC/AMFScheduleWidgetMacBundle.swift`
- [ ] `AMFScheduleWidgetMAC/Widgets/MacWidgetDefinitions.swift`
- [ ] `AMFScheduleWidget/Widgets/Mac/MacAmbientAgendaWidget.swift`
- [ ] `AMFScheduleWidget/Widgets/Mac/MacNotificationCenterWidget.swift`

### Interactive Widget Features
- [ ] `AMFScheduleWidget/Widgets/Intents/WidgetInteractionIntents.swift`

### Supporting Views (for Interactive widget)
- [ ] `AMFScheduleWidget/Widgets/iPad/SwimlanesView.swift`
- [ ] `AMFScheduleWidget/Widgets/iPad/TimelineView.swift`

### Shared Models (ALL of these)
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Models/ScheduleEvent.swift`
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Models/ClientCalendar.swift`
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Models/Summaries.swift`
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Models/WeatherModel.swift`
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Models/WidgetTheme.swift`

### Shared Services (ALL of these)
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Services/AppGroupStore.swift`
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Services/WidgetThemeStore.swift`
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Services/CalendarService.swift`
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Services/WeatherService.swift`
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Services/GeminiSummarizer.swift`
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Services/GoogleCalendarAPI.swift`

### Shared Configuration
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Configuration.swift` (if it exists)

### Resources (if needed)
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Resources/today_prompt.txt`
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Resources/week_prompt.txt`

### macOS Widget Assets
- [ ] `AMFScheduleWidgetMAC/Assets.xcassets`

---

## ❌ DO NOT CHECK THESE (Main App Only)

- [ ] `Schedule Summary Widget Nov 26 2025/AMFScheduleApp.swift` (main app entry)
- [ ] `Schedule Summary Widget Nov 26 2025/ContentView.swift` (main app UI)
- [ ] `Schedule Summary Widget Nov 26 2025/CalendarSettingsView.swift`
- [ ] `Schedule Summary Widget Nov 26 2025/PhotoBackgroundEditorView.swift`
- [ ] `Schedule Summary Widget Nov 26 2025/WidgetStudioView.swift`
- [ ] `Schedule Summary Widget Nov 26 2025/Shared/Services/BackgroundScheduler.swift` (app-only, uses unavailable APIs)

---

## ❌ DO NOT CHECK THESE (iOS Widget Only)

- [ ] `AMFScheduleWidget/AMFScheduleWidgetBundle.swift` (iOS bundle)
- [ ] `AMFScheduleWidget/Widgets/WidgetDefinitions.swift` (iOS widgets - `AMFLockScreenWidget`, `AMFDayboardWidget`)
- [ ] `AMFScheduleWidget/Widgets/iPad/iPadDayboardWidget.swift` (iPad-specific)
- [ ] `AMFScheduleWidget/Widgets/iPad/LockScreenWidgets.swift` (iOS lock screen only)

---

## How to Check Target Membership

1. Select file in Project Navigator (left sidebar)
2. Open **File Inspector** (right sidebar) - press **⌥⌘1** or click the rightmost icon
3. Scroll down to **"Target Membership"** section
4. Check the box for **`AMFScheduleWidgetMACExtension`**

---

## Quick Check Method

1. In Xcode, select **`AMFScheduleWidgetMACExtension`** target
2. Go to **Build Phases** → **Compile Sources**
3. You should see all the files listed above
4. If a file is missing, add it using the method above

---

## Common Issues

**Error: "Cannot find 'X' in scope"**
→ The file containing 'X' is not in the macOS widget target

**Error: "Failed to load widget"**
→ Usually means a critical file is missing (like `ScheduleWidgetProvider.swift` or `AppGroupStore.swift`)

**Error: "App Group not found"**
→ Check entitlements file has App Group configured


