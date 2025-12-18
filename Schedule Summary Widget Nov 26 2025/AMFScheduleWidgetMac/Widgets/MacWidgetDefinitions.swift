//
//  MacWidgetDefinitions.swift
//  AMFScheduleWidgetMac
//
//  Native macOS widget definitions
//  These widgets will appear as separate entries in the macOS widget gallery
//

import SwiftUI
import WidgetKit

// MARK: - Widget Helpers (local workaround)
// macOS-specific implementation (iOS has its own in WidgetDefinitions.swift)
#if os(macOS)
extension View {
    func widgetGlassBackground(theme: WidgetTheme) -> some View {
        modifier(WidgetGlassBackground(theme: theme))
    }
}

private struct WidgetGlassBackground: ViewModifier {
    let theme: WidgetTheme
    
    func body(content: Content) -> some View {
        content
            .containerBackground(for: .widget) {
                backgroundView
            }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if theme.id == "classic" || theme.style == .system {
            Color.black.opacity(0.1)
        } else if theme.style == .light {
            Color.clear
        } else if theme.style == .dark {
            Color.white.opacity(0.05)
        } else {
            theme.accentColor.color.opacity(0.15)
        }
    }
}
#endif

struct MarkdownText: View {
    let text: String
    let fontSize: CGFloat
    let lineLimit: Int?
    let textColor: Color
    
    init(_ text: String, fontSize: CGFloat = 12, lineLimit: Int? = nil, textColor: Color = .black) {
        self.text = text
        self.fontSize = fontSize
        self.lineLimit = lineLimit
        self.textColor = textColor
    }
    
    var body: some View {
        if let attributed = try? AttributedString(markdown: text) {
            Text(attributed)
                .font(.custom("HelveticaNeue", size: fontSize))
                .foregroundColor(textColor)
                .lineSpacing(2)
                .lineLimit(lineLimit)
        } else {
            Text(text)
                .font(.custom("HelveticaNeue", size: fontSize))
                .foregroundColor(textColor)
                .lineSpacing(2)
                .lineLimit(lineLimit)
        }
    }
}

struct CompactEventRow: View {
    let event: ScheduleEvent
    var theme: WidgetTheme = .classic
    
    var body: some View {
        HStack(spacing: 6) {
            // Color indicator matching calendar
            Circle()
                .fill(calendarColor)
                .frame(width: 6, height: 6)
            
            // Time
            Text(event.formattedTime)
                .font(.custom("HelveticaNeue", size: 10))
                .foregroundColor(theme.secondaryTextColor.color)
                .frame(width: 52, alignment: .leading)
            
            // Title + Client combined
            Text(event.title)
                .font(.custom("HelveticaNeue-Medium", size: 10))
                .foregroundColor(event.isPast ? theme.secondaryTextColor.color : theme.primaryTextColor.color)
                .lineLimit(1)
            
            Spacer(minLength: 4)
        }
    }
    
    // Calendar-specific colors
    private var calendarColor: Color {
        switch event.clientName.lowercased() {
        case "theo":
            return Color(red: 0, green: 122/255, blue: 1) // Blue
        case "adam":
            return Color(red: 1, green: 149/255, blue: 0) // Orange
        case "hudson":
            return Color(red: 52/255, green: 199/255, blue: 89/255) // Green
        case "tom":
            return Color(red: 1, green: 59/255, blue: 48/255) // Red
        case "ruby":
            return Color(red: 175/255, green: 82/255, blue: 222/255) // Purple
        case "conall":
            return Color(red: 1, green: 45/255, blue: 85/255) // Pink
        case "leon":
            return Color(red: 88/255, green: 86/255, blue: 214/255) // Indigo
        case "jack × theo", "jack x theo":
            return Color(red: 0, green: 199/255, blue: 190/255) // Teal
        default:
            return Color(red: 142/255, green: 142/255, blue: 147/255) // Gray
        }
    }
}

// MARK: - Mac Ambient Agenda Widget

struct AMFAmbientAgendaWidget: Widget {
    let kind: String = "AMFAmbientAgendaWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ScheduleWidgetConfigIntent.self,
            provider: ScheduleWidgetProvider()
        ) { entry in
            MacAmbientAgendaView(entry: entry, family: .systemMedium)
                .widgetGlassBackground(theme: entry.theme)
        }
        .configurationDisplayName("Ambient Agenda")
        .description("Low-contrast always-visible schedule for your desktop")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Mac Next Up Widget

struct AMFNextUpWidget: Widget {
    let kind: String = "AMFNextUpWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ScheduleWidgetConfigIntent.self,
            provider: ScheduleWidgetProvider()
        ) { entry in
            MacNextUpView(entry: entry, family: .systemMedium)
                .widgetGlassBackground(theme: entry.theme)
        }
        .configurationDisplayName("Next Up")
        .description("Quick glance at your next event and conflicts")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Interactive Schedule Widget

struct AMFInteractiveScheduleWidget: Widget {
    let kind: String = "AMFInteractiveScheduleWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ScheduleWidgetConfigIntent.self,
            provider: ScheduleWidgetProvider()
        ) { entry in
            InteractiveScheduleView(entry: entry)
                .widgetGlassBackground(theme: entry.theme)
        }
        .configurationDisplayName("Interactive Schedule")
        .description("Schedule with navigation and filter controls")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Interactive Schedule View

struct InteractiveScheduleView: View {
    let entry: ScheduleWidgetEntry
    @Environment(\.widgetFamily) var family
    
    private let store = WidgetInteractionStore.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Interactive header
            interactiveHeader
            
            // Content
            switch family {
            case .systemMedium:
                interactiveMediumContent
            case .systemLarge:
                interactiveLargeContent
            default:
                interactiveMediumContent
            }
        }
        .widgetURL(URL(string: "amfschedule://interactive"))
    }
    
    private var interactiveHeader: some View {
        HStack {
            // View type toggle
            ViewCycleButton(currentView: entry.viewType, theme: entry.theme)
            
            Spacer()
            
            // Day navigation
            DayNavigationButtons(dayOffset: store.dayOffset, theme: entry.theme)
            
            Spacer()
            
            // View mode toggle
            ViewModeToggle(currentMode: store.viewMode, theme: entry.theme)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(entry.theme.headerSurface)
    }
    
    private var interactiveMediumContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Person filter chips
            PersonFilterChips(
                people: uniquePeople,
                selectedPerson: store.filteredPerson,
                theme: entry.theme
            )
            .padding(.horizontal, 12)
            
            // Events
            ForEach(filteredEvents.prefix(3)) { event in
                CompactEventRow(event: event, theme: entry.theme)
            }
            .padding(.horizontal, 12)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var interactiveLargeContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Person filter chips
            PersonFilterChips(
                people: uniquePeople,
                selectedPerson: store.filteredPerson,
                theme: entry.theme
            )
            .padding(.horizontal, 12)
            
            // Summary
            if store.viewMode == .brief {
                MarkdownText(entry.todaySummary.summary, fontSize: 11, lineLimit: 3, textColor: entry.theme.primaryTextColor.color)
                    .padding(.horizontal, 12)
            }
            
            // Events or Swimlanes
            if store.viewMode == .lanes {
                SwimlanesView(
                    events: filteredEvents,
                    people: uniquePeople,
                    theme: entry.theme
                )
                .padding(.horizontal, 12)
            } else {
                ForEach(filteredEvents.prefix(6)) { event in
                    CompactEventRow(event: event, theme: entry.theme)
                }
                .padding(.horizontal, 12)
            }
            
            Spacer()
            
            // AI buttons footer
            HStack {
                AISummaryButtons(theme: entry.theme)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 8)
    }
    
    private var uniquePeople: [String] {
        let priority = ["Theo", "Adam", "Hudson", "Tom", "Ruby", "Conall", "Leon"]
        let people = Set(entry.events.map { $0.clientName })
        return Array(people).sorted { p1, p2 in
            let idx1 = priority.firstIndex(of: p1) ?? 999
            let idx2 = priority.firstIndex(of: p2) ?? 999
            return idx1 < idx2
        }
    }
    
    private var filteredEvents: [ScheduleEvent] {
        var events = entry.events.todayOnly().sortedByTime()
        
        // Apply day offset
        if store.dayOffset != 0 {
            let targetDate = Calendar.current.date(byAdding: .day, value: store.dayOffset, to: Date())!
            let dayStart = Calendar.current.startOfDay(for: targetDate)
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
            events = entry.events.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }.sortedByTime()
        }
        
        // Apply person filter
        if let person = store.filteredPerson {
            events = events.filter { $0.clientName == person }
        }
        
        // Apply past events filter
        if !store.showPastEvents {
            events = events.filter { !$0.isPast }
        }
        
        return events
    }
}
