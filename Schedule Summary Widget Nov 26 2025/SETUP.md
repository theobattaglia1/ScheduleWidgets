# AMF Schedule Widget — Setup Guide

## Project Structure

```
Schedule Summary Widget Nov 26 2025/
├── Schedule Summary Widget Nov 26 2025/     # Main App Target
│   ├── AMFScheduleApp.swift                 # App entry point with deep link handling
│   ├── ContentView.swift                    # Main app UI with navigation
│   ├── AppRouter.swift                      # Navigation router for deep links
│   ├── Screens/
│   │   └── ScheduleScreens.swift            # Screen views (Today, FiveDay, NextWeek, EventDetail)
│   ├── Info.plist                           # App configuration
│   └── Schedule_Summary_Widget.entitlements # App entitlements
│
├── AMFScheduleWidget/                       # Widget Extension Target
│   ├── AMFScheduleWidgetBundle.swift        # Widget bundle entry
│   ├── Info.plist                           # Widget configuration
│   ├── AMFScheduleWidget.entitlements       # Widget entitlements
│   └── Widgets/
│       ├── AMFScheduleWidget.swift          # Main configurable widget with all view types
│       ├── ScheduleWidgetProvider.swift     # Timeline provider
│       ├── ScheduleWidgetIntent.swift       # Widget intent
│       ├── WidgetDefinitions.swift          # Additional widget definitions
│       └── WeatherClusterView.swift         # Weather component
│
└── Shared/                                  # Shared Code (add to both targets)
    ├── Configuration.swift                  # All credentials & settings
    ├── DeepLinks/
    │   └── DeepLinkRoute.swift              # Canonical deep link URL handling
    ├── Models/
    │   ├── ScheduleEvent.swift
    │   ├── ClientCalendar.swift
    │   ├── WeatherModel.swift
    │   ├── WidgetTheme.swift
    │   └── Summaries.swift
    ├── Services/
    │   ├── AppGroupStore.swift
    │   ├── GoogleCalendarAPI.swift
    │   ├── CalendarService.swift
    │   ├── WeatherService.swift
    │   ├── GeminiSummarizer.swift
    │   ├── WidgetThemeStore.swift
    │   └── BackgroundScheduler.swift
    └── Resources/
        ├── today_prompt.txt
        └── week_prompt.txt
```

## Xcode Configuration Steps

### 1. Add Shared Files to Both Targets

In Xcode, select all files in the `Shared/` folder (including the new `DeepLinks/` subfolder) and in the File Inspector (right panel), check both targets:
- ☑️ Schedule Summary Widget Nov 26 2025 (main app)
- ☑️ AMFScheduleWidgetExtension (widget)

**New files to add:**
- `Shared/DeepLinks/DeepLinkRoute.swift` - Add to BOTH targets
- `Schedule Summary Widget Nov 26 2025/AppRouter.swift` - Add to main app target only
- `Schedule Summary Widget Nov 26 2025/Screens/ScheduleScreens.swift` - Add to main app target only

### 2. Configure App Groups

1. Select your project in the navigator
2. Select the **main app target**
3. Go to **Signing & Capabilities**
4. Click **+ Capability** → Add **App Groups**
5. Add: `group.Theo.Schedule-Summary-Widget-Nov-26-2025`
6. Repeat for the **widget extension target**

### 3. Configure WeatherKit

1. Select your project
2. Select the **main app target**
3. Go to **Signing & Capabilities**
4. Click **+ Capability** → Add **WeatherKit**
5. Repeat for the **widget extension target**

**Note:** WeatherKit also requires enabling in your Apple Developer account:
- Go to https://developer.apple.com/account/resources/identifiers
- Edit your App ID
- Enable WeatherKit capability

### 4. Configure URL Schemes

The URL schemes are already in `Info.plist`, but verify in Xcode:
1. Select the main app target
2. Go to **Info** tab
3. Expand **URL Types**
4. Verify these schemes exist:
   - `com.googleusercontent.apps.874000025146-0gug8ghng3crr9tucb6105emaarc7uvr` (Google OAuth)
   - `amfschedule` (Deep links)

## Deep Link URL Format

The app supports canonical deep links for widget-to-app navigation:

### Canonical Format
```
amfschedule://open?view=<viewType>&date=<YYYY-MM-DD>&id=<eventId>
```

### Supported URLs
| Destination | URL |
|-------------|-----|
| Today view | `amfschedule://open?view=today` |
| Today view (specific date) | `amfschedule://open?view=today&date=2025-01-15` |
| 5-Day outlook | `amfschedule://open?view=fiveDay` |
| Next week | `amfschedule://open?view=nextWeek` |
| Event detail | `amfschedule://open?view=event&id=EVENT_ID&date=2025-01-15` |

### Legacy URL Support (Backwards Compatible)
The app also accepts legacy URLs:
- `amfschedule://today`
- `amfschedule://week` / `amfschedule://sevenday`
- `amfschedule://nextweek`

### 5. Configure Background Modes

1. Select the main app target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** → Add **Background Modes**
4. Enable:
   - ☑️ Background fetch
   - ☑️ Background processing

### 6. Set Entitlements Files

1. Select the main app target → Build Settings
2. Search for "Code Signing Entitlements"
3. Set to: `Schedule Summary Widget Nov 26 2025/Schedule_Summary_Widget.entitlements`

4. Select the widget target → Build Settings
5. Search for "Code Signing Entitlements"
6. Set to: `AMFScheduleWidget/AMFScheduleWidget.entitlements`

## Google Cloud Console Setup

Your Google OAuth is configured. Ensure your Google Cloud project has:

1. **OAuth consent screen** configured
2. **Credentials** → OAuth 2.0 Client ID for iOS:
   - Bundle ID: `Theo.Schedule-Summary-Widget-Nov-26-2025`
   - No client secret needed (uses PKCE)

3. **APIs enabled:**
   - Google Calendar API

## Embedded Credentials

All credentials are embedded in the code:

| Service | Location |
|---------|----------|
| Google OAuth Client ID | `Shared/Configuration.swift`, `Shared/Services/GoogleCalendarAPI.swift` |
| Gemini API Key | `Shared/Configuration.swift`, `Shared/Services/GeminiSummarizer.swift` |
| Calendar IDs | `Shared/Models/ClientCalendar.swift`, `Shared/Configuration.swift` |
| App Group ID | `Shared/Configuration.swift`, `Shared/Services/AppGroupStore.swift` |

## Testing

### Run on Simulator
1. Select the main app scheme
2. Build and run (⌘R)
3. Sign in with Google
4. Grant calendar permissions
5. Wait for data to load

### Test Widgets
1. Long-press on home screen
2. Tap + to add widget
3. Search for "AMF Schedule"
4. Add "Today" or "Week Ahead" widget

### Debug Background Refresh
In Xcode, use Debug menu → Simulate Background Fetch to test background refresh.

## Troubleshooting

### "App Group not found"
- Ensure App Groups capability is added to both targets
- Verify the identifier matches exactly: `group.Theo.Schedule-Summary-Widget-Nov-26-2025`

### "WeatherKit error"
- Ensure WeatherKit is enabled in Apple Developer portal
- WeatherKit capability added in Xcode
- Device has internet connectivity

### "Google sign-in fails"
- Verify URL scheme is registered in Info.plist
- Check Google Cloud Console OAuth configuration
- Ensure bundle ID matches exactly

### "Widget shows placeholder"
- Open main app and sign in first
- Pull to refresh in main app
- Check that background refresh is enabled

## Calendar Display Order

Calendars appear in this order:
1. **Theo** (primary)
2. **Adam**
3. **Conall**
4. **Hudson**
5. **Ruby**
6. **Tom**
7. **JACK × THEO** (iCloud)

## AMF Editorial Voice

All AI summaries follow these rules:
- Crisp, minimal, smart, observational
- No emojis, no filler, no "friendly AI" tone
- Short declarative sentences
- Character limits: Today ≈320, Week Medium ≈280, Week Large ≈460

