# Debugging Widget Load Error

## What is WidgetKit Simulator?

**WidgetKit Simulator is the CORRECT tool** for testing widgets! It's a separate app that lets you preview widgets without running your full app. This is normal and expected.

## Error: "Failed to load widget" (Error 5)

This usually means the widget extension is missing required files or dependencies. Here's how to fix it:

### Step 1: Check Console for Specific Errors

1. In Xcode, open the **Console** (View → Debug Area → Show Debug Area, or ⌘⇧Y)
2. Look for red error messages that tell you what's missing
3. Common errors:
   - "Cannot find type 'X' in scope" → Missing file in target
   - "App Group not found" → Missing entitlements
   - "File not found" → Missing resource file

### Step 2: Verify All Required Files Are in macOS Target

In Xcode, for each file below, check that `AMFScheduleWidgetMACExtension` is checked in Target Membership:

**Critical Files (must have):**
- ✅ `ScheduleWidgetProvider.swift`
- ✅ `ScheduleWidgetIntent.swift`
- ✅ `AppGroupStore.swift`
- ✅ `WidgetThemeStore.swift`
- ✅ All files in `Shared/Models/`
- ✅ `MacAmbientAgendaWidget.swift`
- ✅ `MacNotificationCenterWidget.swift`
- ✅ `MacWidgetDefinitions.swift`
- ✅ `AMFScheduleWidgetMacBundle.swift`

**Supporting Files (for interactive widget):**
- ✅ `WidgetInteractionIntents.swift`
- ✅ `SwimlanesView.swift`
- ✅ `TimelineView.swift`
- ✅ `AMFScheduleWidget.swift` (for shared views like `MarkdownText`, `CompactEventRow`)

### Step 3: Check App Group Configuration

1. Select `AMFScheduleWidgetMACExtension` target
2. Go to **Signing & Capabilities**
3. Verify **App Groups** is enabled with: `group.Theo.Schedule-Summary-Widget-Nov-26-2025`
4. Check the entitlements file has the same App Group ID

### Step 4: Try Loading Widget Again

1. In WidgetKit Simulator, click the **+** button (top right)
2. Search for "Ambient Agenda" or "Next Up"
3. Add the widget
4. If it still fails, check the Console for the specific error

### Step 5: Test with Placeholder Data

The widget should work even without real data - it uses placeholder data. If it still fails, the issue is likely:
- Missing file in target
- Compilation error
- Missing dependency

## Quick Fix Checklist

- [ ] All shared files added to `AMFScheduleWidgetMACExtension` target
- [ ] App Group configured in entitlements
- [ ] No compilation errors (check Issues navigator)
- [ ] Widget bundle has `@main` attribute
- [ ] All widget definitions are accessible

## Still Not Working?

Check the Xcode Console for the exact error message - it will tell you what's missing!


