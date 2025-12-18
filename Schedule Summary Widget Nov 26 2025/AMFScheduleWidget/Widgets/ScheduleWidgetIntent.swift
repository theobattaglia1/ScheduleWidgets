//
//  ScheduleWidgetIntent.swift
//  AMFScheduleWidget
//
//  Configurable widget intent with view type selection
//

import AppIntents
import WidgetKit

// MARK: - View Type Enum

enum ScheduleViewType: String, CaseIterable, AppEnum {
    case today = "today"
    case sevenDay = "sevenDay"
    case nextWeek = "nextWeek"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "View Type"
    }
    
    static var caseDisplayRepresentations: [ScheduleViewType: DisplayRepresentation] {
        [
            .today: DisplayRepresentation(title: "Today", subtitle: "Today's schedule with details"),
            .sevenDay: DisplayRepresentation(title: "5-Day Outlook", subtitle: "Next 5 days for all clients"),
            .nextWeek: DisplayRepresentation(title: "Next Week", subtitle: "Next Monday–Sunday preview")
        ]
    }
}

// MARK: - Widget Configuration Intent

struct ScheduleWidgetConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Schedule View"
    static var description: IntentDescription = IntentDescription("Choose which schedule view to display")
    
    @Parameter(title: "View Type", default: .today)
    var viewType: ScheduleViewType
    
    init() {}
    
    init(viewType: ScheduleViewType) {
        self.viewType = viewType
    }
}
