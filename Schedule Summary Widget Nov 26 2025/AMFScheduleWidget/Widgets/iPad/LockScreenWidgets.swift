//
//  LockScreenWidgets.swift
//  AMFScheduleWidget
//
//  Lock Screen accessory widgets for iPad (iOS 16+)
//  - Inline: "HUDSON • 4:30 Session • 22m"
//  - Rectangular: Next 2 events + temperature
//  - Circular: Ring countdown to next hard start
//

import SwiftUI
import WidgetKit

// MARK: - Accessory Inline Widget View

struct AccessoryInlineView: View {
    let entry: ScheduleWidgetEntry
    
    private var nextEvent: ScheduleEvent? {
        entry.events
            .filter { !$0.isPast && !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .first
    }
    
    var body: some View {
        if let event = nextEvent {
            HStack(spacing: 4) {
                // Person indicator
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                
                Text(event.clientName.uppercased())
                    .font(.custom("HelveticaNeue-Bold", size: 12))
                
                Text("•")
                
                Text(event.formattedTime)
                    .font(.custom("HelveticaNeue", size: 12))
                
                Text(event.title)
                    .font(.custom("HelveticaNeue", size: 12))
                    .lineLimit(1)
                
                Text("•")
                
                Text(timeUntil(event.startDate))
                    .font(.custom("HelveticaNeue-Medium", size: 12))
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text("No upcoming events")
                    .font(.custom("HelveticaNeue", size: 12))
            }
        }
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

// MARK: - Accessory Rectangular Widget View

struct AccessoryRectangularView: View {
    let entry: ScheduleWidgetEntry
    
    private var upcomingEvents: [ScheduleEvent] {
        entry.events
            .filter { !$0.isPast && !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Left side: Events
            VStack(alignment: .leading, spacing: 3) {
                ForEach(upcomingEvents.prefix(2)) { event in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(CalendarColors.color(for: event.clientName))
                            .frame(width: 6, height: 6)
                        
                        Text(event.formattedTime)
                            .font(.custom("HelveticaNeue", size: 10))
                        
                        Text(event.title)
                            .font(.custom("HelveticaNeue-Medium", size: 10))
                            .lineLimit(1)
                    }
                }
                
                if upcomingEvents.isEmpty {
                    Text("No events")
                        .font(.custom("HelveticaNeue", size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Right side: Weather
            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: entry.weather.symbolName)
                    .font(.system(size: 16))
                
                Text(entry.weather.temperatureFormatted)
                    .font(.custom("HelveticaNeue-Medium", size: 12))
            }
        }
    }
}

// MARK: - Accessory Circular Widget View

struct AccessoryCircularView: View {
    let entry: ScheduleWidgetEntry
    
    private var nextEvent: ScheduleEvent? {
        entry.events
            .filter { !$0.isPast && !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .first
    }
    
    var body: some View {
        if let event = nextEvent {
            ZStack {
                // Progress ring
                AccessoryWidgetBackground()
                
                // Countdown ring
                Circle()
                    .trim(from: 0, to: progressUntil(event.startDate))
                    .stroke(
                        CalendarColors.color(for: event.clientName),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(2)
                
                // Center content
                VStack(spacing: 0) {
                    Text(CalendarColors.initial(for: event.clientName))
                        .font(.custom("HelveticaNeue-Bold", size: 12))
                    
                    Text(timeUntilShort(event.startDate))
                        .font(.custom("HelveticaNeue", size: 10))
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                
                VStack(spacing: 0) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Free")
                        .font(.custom("HelveticaNeue", size: 10))
                }
            }
        }
    }
    
    private func progressUntil(_ date: Date) -> CGFloat {
        let totalSeconds = date.timeIntervalSince(Date())
        if totalSeconds < 0 { return 1 }
        
        // Full circle = 60 minutes
        let progress = 1 - min(totalSeconds / 3600, 1)
        return CGFloat(progress)
    }
    
    private func timeUntilShort(_ date: Date) -> String {
        let minutes = Int(date.timeIntervalSince(Date()) / 60)
        if minutes < 0 { return "now" }
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h"
    }
}

// MARK: - Accessory Corner Widget View

struct AccessoryCornerView: View {
    let entry: ScheduleWidgetEntry
    
    private var eventCount: Int {
        entry.events.filter { !$0.isPast }.count
    }
    
    private var conflictCount: Int {
        detectConflicts().count
    }
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 2) {
                Text("\(eventCount)")
                    .font(.custom("HelveticaNeue-Bold", size: 20))
                
                Text("events")
                    .font(.custom("HelveticaNeue", size: 8))
            }
        }
        .widgetLabel {
            if conflictCount > 0 {
                Label("\(conflictCount) conflicts", systemImage: "exclamationmark.triangle")
            } else {
                Label("Today", systemImage: "calendar")
            }
        }
    }
    
    private func detectConflicts() -> [(String, String)] {
        var conflicts: [(String, String)] = []
        let timedEvents = entry.events.filter { !$0.isAllDay && !$0.isPast }
        
        for i in 0..<timedEvents.count {
            for j in (i+1)..<timedEvents.count {
                let e1 = timedEvents[i]
                let e2 = timedEvents[j]
                
                if e1.startDate < e2.endDate && e2.startDate < e1.endDate {
                    conflicts.append((e1.clientName, e2.clientName))
                }
            }
        }
        
        return conflicts
    }
}

// MARK: - Conflicts Badge Widget (Rectangular)

struct ConflictsBadgeView: View {
    let entry: ScheduleWidgetEntry
    
    private var conflicts: [(ScheduleEvent, ScheduleEvent)] {
        var result: [(ScheduleEvent, ScheduleEvent)] = []
        let timedEvents = entry.events.filter { !$0.isAllDay && !$0.isPast }.sortedByTime()
        
        for i in 0..<timedEvents.count {
            for j in (i+1)..<timedEvents.count {
                let e1 = timedEvents[i]
                let e2 = timedEvents[j]
                
                if e1.startDate < e2.endDate && e2.startDate < e1.endDate {
                    result.append((e1, e2))
                }
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: conflicts.isEmpty ? "checkmark.circle" : "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(conflicts.isEmpty ? .green : .red)
                
                Text(conflicts.isEmpty ? "No Conflicts" : "\(conflicts.count) Conflicts")
                    .font(.custom("HelveticaNeue-Bold", size: 11))
            }
            
            if let firstConflict = conflicts.first {
                HStack(spacing: 4) {
                    Circle()
                        .fill(CalendarColors.color(for: firstConflict.0.clientName))
                        .frame(width: 6, height: 6)
                    
                    Text("↔")
                        .font(.system(size: 8))
                    
                    Circle()
                        .fill(CalendarColors.color(for: firstConflict.1.clientName))
                        .frame(width: 6, height: 6)
                    
                    Text("at \(firstConflict.0.formattedTime)")
                        .font(.custom("HelveticaNeue", size: 9))
                }
            }
        }
    }
}

// MARK: - Countdown to Next Event (Circular)

struct NextEventCountdownView: View {
    let entry: ScheduleWidgetEntry
    
    private var nextEvent: ScheduleEvent? {
        entry.events
            .filter { !$0.isPast && !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .first
    }
    
    var body: some View {
        Gauge(value: gaugeProgress) {
            if let event = nextEvent {
                VStack(spacing: 0) {
                    Text(timeUntilShort(event.startDate))
                        .font(.custom("HelveticaNeue-Bold", size: 14))
                }
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 16))
            }
        }
        .gaugeStyle(.accessoryCircular)
        .tint(nextEvent.map { CalendarColors.color(for: $0.clientName) } ?? .green)
    }
    
    private var gaugeProgress: Double {
        guard let event = nextEvent else { return 1 }
        let totalSeconds = event.startDate.timeIntervalSince(Date())
        if totalSeconds < 0 { return 1 }
        return 1 - min(totalSeconds / 3600, 1)
    }
    
    private func timeUntilShort(_ date: Date) -> String {
        let minutes = Int(date.timeIntervalSince(Date()) / 60)
        if minutes < 0 { return "now" }
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h"
    }
}

// MARK: - Weather + First Event (Rectangular)

struct WeatherFirstEventView: View {
    let entry: ScheduleWidgetEntry
    
    private var nextEvent: ScheduleEvent? {
        entry.events
            .filter { !$0.isPast }
            .sorted { $0.startDate < $1.startDate }
            .first
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Weather
            VStack(spacing: 2) {
                Image(systemName: entry.weather.symbolName)
                    .font(.system(size: 18))
                
                Text(entry.weather.temperatureFormatted)
                    .font(.custom("HelveticaNeue-Medium", size: 11))
            }
            
            // Divider
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(width: 1)
            
            // Next Event
            VStack(alignment: .leading, spacing: 2) {
                if let event = nextEvent {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(CalendarColors.color(for: event.clientName))
                            .frame(width: 6, height: 6)
                        
                        Text(event.clientName)
                            .font(.custom("HelveticaNeue-Bold", size: 10))
                    }
                    
                    Text(event.title)
                        .font(.custom("HelveticaNeue", size: 10))
                        .lineLimit(1)
                    
                    Text(event.formattedTime)
                        .font(.custom("HelveticaNeue", size: 9))
                        .foregroundColor(.secondary)
                } else {
                    Text("No events")
                        .font(.custom("HelveticaNeue", size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

