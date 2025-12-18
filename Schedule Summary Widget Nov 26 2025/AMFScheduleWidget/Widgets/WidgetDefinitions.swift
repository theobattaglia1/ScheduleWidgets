//
//  WidgetDefinitions.swift
//  AMFScheduleWidget
//
//  Additional widget definitions for iPad and Mac
//  Note: AMFScheduleWidget, MarkdownText, WidgetGlassBackground are defined in AMFScheduleWidget.swift
//

import SwiftUI
import WidgetKit

// Note: widgetGlassBackground extension is defined in AMFScheduleWidget.swift

// MARK: - Lock Screen Widget (iPhone + iPad)

#if os(iOS)
struct AMFLockScreenWidget: Widget {
    let kind: String = "AMFLockScreenWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ScheduleWidgetConfigIntent.self,
            provider: ScheduleWidgetProvider()
        ) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Schedule")
        .description("See your next event at a glance")
        .supportedFamilies([
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCircular
        ])
    }
}

struct LockScreenWidgetView: View {
    let entry: ScheduleWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        default:
            AccessoryRectangularView(entry: entry)
        }
    }
}
#endif

// MARK: - iPad Dayboard Widget (Extra Large)

#if os(iOS)
struct AMFDayboardWidget: Widget {
    let kind: String = "AMFDayboardWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ScheduleWidgetConfigIntent.self,
            provider: ScheduleWidgetProvider()
        ) { entry in
            iPadDayboardView(entry: entry)
                .widgetGlassBackground(theme: entry.theme)
        }
        .configurationDisplayName("Dayboard")
        .description("Full schedule dashboard with timeline and people swimlanes")
        .supportedFamilies([.systemExtraLarge])
    }
}

struct iPadDayboardView: View {
    let entry: ScheduleWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        // Use the appropriate ExtraLarge view based on view type
        // These views are defined in AMFScheduleWidget.swift
        #if os(iOS)
        switch entry.viewType {
        case .today:
            TodayExtraLargeView(entry: entry)
        case .sevenDay:
            SevenDayExtraLargeView(entry: entry)
        case .nextWeek:
            NextWeekExtraLargeView(entry: entry)
        }
        #else
        // Placeholder for non-iOS platforms (should not be used)
        Text("Dayboard not available")
        #endif
    }
}
#endif

// Note: Mac-specific widgets (AMFAmbientAgendaWidget, AMFNextUpWidget, AMFInteractiveScheduleWidget)
// are defined in MacWidgetDefinitions.swift, which is only included in the macOS target.
