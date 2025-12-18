#!/bin/bash

# Simple script to check which files exist and should be in macOS widget target

echo "🔍 Checking files for macOS widget target..."
echo "=============================================="
echo ""

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Files that SHOULD be in AMFScheduleWidgetMACExtension target
declare -a REQUIRED_FILES=(
    "AMFScheduleWidget/Widgets/ScheduleWidgetProvider.swift"
    "AMFScheduleWidget/Widgets/ScheduleWidgetIntent.swift"
    "AMFScheduleWidget/Widgets/WeatherClusterView.swift"
    "AMFScheduleWidget/Widgets/AMFScheduleWidget.swift"
    "AMFScheduleWidgetMAC/AMFScheduleWidgetMacBundle.swift"
    "AMFScheduleWidgetMAC/Widgets/MacWidgetDefinitions.swift"
    "AMFScheduleWidget/Widgets/Mac/MacAmbientAgendaWidget.swift"
    "AMFScheduleWidget/Widgets/Mac/MacNotificationCenterWidget.swift"
    "AMFScheduleWidget/Widgets/Intents/WidgetInteractionIntents.swift"
    "AMFScheduleWidget/Widgets/iPad/SwimlanesView.swift"
    "AMFScheduleWidget/Widgets/iPad/TimelineView.swift"
    "Schedule Summary Widget Nov 26 2025/Shared/Models/ScheduleEvent.swift"
    "Schedule Summary Widget Nov 26 2025/Shared/Models/ClientCalendar.swift"
    "Schedule Summary Widget Nov 26 2025/Shared/Models/Summaries.swift"
    "Schedule Summary Widget Nov 26 2025/Shared/Models/WeatherModel.swift"
    "Schedule Summary Widget Nov 26 2025/Shared/Models/WidgetTheme.swift"
    "Schedule Summary Widget Nov 26 2025/Shared/Services/AppGroupStore.swift"
    "Schedule Summary Widget Nov 26 2025/Shared/Services/WidgetThemeStore.swift"
    "Schedule Summary Widget Nov 26 2025/Shared/Services/CalendarService.swift"
    "Schedule Summary Widget Nov 26 2025/Shared/Services/WeatherService.swift"
    "Schedule Summary Widget Nov 26 2025/Shared/Services/GeminiSummarizer.swift"
    "Schedule Summary Widget Nov 26 2025/Shared/Services/GoogleCalendarAPI.swift"
)

echo "📋 FILES THAT SHOULD BE IN AMFScheduleWidgetMACExtension TARGET:"
echo ""
echo "Total files to check: ${#REQUIRED_FILES[@]}"
echo ""

EXISTS=0
MISSING=0

for file in "${REQUIRED_FILES[@]}"; do
    full_path="$PROJECT_DIR/$file"
    if [ -f "$full_path" ]; then
        echo "✅ $file"
        ((EXISTS++))
    else
        echo "❌ $file (FILE NOT FOUND)"
        ((MISSING++))
    fi
done

echo ""
echo "=============================================="
echo "📊 SUMMARY:"
echo "   ✅ Files that exist: $EXISTS"
echo "   ❌ Files not found: $MISSING"
echo ""
echo "💡 NEXT STEPS:"
echo "   1. In Xcode, select each file above"
echo "   2. Press ⌥⌘1 (File Inspector)"
echo "   3. Under 'Target Membership', check 'AMFScheduleWidgetMACExtension'"
echo ""
echo "   Or use Xcode's 'Add Files' dialog to add multiple files at once:"
echo "   - Select multiple files (⌘-click)"
echo "   - Right-click → 'Add Files to...'"
echo "   - Check 'AMFScheduleWidgetMACExtension' target"
echo ""


