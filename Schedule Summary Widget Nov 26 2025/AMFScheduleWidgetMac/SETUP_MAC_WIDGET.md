# Native macOS Widget Extension Setup

This folder contains a **native macOS widget extension** that will run as true macOS widgets (not Catalyst), giving you:
- ✅ No "From iPhone" label
- ✅ Separate widget entries: "Ambient Agenda", "Next Up", "Interactive Schedule"
- ✅ Full macOS widget capabilities

## Step-by-Step Setup in Xcode

### 1. Add New Widget Extension Target

1. Open your project in Xcode
2. **File** → **New** → **Target...**
3. Select **Widget Extension** (under macOS, not iOS)
4. Click **Next**
5. Configure:
   - **Product Name**: `AMFScheduleWidgetMac`
   - **Team**: Your development team
   - **Organization Identifier**: `Theo`
   - **Bundle Identifier**: `Theo.Schedule-Summary-Widget-Nov-26-2025.AMFScheduleWidgetMac`
   - **Language**: Swift
   - **☑️ Include Configuration Intent** (check this)
6. Click **Finish**

### 2. Delete Auto-Generated Files

Xcode will create some default files. Delete these:
- `AMFScheduleWidgetMacBundle.swift` (we have our own)
- Any default widget view files

### 3. Add Our Files to the Target

1. In Project Navigator, **right-click** on `AMFScheduleWidgetMac` folder
2. Select **"Add Files to 'Schedule Summary Widget Nov 26 2025'..."**
3. Navigate to and add:
   - `AMFScheduleWidgetMac/AMFScheduleWidgetMacBundle.swift`
   - `AMFScheduleWidgetMac/Widgets/MacWidgetDefinitions.swift`
   - `AMFScheduleWidgetMac/Info.plist`
   - `AMFScheduleWidgetMac/AMFScheduleWidgetMac.entitlements`
4. **IMPORTANT**: In the "Add Files" dialog:
   - ☑️ Check **"Copy items if needed"** (unchecked - files are already in place)
   - ☑️ Check **"Create groups"**
   - ☑️ Under **"Add to targets"**, check **"AMFScheduleWidgetMac"** ONLY

### 4. Share Code with iOS Widget Extension

You need to share the widget code between iOS and macOS targets. Add these files to **BOTH** targets:

**From `AMFScheduleWidget/Widgets/`:**
- `ScheduleWidgetProvider.swift`
- `ScheduleWidgetIntent.swift`
- `WeatherClusterView.swift`
- `WidgetDefinitions.swift` (or create a shared version)

**From `AMFScheduleWidget/Widgets/Mac/`:**
- `MacAmbientAgendaWidget.swift`
- `MacNotificationCenterWidget.swift`

**From `AMFScheduleWidget/Widgets/Intents/`:**
- `WidgetInteractionIntents.swift`

**From `AMFScheduleWidget/Widgets/iPad/`:**
- `SwimlanesView.swift` (for interactive widget)
- `TimelineView.swift` (for interactive widget)

**From `Schedule Summary Widget Nov 26 2025/Shared/`:**
- All files in `Models/`
- All files in `Services/`

**How to add to target:**
1. Select each file in Project Navigator
2. Open **File Inspector** (right sidebar, ⌥⌘1)
3. Under **"Target Membership"**, check:
   - ☑️ `AMFScheduleWidgetExtension` (iOS)
   - ☑️ `AMFScheduleWidgetMac` (macOS)

### 5. Configure Target Settings

1. Select **AMFScheduleWidgetMac** target
2. Go to **General** tab:
   - **Deployment Target**: macOS 15.0 (or 14.0 if you need older support)
   - **Embedded Binaries**: Should show the widget extension

3. Go to **Build Settings**:
   - Search for **"Product Bundle Identifier"**
   - Should be: `Theo.Schedule-Summary-Widget-Nov-26-2025.AMFScheduleWidgetMac`

4. Go to **Signing & Capabilities**:
   - **Team**: Your development team
   - **App Groups**: Add `group.Theo.Schedule-Summary-Widget-Nov-26-2025`
   - **WeatherKit**: Enable
   - **Network**: Outgoing Connections (Client)

### 6. Link Entitlements

1. In **Build Settings**, search for **"Code Signing Entitlements"**
2. Set to: `AMFScheduleWidgetMac/AMFScheduleWidgetMac.entitlements`

### 7. Update Info.plist Reference

1. In **Build Settings**, search for **"Info.plist File"**
2. Set to: `AMFScheduleWidgetMac/Info.plist`

### 8. Build and Run

1. Select **"My Mac"** as the destination (not Mac Catalyst)
2. Select **"AMFScheduleWidgetMac"** scheme
3. Build (⌘B)
4. Run (⌘R)

### 9. Add Widgets to Desktop

1. Right-click desktop → **Edit Widgets**
2. You should now see **three separate widgets**:
   - **Ambient Agenda** - Desktop timeline widget
   - **Next Up** - Quick glance widget  
   - **Interactive Schedule** - With buttons

These will **NOT** show "From iPhone" - they're native macOS widgets!

## Troubleshooting

**"No such module" errors:**
- Make sure shared files are added to both iOS and macOS widget targets

**"Widget not appearing":**
- Make sure the bundle identifier is unique
- Clean build folder (⇧⌘K) and rebuild
- Restart your Mac (sometimes needed for widget registry)

**"Code signing errors":**
- Make sure App Group matches between app and widget extension
- Check that entitlements file is properly linked

## File Structure

```
AMFScheduleWidgetMac/
├── AMFScheduleWidgetMacBundle.swift    ← Main bundle (macOS only)
├── AMFScheduleWidgetMac.entitlements   ← macOS entitlements
├── Info.plist                          ← macOS Info.plist
└── Widgets/
    └── MacWidgetDefinitions.swift      ← Widget definitions
```

Shared code (in both targets):
- All widget views from `AMFScheduleWidget/Widgets/Mac/`
- All models and services from `Shared/`
- Provider and Intent files


