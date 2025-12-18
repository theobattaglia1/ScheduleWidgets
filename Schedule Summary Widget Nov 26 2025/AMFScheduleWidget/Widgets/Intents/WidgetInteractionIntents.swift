//
//  WidgetInteractionIntents.swift
//  AMFScheduleWidget
//
//  Interactive App Intents for widget buttons and toggles
//  - Cycle between view types (Today → 5-Day → Next Week)
//  - Day paging (Previous/Next day)
//  - Person filter toggles
//  - View mode toggles (Brief/Agenda/Lanes)
//

import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Widget Interaction State Store

final class WidgetInteractionStore {
    static let shared = WidgetInteractionStore()
    
    private let defaults: UserDefaults?
    private let suiteName = "group.Theo.Schedule-Summary-Widget-Nov-26-2025"
    
    // Keys
    private let viewTypeKey = "widget_viewType"
    private let dayOffsetKey = "widget_dayOffset"
    private let filterPersonKey = "widget_filterPerson"
    private let viewModeKey = "widget_viewMode"
    private let showPastEventsKey = "widget_showPastEvents"
    private let showTravelBuffersKey = "widget_showTravelBuffers"
    
    private init() {
        defaults = UserDefaults(suiteName: suiteName)
    }
    
    // MARK: - View Type
    
    var currentViewType: ScheduleViewType {
        get {
            guard let raw = defaults?.string(forKey: viewTypeKey),
                  let type = ScheduleViewType(rawValue: raw) else {
                return .today
            }
            return type
        }
        set {
            defaults?.set(newValue.rawValue, forKey: viewTypeKey)
        }
    }
    
    func cycleViewType() -> ScheduleViewType {
        let types: [ScheduleViewType] = [.today, .sevenDay, .nextWeek]
        let currentIndex = types.firstIndex(of: currentViewType) ?? 0
        let nextIndex = (currentIndex + 1) % types.count
        currentViewType = types[nextIndex]
        return currentViewType
    }
    
    // MARK: - Day Offset
    
    var dayOffset: Int {
        get { defaults?.integer(forKey: dayOffsetKey) ?? 0 }
        set { defaults?.set(newValue, forKey: dayOffsetKey) }
    }
    
    func nextDay() -> Int {
        dayOffset = min(dayOffset + 1, 7)
        return dayOffset
    }
    
    func previousDay() -> Int {
        dayOffset = max(dayOffset - 1, -7)
        return dayOffset
    }
    
    func resetDayOffset() {
        dayOffset = 0
    }
    
    // MARK: - Person Filter
    
    var filteredPerson: String? {
        get { defaults?.string(forKey: filterPersonKey) }
        set { defaults?.set(newValue, forKey: filterPersonKey) }
    }
    
    func togglePersonFilter(_ person: String) -> String? {
        if filteredPerson == person {
            filteredPerson = nil
        } else {
            filteredPerson = person
        }
        return filteredPerson
    }
    
    func clearPersonFilter() {
        filteredPerson = nil
    }
    
    // MARK: - View Mode
    
    enum ViewMode: String {
        case brief = "brief"
        case agenda = "agenda"
        case lanes = "lanes"
    }
    
    var viewMode: ViewMode {
        get {
            guard let raw = defaults?.string(forKey: viewModeKey),
                  let mode = ViewMode(rawValue: raw) else {
                return .agenda
            }
            return mode
        }
        set {
            defaults?.set(newValue.rawValue, forKey: viewModeKey)
        }
    }
    
    func cycleViewMode() -> ViewMode {
        let modes: [ViewMode] = [.brief, .agenda, .lanes]
        let currentIndex = modes.firstIndex(of: viewMode) ?? 0
        let nextIndex = (currentIndex + 1) % modes.count
        viewMode = modes[nextIndex]
        return viewMode
    }
    
    // MARK: - Toggles
    
    var showPastEvents: Bool {
        get { defaults?.bool(forKey: showPastEventsKey) ?? false }
        set { defaults?.set(newValue, forKey: showPastEventsKey) }
    }
    
    var showTravelBuffers: Bool {
        get { defaults?.bool(forKey: showTravelBuffersKey) ?? false }
        set { defaults?.set(newValue, forKey: showTravelBuffersKey) }
    }
}

// MARK: - Cycle View Type Intent

struct CycleViewTypeIntent: AppIntent {
    static var title: LocalizedStringResource = "Cycle Schedule View"
    static var description = IntentDescription("Switch between Today, 5-Day, and Next Week views")
    
    func perform() async throws -> some IntentResult {
        _ = WidgetInteractionStore.shared.cycleViewType()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Next Day Intent

struct NextDayIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Day"
    static var description = IntentDescription("Move to the next day")
    
    func perform() async throws -> some IntentResult {
        _ = WidgetInteractionStore.shared.nextDay()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Previous Day Intent

struct PreviousDayIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Day"
    static var description = IntentDescription("Move to the previous day")
    
    func perform() async throws -> some IntentResult {
        _ = WidgetInteractionStore.shared.previousDay()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Reset Day Intent

struct ResetDayIntent: AppIntent {
    static var title: LocalizedStringResource = "Back to Today"
    static var description = IntentDescription("Reset view to today")
    
    func perform() async throws -> some IntentResult {
        WidgetInteractionStore.shared.resetDayOffset()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Toggle Person Filter Intent

struct TogglePersonFilterIntent: AppIntent {
    static var title: LocalizedStringResource = "Filter by Person"
    static var description = IntentDescription("Show only events for a specific person")
    
    @Parameter(title: "Person")
    var personName: String
    
    init() {
        self.personName = ""
    }
    
    init(person: String) {
        self.personName = person
    }
    
    func perform() async throws -> some IntentResult {
        _ = WidgetInteractionStore.shared.togglePersonFilter(personName)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Clear Person Filter Intent

struct ClearPersonFilterIntent: AppIntent {
    static var title: LocalizedStringResource = "Show All People"
    static var description = IntentDescription("Clear person filter and show all events")
    
    func perform() async throws -> some IntentResult {
        WidgetInteractionStore.shared.clearPersonFilter()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Cycle View Mode Intent

struct CycleViewModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Cycle View Mode"
    static var description = IntentDescription("Switch between Brief, Agenda, and Lanes views")
    
    func perform() async throws -> some IntentResult {
        _ = WidgetInteractionStore.shared.cycleViewMode()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Toggle Past Events Intent

struct TogglePastEventsIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Past Events"
    static var description = IntentDescription("Show or hide past events")
    
    func perform() async throws -> some IntentResult {
        let store = WidgetInteractionStore.shared
        store.showPastEvents = !store.showPastEvents
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Toggle Travel Buffers Intent

struct ToggleTravelBuffersIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Travel Buffers"
    static var description = IntentDescription("Show or hide travel buffer times")
    
    func perform() async throws -> some IntentResult {
        let store = WidgetInteractionStore.shared
        store.showTravelBuffers = !store.showTravelBuffers
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Request AI Summary Intent

enum AISummaryType: String, AppEnum {
    case nextThreeHours = "next3h"
    case conflicts = "conflicts"
    case prepNow = "prep"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Summary Type"
    
    static var caseDisplayRepresentations: [AISummaryType: DisplayRepresentation] {
        [
            .nextThreeHours: DisplayRepresentation(title: "Next 3 Hours"),
            .conflicts: DisplayRepresentation(title: "Today's Conflicts"),
            .prepNow: DisplayRepresentation(title: "What to Prep Now")
        ]
    }
}

struct RequestAISummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask AI"
    static var description = IntentDescription("Request an AI-generated summary")
    
    @Parameter(title: "Summary Type")
    var summaryType: AISummaryType
    
    init() {
        self.summaryType = .nextThreeHours
    }
    
    init(type: AISummaryType) {
        self.summaryType = type
    }
    
    func perform() async throws -> some IntentResult {
        // Store the request type - the main app will pick it up and generate
        let defaults = UserDefaults(suiteName: "group.Theo.Schedule-Summary-Widget-Nov-26-2025")
        defaults?.set(summaryType.rawValue, forKey: "widget_requestedSummary")
        defaults?.set(Date().timeIntervalSince1970, forKey: "widget_summaryRequestTime")
        
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Interactive Button Views

struct ViewCycleButton: View {
    let currentView: ScheduleViewType
    let theme: WidgetTheme
    
    var body: some View {
        Button(intent: CycleViewTypeIntent()) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 10))
                Text(label)
                    .font(.custom("HelveticaNeue-Medium", size: 9))
            }
            .foregroundColor(theme.accentColor.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.accentColor.color.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private var label: String {
        switch currentView {
        case .today: return "Today"
        case .sevenDay: return "5-Day"
        case .nextWeek: return "Next Week"
        }
    }
    
    private var iconName: String {
        switch currentView {
        case .today: return "sun.max"
        case .sevenDay: return "calendar"
        case .nextWeek: return "calendar.badge.clock"
        }
    }
}

struct DayNavigationButtons: View {
    let dayOffset: Int
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 8) {
            Button(intent: PreviousDayIntent()) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.secondaryTextColor.color)
            }
            .buttonStyle(.plain)
            
            if dayOffset != 0 {
                Button(intent: ResetDayIntent()) {
                    Text("Today")
                        .font(.custom("HelveticaNeue-Medium", size: 9))
                        .foregroundColor(theme.accentColor.color)
                }
                .buttonStyle(.plain)
            } else {
                Text(dayLabel)
                    .font(.custom("HelveticaNeue-Medium", size: 9))
                    .foregroundColor(theme.primaryTextColor.color)
            }
            
            Button(intent: NextDayIntent()) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.secondaryTextColor.color)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var dayLabel: String {
        if dayOffset == 0 { return "Today" }
        if dayOffset == 1 { return "Tomorrow" }
        if dayOffset == -1 { return "Yesterday" }
        
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        return formatter.string(from: date)
    }
}

struct PersonFilterChips: View {
    let people: [String]
    let selectedPerson: String?
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(people.prefix(6), id: \.self) { person in
                Button(intent: TogglePersonFilterIntent(person: person)) {
                    Text(CalendarColors.initial(for: person))
                        .font(.custom("HelveticaNeue-Bold", size: 9))
                        .foregroundColor(selectedPerson == person ? .white : CalendarColors.color(for: person))
                        .frame(width: 20, height: 20)
                        .background(
                            selectedPerson == person
                                ? CalendarColors.color(for: person)
                                : CalendarColors.color(for: person).opacity(0.15)
                        )
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            
            if selectedPerson != nil {
                Button(intent: ClearPersonFilterIntent()) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryTextColor.color)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ViewModeToggle: View {
    let currentMode: WidgetInteractionStore.ViewMode
    let theme: WidgetTheme
    
    var body: some View {
        Button(intent: CycleViewModeIntent()) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 10))
                Text(label)
                    .font(.custom("HelveticaNeue-Medium", size: 9))
            }
            .foregroundColor(theme.secondaryTextColor.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(theme.glassTintColor.opacity(0.06))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
    
    private var label: String {
        switch currentMode {
        case .brief: return "Brief"
        case .agenda: return "Agenda"
        case .lanes: return "Lanes"
        }
    }
    
    private var iconName: String {
        switch currentMode {
        case .brief: return "text.alignleft"
        case .agenda: return "list.bullet"
        case .lanes: return "chart.bar.xaxis"
        }
    }
}

struct AISummaryButtons: View {
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 6) {
            Button(intent: RequestAISummaryIntent(type: .nextThreeHours)) {
                Label("Next 3h", systemImage: "clock")
                    .font(.custom("HelveticaNeue", size: 9))
            }
            .buttonStyle(.plain)
            
            Button(intent: RequestAISummaryIntent(type: .conflicts)) {
                Label("Conflicts", systemImage: "exclamationmark.triangle")
                    .font(.custom("HelveticaNeue", size: 9))
            }
            .buttonStyle(.plain)
            
            Button(intent: RequestAISummaryIntent(type: .prepNow)) {
                Label("Prep", systemImage: "checklist")
                    .font(.custom("HelveticaNeue", size: 9))
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(theme.accentColor.color)
    }
}

