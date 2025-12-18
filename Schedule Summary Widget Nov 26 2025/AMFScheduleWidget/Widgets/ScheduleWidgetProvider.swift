//
//  ScheduleWidgetProvider.swift
//  AMFScheduleWidget
//
//  Timeline provider for configurable schedule widgets
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct ScheduleWidgetEntry: TimelineEntry {
    let date: Date
    let viewType: ScheduleViewType
    let todaySummary: TodaySummary
    let weekSummary: WeekSummary
    let sevenDaySummary: String
    let nextWeekSummary: String
    let weather: WeatherData
    let events: [ScheduleEvent]
    let lastRefresh: Date?
    let theme: WidgetTheme
    
    static func placeholder(viewType: ScheduleViewType = .today) -> ScheduleWidgetEntry {
        ScheduleWidgetEntry(
            date: Date(),
            viewType: viewType,
            todaySummary: .placeholder,
            weekSummary: .placeholder,
            sevenDaySummary: "Loading 7-day outlook...",
            nextWeekSummary: "Loading next week...",
            weather: .placeholder,
            events: [],
            lastRefresh: nil,
            theme: .classic
        )
    }
}

// MARK: - Configurable Timeline Provider

struct ScheduleWidgetProvider: AppIntentTimelineProvider {
    
    private let store = AppGroupStore.shared
    private let themeStore = WidgetThemeStore.shared
    
    typealias Entry = ScheduleWidgetEntry
    typealias Intent = ScheduleWidgetConfigIntent
    
    // MARK: - Placeholder
    
    func placeholder(in context: Context) -> ScheduleWidgetEntry {
        .placeholder()
    }
    
    // MARK: - Snapshot
    
    func snapshot(for configuration: ScheduleWidgetConfigIntent, in context: Context) async -> ScheduleWidgetEntry {
        loadCachedEntry(viewType: configuration.viewType)
    }
    
    // MARK: - Timeline
    
    func timeline(for configuration: ScheduleWidgetConfigIntent, in context: Context) async -> Timeline<ScheduleWidgetEntry> {
        // Pre-generate entries for the next 12 hours (one per hour)
        // This ensures the widget updates throughout the day even without new data fetches
        var entries: [ScheduleWidgetEntry] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Load base data once
        let todaySummary = store.loadTodaySummary() ?? .placeholder
        let weekSummary = store.loadWeekSummary() ?? .placeholder
        let weather = store.loadWeather() ?? .placeholder
        let events = store.loadEvents() ?? []
        let lastRefresh = store.loadLastRefreshTime()
        let theme = themeStore.loadTheme(for: configuration.viewType.rawValue)
        
        // Generate an entry for each hour for the next 12 hours
        for hourOffset in 0..<12 {
            guard let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: now) else { continue }
            
            // Round to the top of the hour for cleaner updates
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: entryDate)
            guard let roundedDate = calendar.date(from: components) else { continue }
            
            // Generate view-specific summaries (these update based on "current" time of each entry)
            let sevenDaySummary = generateSevenDaySummary(from: events, asOf: roundedDate)
            let nextWeekSummary = generateNextWeekSummary(from: events, asOf: roundedDate)
            
            let entry = ScheduleWidgetEntry(
                date: roundedDate,
                viewType: configuration.viewType,
                todaySummary: todaySummary,
                weekSummary: weekSummary,
                sevenDaySummary: sevenDaySummary,
                nextWeekSummary: nextWeekSummary,
                weather: weather,
                events: events,
                lastRefresh: lastRefresh,
                theme: theme
            )
            entries.append(entry)
        }
        
        // After 12 hours, ask iOS to request a new timeline
        let refreshDate = calendar.date(byAdding: .hour, value: 12, to: now) ?? now.addingTimeInterval(43200)
        
        return Timeline(entries: entries, policy: .after(refreshDate))
    }
    
    // MARK: - Cache Loading
    
    private func loadCachedEntry(viewType: ScheduleViewType) -> ScheduleWidgetEntry {
        let todaySummary = store.loadTodaySummary() ?? .placeholder
        let weekSummary = store.loadWeekSummary() ?? .placeholder
        let weather = store.loadWeather() ?? .placeholder
        let events = store.loadEvents() ?? []
        let lastRefresh = store.loadLastRefreshTime()
        let theme = themeStore.loadTheme(for: viewType.rawValue)
        
        // Generate view-specific summaries
        let sevenDaySummary = generateSevenDaySummary(from: events)
        let nextWeekSummary = generateNextWeekSummary(from: events)
        
        return ScheduleWidgetEntry(
            date: Date(),
            viewType: viewType,
            todaySummary: todaySummary,
            weekSummary: weekSummary,
            sevenDaySummary: sevenDaySummary,
            nextWeekSummary: nextWeekSummary,
            weather: weather,
            events: events,
            lastRefresh: lastRefresh,
            theme: theme
        )
    }
    
    // MARK: - 5-Day Summary (with asOf date for pre-generation)
    
    private func generateSevenDaySummary(from events: [ScheduleEvent], asOf date: Date = Date()) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 5, to: today)!
        
        let upcomingEvents = events.filter { event in
            event.startDate >= today && event.startDate < endDate
        }
        
        if upcomingEvents.isEmpty {
            return "Clear week ahead. No scheduled events."
        }
        
        // Group by client, Theo first
        let grouped = Dictionary(grouping: upcomingEvents) { $0.clientName }
        let sortedClients = grouped.keys.sorted { client1, client2 in
            if client1 == "Theo" { return true }
            if client2 == "Theo" { return false }
            return client1 < client2
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        
        var parts: [String] = []
        for client in sortedClients.prefix(5) {
            guard let clientEvents = grouped[client] else { continue }
            let days = Set(clientEvents.map { dateFormatter.string(from: $0.startDate) })
            let dayList = days.sorted().joined(separator: ", ")
            parts.append("**\(client)**: \(clientEvents.count) events (\(dayList))")
        }
        
        return parts.joined(separator: ". ") + "."
    }
    
    // MARK: - Next Week Summary (with asOf date for pre-generation)
    
    private func generateNextWeekSummary(from events: [ScheduleEvent], asOf date: Date = Date()) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        
        // Find next Monday from the given date
        var nextMonday = calendar.startOfDay(for: date)
        while calendar.component(.weekday, from: nextMonday) != 2 {
            nextMonday = calendar.date(byAdding: .day, value: 1, to: nextMonday)!
        }
        // If the given date IS Monday, get NEXT Monday
        if calendar.component(.weekday, from: date) == 2 {
            nextMonday = calendar.date(byAdding: .day, value: 7, to: nextMonday)!
        }
        
        let nextSunday = calendar.date(byAdding: .day, value: 7, to: nextMonday)!
        
        let nextWeekEvents = events.filter { event in
            event.startDate >= nextMonday && event.startDate < nextSunday
        }
        
        if nextWeekEvents.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return "Next week (\(dateFormatter.string(from: nextMonday))–\(dateFormatter.string(from: calendar.date(byAdding: .day, value: 6, to: nextMonday)!))): Clear schedule."
        }
        
        // Group by client
        let grouped = Dictionary(grouping: nextWeekEvents) { $0.clientName }
        let sortedClients = grouped.keys.sorted { client1, client2 in
            if client1 == "Theo" { return true }
            if client2 == "Theo" { return false }
            return client1 < client2
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        
        var parts: [String] = []
        for client in sortedClients.prefix(5) {
            guard let clientEvents = grouped[client] else { continue }
            let eventDescs = clientEvents.prefix(2).map { event in
                "\(event.title) \(dateFormatter.string(from: event.startDate))"
            }.joined(separator: ", ")
            parts.append("**\(client)** has \(eventDescs)")
        }
        
        if sortedClients.count > 5 {
            parts.append("+\(sortedClients.count - 5) more clients")
        }
        
        return parts.joined(separator: ". ") + "."
    }
}
