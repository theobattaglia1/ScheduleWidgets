# App Group Permissions Fix

## Problem

The widget extension is getting "Operation not permitted" errors when trying to read files from the App Group container. This is a macOS sandboxing/permissions issue.

## Solution Applied

1. **Code Fix**: Updated `AppGroupStore.swift` to set proper file permissions when writing files (0o644 for files, 0o755 for directories)
2. **Manual Fix**: Run this command to fix existing files:
   ```bash
   chmod -R u+rwX,go+rX "/Users/theobattaglia/Library/Group Containers/group.Theo.Schedule-Summary-Widget-Nov-26-2025/"
   ```

## Verify Entitlements in Xcode

Make sure the Mac extension has the App Group properly configured:

1. Select **AMFScheduleWidgetMACExtension** target
2. Go to **Signing & Capabilities**
3. Verify **App Groups** capability is enabled
4. Verify it contains: `group.Theo.Schedule-Summary-Widget-Nov-26-2025`
5. Check that the entitlements file is properly linked in **Build Settings** → **Code Signing Entitlements**

## After Fixing

1. **Restart the main app** to regenerate files with proper permissions
2. **Restart the widget extension** (or rebuild)
3. The widget should now be able to read the files

## If Still Not Working

If you still get permission errors:

1. Check that both the main app and widget extension have the same App Group ID in their entitlements
2. Verify the App Group is enabled in both targets' Signing & Capabilities
3. Try deleting and recreating the App Group container:
   ```bash
   rm -rf "/Users/theobattaglia/Library/Group Containers/group.Theo.Schedule-Summary-Widget-Nov-26-2025/"
   ```
   Then restart the app to recreate it with proper permissions.
