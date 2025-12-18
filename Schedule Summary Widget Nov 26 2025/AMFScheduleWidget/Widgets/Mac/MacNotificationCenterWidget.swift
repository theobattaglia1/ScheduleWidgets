//
//  MacNotificationCenterWidget.swift
//  AMFScheduleWidget
//
//  Mac Notification Center Widget: "Next Up + Conflicts"
//  Compact, high-signal widget for quick pull-down glance
//  Features: Next event, travel buffer indicator, conflict count
//

import SwiftUI
import WidgetKit

// Note: Color.init(hex:) is defined in AMFScheduleWidget.swift

// MARK: - Notification Center "Next Up" Widget View

struct MacNextUpView: View {
    let entry: ScheduleWidgetEntry
    let family: WidgetFamily
    
    private var theme: WidgetTheme { entry.theme }
    private var events: [ScheduleEvent] { entry.events.todayOnly().sortedByTime() }
    
    var body: some View {
        switch family {
        case .systemSmall:
            nextUpSmall
        case .systemMedium:
            nextUpMedium
        default:
            nextUpMedium
        }
    }
    
    // MARK: - Small: Just next event
    
    private var nextUpSmall: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("NEXT UP")
                    .font(.custom("HelveticaNeue-Bold", size: 9))
                    .foregroundColor(theme.secondaryTextColor.color)
                    .tracking(1)
                
                Spacer()
                
                if conflictCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                        Text("\(conflictCount)")
                            .font(.custom("HelveticaNeue-Bold", size: 9))
                    }
                    .foregroundColor(Color(hex: "FF3B30"))
                }
            }
            
            if let event = nextUpcomingEvent {
                Spacer()
                
                // Event card
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(CalendarColors.color(for: event.clientName))
                            .frame(width: 8, height: 8)
                        
                        Text(event.clientName)
                            .font(.custom("HelveticaNeue-Medium", size: 11))
                            .foregroundColor(CalendarColors.color(for: event.clientName))
                    }
                    
                    Text(event.title)
                        .font(.custom("HelveticaNeue-Medium", size: 14))
                        .foregroundColor(theme.primaryTextColor.color)
                        .lineLimit(2)
                    
                    Text(event.formattedTime)
                        .font(.custom("HelveticaNeue", size: 11))
                        .foregroundColor(theme.secondaryTextColor.color)
                }
                
                Spacer()
                
                // Countdown
                HStack {
                    Spacer()
                    
                    Text(event.isHappeningNow ? "Now" : "in \(timeUntil(event.startDate))")
                        .font(.custom("HelveticaNeue-Bold", size: 12))
                        .foregroundColor(event.isHappeningNow ? Color(hex: "FF3B30") : theme.accentColor.color)
                }
            } else {
                Spacer()
                
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(Color(hex: "34C759"))
                    
                    Text("All clear!")
                        .font(.custom("HelveticaNeue-Medium", size: 12))
                        .foregroundColor(theme.primaryTextColor.color)
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
        }
        .padding(14)
    }
    
    // MARK: - Medium: Next event + 2 more
    
    private var nextUpMedium: some View {
        HStack(spacing: 16) {
            // Left side: Next event (primary)
            VStack(alignment: .leading, spacing: 6) {
                Text("NEXT UP")
                    .font(.custom("HelveticaNeue-Bold", size: 9))
                    .foregroundColor(theme.secondaryTextColor.color)
                    .tracking(1)
                
                if let event = nextUpcomingEvent {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(CalendarColors.color(for: event.clientName))
                                .frame(width: 8, height: 8)
                            
                            Text(event.clientName)
                                .font(.custom("HelveticaNeue-Medium", size: 10))
                                .foregroundColor(CalendarColors.color(for: event.clientName))
                        }
                        
                        Text(event.title)
                            .font(.custom("HelveticaNeue-Medium", size: 13))
                            .foregroundColor(theme.primaryTextColor.color)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Text(event.formattedTime)
                                .font(.custom("HelveticaNeue", size: 10))
                                .foregroundColor(theme.secondaryTextColor.color)
                            
                            Text("•")
                                .foregroundColor(theme.secondaryTextColor.color.opacity(0.5))
                            
                            Text(event.isHappeningNow ? "Now" : "in \(timeUntil(event.startDate))")
                                .font(.custom("HelveticaNeue-Medium", size: 10))
                                .foregroundColor(event.isHappeningNow ? Color(hex: "FF3B30") : theme.accentColor.color)
                        }
                        
                        // Travel buffer indicator (if location exists)
                        if let location = event.location, !location.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 8))
                                Text(location)
                                    .font(.custom("HelveticaNeue", size: 9))
                            }
                            .foregroundColor(theme.secondaryTextColor.color.opacity(0.7))
                            .lineLimit(1)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(Color(hex: "34C759"))
                        
                        Text("All clear for today")
                            .font(.custom("HelveticaNeue", size: 11))
                            .foregroundColor(theme.secondaryTextColor.color)
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right side: Coming up + conflicts
            VStack(alignment: .trailing, spacing: 8) {
                // Conflict badge (more prominent)
                if conflictCount > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                            Text("\(conflictCount)")
                                .font(.custom("HelveticaNeue-Bold", size: 11))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(hex: "FF3B30"))
                        .cornerRadius(4)
                        
                        // Show first conflict preview
                        if let firstConflict = conflicts.first {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(CalendarColors.color(for: firstConflict.0.clientName))
                                    .frame(width: 5, height: 5)
                                Text("↔")
                                    .font(.system(size: 7))
                                Circle()
                                    .fill(CalendarColors.color(for: firstConflict.1.clientName))
                                    .frame(width: 5, height: 5)
                            }
                            .foregroundColor(theme.secondaryTextColor.color.opacity(0.6))
                        }
                    }
                }
                
                // Next 2 events (after the primary one)
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(upcomingEvents.dropFirst().prefix(2)) { event in
                        HStack(spacing: 4) {
                            Text(event.formattedTime)
                                .font(.custom("HelveticaNeue", size: 9))
                                .foregroundColor(theme.secondaryTextColor.color)
                            
                            Circle()
                                .fill(CalendarColors.color(for: event.clientName))
                                .frame(width: 5, height: 5)
                            
                            Text(event.title)
                                .font(.custom("HelveticaNeue", size: 9))
                                .foregroundColor(theme.primaryTextColor.color)
                                .lineLimit(1)
                                .frame(maxWidth: 80, alignment: .trailing)
                        }
                    }
                }
                
                Spacer()
                
                // Today summary
                Text("\(events.count) events today")
                    .font(.custom("HelveticaNeue", size: 9))
                    .foregroundColor(theme.secondaryTextColor.color.opacity(0.6))
            }
            .frame(width: 120)
        }
        .padding(14)
    }
    
    // MARK: - Helpers
    
    private var nextUpcomingEvent: ScheduleEvent? {
        events.first { !$0.isPast }
    }
    
    private var upcomingEvents: [ScheduleEvent] {
        events.filter { !$0.isPast }
    }
    
    /// Count conflicts between different people (not same-person overlapping events)
    private var conflictCount: Int {
        var conflicts: Set<String> = []
        let timedEvents = events.filter { !$0.isAllDay && !$0.isPast }
        
        for i in 0..<timedEvents.count {
            for j in (i+1)..<timedEvents.count {
                let e1 = timedEvents[i]
                let e2 = timedEvents[j]
                
                // Only count conflicts between different people
                if e1.clientName != e2.clientName &&
                   e1.startDate < e2.endDate && e2.startDate < e1.endDate {
                    // Create unique conflict ID
                    let conflictId = [e1.id, e2.id].sorted().joined(separator: "-")
                    conflicts.insert(conflictId)
                }
            }
        }
        return conflicts.count
    }
    
    /// Get conflicts as tuples for display
    private var conflicts: [(ScheduleEvent, ScheduleEvent)] {
        var result: [(ScheduleEvent, ScheduleEvent)] = []
        let timedEvents = events.filter { !$0.isAllDay && !$0.isPast }
        
        for i in 0..<timedEvents.count {
            for j in (i+1)..<timedEvents.count {
                let e1 = timedEvents[i]
                let e2 = timedEvents[j]
                
                // Only conflicts between different people
                if e1.clientName != e2.clientName &&
                   e1.startDate < e2.endDate && e2.startDate < e1.endDate {
                    result.append((e1, e2))
                }
            }
        }
        
        return result.sorted { $0.0.startDate < $1.0.startDate }
    }
    
    private func timeUntil(_ date: Date) -> String {
        let minutes = Int(date.timeIntervalSince(Date()) / 60)
        if minutes < 0 { return "now" }
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }
}

// MARK: - Single Person Focus Widget

struct PersonFocusWidgetView: View {
    let entry: ScheduleWidgetEntry
    let personName: String
    let theme: WidgetTheme
    
    private var personEvents: [ScheduleEvent] {
        entry.events
            .filter { $0.clientName == personName && !$0.isPast }
            .sorted { $0.startDate < $1.startDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Person header
            HStack(spacing: 6) {
                Text(CalendarColors.initial(for: personName))
                    .font(.custom("HelveticaNeue-Bold", size: 12))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(CalendarColors.color(for: personName))
                    .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(personName.uppercased())
                        .font(.custom("HelveticaNeue-Bold", size: 10))
                        .foregroundColor(CalendarColors.color(for: personName))
                        .tracking(1)
                    
                    Text("\(personEvents.count) events today")
                        .font(.custom("HelveticaNeue", size: 9))
                        .foregroundColor(theme.secondaryTextColor.color)
                }
                
                Spacer()
            }
            
            // Events list
            if personEvents.isEmpty {
                Spacer()
                Text("Free today")
                    .font(.custom("HelveticaNeue", size: 11))
                    .foregroundColor(theme.secondaryTextColor.color)
                    .italic()
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(personEvents.prefix(4)) { event in
                        HStack(spacing: 6) {
                            Text(event.isAllDay ? "All day" : event.formattedTime)
                                .font(.custom("HelveticaNeue", size: 9))
                                .foregroundColor(theme.secondaryTextColor.color)
                                .frame(width: 44, alignment: .leading)
                            
                            Text(event.title)
                                .font(.custom("HelveticaNeue-Medium", size: 10))
                                .foregroundColor(theme.primaryTextColor.color)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if event.isHappeningNow {
                                Text("NOW")
                                    .font(.custom("HelveticaNeue-Bold", size: 7))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(CalendarColors.color(for: personName))
                                    .cornerRadius(3)
                            }
                        }
                    }
                    
                    if personEvents.count > 4 {
                        Text("+\(personEvents.count - 4) more")
                            .font(.custom("HelveticaNeue", size: 9))
                            .foregroundColor(theme.secondaryTextColor.color)
                    }
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Quick Stats Widget (for Mac desktop)

struct QuickStatsWidgetView: View {
    let entry: ScheduleWidgetEntry
    let theme: WidgetTheme
    
    private var events: [ScheduleEvent] { entry.events.todayOnly() }
    
    var body: some View {
        HStack(spacing: 16) {
            // Events stat
            StatCard(
                value: "\(events.count)",
                label: "Events",
                icon: "calendar",
                color: theme.accentColor.color,
                theme: theme
            )
            
            // Conflicts stat
            StatCard(
                value: "\(conflictCount)",
                label: "Conflicts",
                icon: "exclamationmark.triangle",
                color: conflictCount > 0 ? Color(hex: "FF3B30") : Color(hex: "34C759"),
                theme: theme
            )
            
            // Free time stat
            StatCard(
                value: freeTimeFormatted,
                label: "Free",
                icon: "clock",
                color: Color(hex: "34C759"),
                theme: theme
            )
        }
        .padding(12)
    }
    
    /// Count conflicts between different people (not same-person overlapping events)
    private var conflictCount: Int {
        var conflicts: Set<String> = []
        let timedEvents = events.filter { !$0.isAllDay && !$0.isPast }
        
        for i in 0..<timedEvents.count {
            for j in (i+1)..<timedEvents.count {
                let e1 = timedEvents[i]
                let e2 = timedEvents[j]
                
                // Only count conflicts between different people
                if e1.clientName != e2.clientName &&
                   e1.startDate < e2.endDate && e2.startDate < e1.endDate {
                    // Create unique conflict ID
                    let conflictId = [e1.id, e2.id].sorted().joined(separator: "-")
                    conflicts.insert(conflictId)
                }
            }
        }
        return conflicts.count
    }
    
    private var freeTimeFormatted: String {
        // Calculate total scheduled time
        let timedEvents = events.filter { !$0.isAllDay }
        var totalMinutes = 0
        for event in timedEvents {
            totalMinutes += event.durationMinutes
        }
        
        // Assume 12 hour working day
        let workdayMinutes = 12 * 60
        let freeMinutes = max(0, workdayMinutes - totalMinutes)
        
        let hours = freeMinutes / 60
        return "\(hours)h"
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let theme: WidgetTheme
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            
            Text(value)
                .font(.custom("HelveticaNeue-Bold", size: 18))
                .foregroundColor(theme.primaryTextColor.color)
            
            Text(label)
                .font(.custom("HelveticaNeue", size: 9))
                .foregroundColor(theme.secondaryTextColor.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(theme.glassTintColor.opacity(0.04))
        .cornerRadius(8)
    }
}


