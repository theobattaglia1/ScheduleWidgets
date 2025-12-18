# macOS Sandbox Permission Fix

## Problem

The widget extension is getting "Operation not permitted" errors when trying to read files from the App Group container. This is a macOS sandboxing issue.

## Critical Fix: Verify App Group Entitlements

### Step 1: Check Main App Entitlements

1. In Xcode, select the **main app target** ("Schedule Summary Widget Nov 26 2025")
2. Go to **Signing & Capabilities**
3. Verify **App Groups** capability is enabled
4. Verify it contains: `group.Theo.Schedule-Summary-Widget-Nov-26-2025`
5. Check the entitlements file path in **Build Settings** → **Code Signing Entitlements**

### Step 2: Check Mac Extension Entitlements

1. Select **AMFScheduleWidgetMACExtension** target
2. Go to **Signing & Capabilities**
3. **CRITICAL**: Verify **App Groups** capability is enabled
4. **CRITICAL**: Verify it contains: `group.Theo.Schedule-Summary-Widget-Nov-26-2025`
5. Check the entitlements file path in **Build Settings** → **Code Signing Entitlements**
   - Should be: `AMFScheduleWidgetMac/AMFScheduleWidgetMac.entitlements`

### Step 3: Verify Entitlements File Content

Open `AMFScheduleWidgetMac/AMFScheduleWidgetMac.entitlements` and verify it contains:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.Theo.Schedule-Summary-Widget-Nov-26-2025</string>
</array>
```

### Step 4: Clean and Rebuild

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Quit Xcode completely**
3. **Restart Xcode**
4. **Rebuild** both the main app and widget extension

### Step 5: Restart macOS (if still not working)

Sometimes macOS caches entitlements. Try:
1. **Restart your Mac**
2. After restart, rebuild and test again

## Alternative: Check System Console

If the issue persists, check the system console for sandbox violations:

1. Open **Console.app**
2. Filter for your app name or "sandbox"
3. Look for "deny file-read" or "deny file-read-data" messages
4. This will tell you exactly what the sandbox is blocking

## Why This Happens

macOS widget extensions have stricter sandboxing than iOS. The App Group must be:
1. ✅ Properly configured in both app and extension entitlements
2. ✅ Enabled in Signing & Capabilities for both targets
3. ✅ Using the exact same App Group ID (case-sensitive)
4. ✅ Properly code-signed

## If Still Not Working

If you've verified all of the above and it still doesn't work:

1. **Delete the App Group container**:
   ```bash
   rm -rf "/Users/theobattaglia/Library/Group Containers/group.Theo.Schedule-Summary-Widget-Nov-26-2025/"
   ```

2. **Restart the main app** to recreate the container

3. **Test the widget** - it should now be able to read the newly created files

The key issue is that macOS sandboxing is very strict, and the entitlements must be perfectly configured for both the main app and the widget extension.
