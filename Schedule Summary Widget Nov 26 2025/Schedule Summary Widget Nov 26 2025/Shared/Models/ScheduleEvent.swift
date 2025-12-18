//
//  ScheduleEvent.swift
//  AMF Schedule
//
//  Multi-calendar schedule event model
//

import Foundation

/// Represents a single calendar event from any source (Google Calendar or EventKit)
struct ScheduleEvent: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let notes: String?
    let clientName: String
    let calendarSource: CalendarSource
    
    enum CalendarSource: String, Codable {
        case google
        case icloud
    }
    
    /// Formatted time string (12-hour format)
    var formattedTime: String {
        if isAllDay {
            return "All day"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startDate)
    }
    
    /// Formatted time range
    var formattedTimeRange: String {
        if isAllDay {
            return "All day"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        return "\(start) – \(end)"
    }
    
    /// Duration in minutes
    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }
    
    /// Check if event is happening now
    var isHappeningNow: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    /// Check if event is in the past
    var isPast: Bool {
        endDate < Date()
    }
}

/// Extension for sorting and grouping events
extension Array where Element == ScheduleEvent {
    /// Group events by date
    func groupedByDate() -> [Date: [ScheduleEvent]] {
        let calendar = Calendar.current
        var grouped: [Date: [ScheduleEvent]] = [:]
        
        for event in self {
            let dateKey = calendar.startOfDay(for: event.startDate)
            if grouped[dateKey] != nil {
                grouped[dateKey]?.append(event)
            } else {
                grouped[dateKey] = [event]
            }
        }
        
        return grouped
    }
    
    /// Sort events by start time
    func sortedByTime() -> [ScheduleEvent] {
        sorted { $0.startDate < $1.startDate }
    }
    
    /// Filter to today's events only
    func todayOnly() -> [ScheduleEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return filter { event in
            event.startDate >= today && event.startDate < tomorrow
        }
    }
    
    /// Filter to this week's events (Monday start)
    func thisWeekOnly() -> [ScheduleEvent] {
        let calendar = Calendar(identifier: .gregorian)
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        
        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: Date()) else {
            return []
        }
        
        return filter { event in
            event.startDate >= weekInterval.start && event.startDate < weekInterval.end
        }
    }
    
    /// Filter to next 5 days of events
    func nextFiveDays() -> [ScheduleEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let fiveDaysLater = calendar.date(byAdding: .day, value: 5, to: today) else {
            return []
        }
        
        return filter { event in
            event.startDate >= today && event.startDate < fiveDaysLater
        }
    }
    
    /// Filter to next week's events (Monday-Sunday)
    func nextWeek() -> [ScheduleEvent] {
        let calendar = Calendar(identifier: .gregorian)
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        
        // Find next Monday
        var nextMonday = Date()
        while cal.component(.weekday, from: nextMonday) != 2 {
            nextMonday = cal.date(byAdding: .day, value: 1, to: nextMonday)!
        }
        // If today is Monday, get the following Monday
        if cal.component(.weekday, from: Date()) == 2 {
            nextMonday = cal.date(byAdding: .day, value: 7, to: nextMonday)!
        }
        
        guard let nextSunday = cal.date(byAdding: .day, value: 6, to: nextMonday) else {
            return []
        }
        
        let weekStart = cal.startOfDay(for: nextMonday)
        let weekEnd = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: nextSunday))!
        
        return filter { event in
            event.startDate >= weekStart && event.startDate < weekEnd
        }
    }
}

