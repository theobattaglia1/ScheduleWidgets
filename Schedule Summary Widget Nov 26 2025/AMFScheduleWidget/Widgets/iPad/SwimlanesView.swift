//
//  SwimlanesView.swift
//  AMFScheduleWidget
//
//  Multi-person swimlane visualization showing who is busy when
//  Each person gets a horizontal row with event bars on a shared time axis
//

import SwiftUI

// Note: Color.init(hex:) is defined in AMFScheduleWidget.swift

// MARK: - Swimlanes View

struct SwimlanesView: View {
    let events: [ScheduleEvent]
    let people: [String]
    let theme: WidgetTheme
    var hourRange: ClosedRange<Int> = 7...20  // 7 AM to 8 PM
    
    private let rowHeight: CGFloat = 24
    private let labelWidth: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            // Time axis header
            timeAxisHeader
                .padding(.leading, labelWidth)
            
            // Person rows
            ForEach(people, id: \.self) { person in
                swimlaneRow(for: person)
            }
        }
    }
    
    // MARK: - Time Axis Header
    
    private var timeAxisHeader: some View {
        GeometryReader { geometry in
            let totalHours = CGFloat(hourRange.count)
            let hourWidth = geometry.size.width / totalHours
            
            HStack(spacing: 0) {
                ForEach(Array(stride(from: hourRange.lowerBound, through: hourRange.upperBound, by: 3)), id: \.self) { hour in
                    Text(formatHour(hour))
                        .font(.custom("HelveticaNeue", size: 8))
                        .foregroundColor(theme.secondaryTextColor.color.opacity(0.6))
                        .frame(width: hourWidth * 3, alignment: .leading)
                }
            }
        }
        .frame(height: 14)
    }
    
    // MARK: - Swimlane Row
    
    private func swimlaneRow(for person: String) -> some View {
        let personEvents = events.filter { $0.clientName == person && !$0.isAllDay }
        let color = CalendarColors.color(for: person)
        
        return HStack(spacing: 4) {
            // Person label
            HStack(spacing: 3) {
                Text(CalendarColors.initial(for: person))
                    .font(.custom("HelveticaNeue-Bold", size: 8))
                    .foregroundColor(.white)
                    .frame(width: 14, height: 14)
                    .background(color)
                    .cornerRadius(3)
                
                Text(String(person.prefix(3)))
                    .font(.custom("HelveticaNeue", size: 8))
                    .foregroundColor(theme.secondaryTextColor.color)
            }
            .frame(width: labelWidth, alignment: .leading)
            
            // Event bars
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(theme.secondaryTextColor.color.opacity(0.05))
                        .cornerRadius(3)
                    
                    // Now indicator
                    nowIndicator(in: geometry.size)
                    
                    // Event bars
                    ForEach(personEvents) { event in
                        eventBar(for: event, color: color, in: geometry.size)
                    }
                }
            }
        }
        .frame(height: rowHeight)
    }
    
    // MARK: - Event Bar
    
    private func eventBar(for event: ScheduleEvent, color: Color, in size: CGSize) -> some View {
        let startHour = Calendar.current.component(.hour, from: event.startDate)
        let startMinute = Calendar.current.component(.minute, from: event.startDate)
        let endHour = Calendar.current.component(.hour, from: event.endDate)
        let endMinute = Calendar.current.component(.minute, from: event.endDate)
        
        let totalHours = CGFloat(hourRange.count)
        let hourWidth = size.width / totalHours
        
        let startFraction = CGFloat(startHour - hourRange.lowerBound) + CGFloat(startMinute) / 60
        let endFraction = CGFloat(endHour - hourRange.lowerBound) + CGFloat(endMinute) / 60
        
        let xOffset = startFraction * hourWidth
        let barWidth = max((endFraction - startFraction) * hourWidth, 8)
        
        return Rectangle()
            .fill(color.opacity(event.isPast ? 0.3 : 0.8))
            .frame(width: barWidth, height: rowHeight - 6)
            .cornerRadius(3)
            .overlay(
                // Conflict indicator (flash if overlapping with another person)
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color(hex: "FF3B30"), lineWidth: isConflicting(event) ? 2 : 0)
            )
            .offset(x: xOffset, y: 3)
    }
    
    // MARK: - Now Indicator
    
    private func nowIndicator(in size: CGSize) -> some View {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let minute = Calendar.current.component(.minute, from: now)
        
        guard hourRange.contains(hour) else { return AnyView(EmptyView()) }
        
        let totalHours = CGFloat(hourRange.count)
        let hourWidth = size.width / totalHours
        let fraction = CGFloat(hour - hourRange.lowerBound) + CGFloat(minute) / 60
        let xOffset = fraction * hourWidth
        
        return AnyView(
            Rectangle()
                .fill(Color(hex: "FF3B30").opacity(0.3))
                .frame(width: 2)
                .offset(x: xOffset)
        )
    }
    
    // MARK: - Helpers
    
    private func isConflicting(_ event: ScheduleEvent) -> Bool {
        // Check if this event overlaps with any other person's event
        let otherEvents = events.filter { $0.clientName != event.clientName && !$0.isAllDay }
        return otherEvents.contains { other in
            event.startDate < other.endDate && other.startDate < event.endDate
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 12 { return "12p" }
        if hour < 12 { return "\(hour)a" }
        return "\(hour - 12)p"
    }
}

// MARK: - Conflict Matrix View

struct ConflictMatrixView: View {
    let events: [ScheduleEvent]
    let people: [String]
    let theme: WidgetTheme
    
    var body: some View {
        let conflicts = calculateConflicts()
        
        VStack(alignment: .leading, spacing: 8) {
            Text("OVERLAPS")
                .font(.custom("HelveticaNeue-Bold", size: 9))
                .foregroundColor(theme.secondaryTextColor.color)
                .tracking(0.5)
            
            if conflicts.isEmpty {
                Text("No conflicts today")
                    .font(.custom("HelveticaNeue", size: 10))
                    .foregroundColor(theme.secondaryTextColor.color.opacity(0.7))
                    .italic()
            } else {
                VStack(spacing: 4) {
                    ForEach(conflicts.prefix(4), id: \.id) { conflict in
                        ConflictMatrixRow(conflict: conflict, theme: theme)
                    }
                    
                    if conflicts.count > 4 {
                        Text("+\(conflicts.count - 4) more")
                            .font(.custom("HelveticaNeue", size: 9))
                            .foregroundColor(theme.secondaryTextColor.color)
                    }
                }
            }
        }
        .padding(12)
        .background(theme.glassTintColor.opacity(0.04))
        .cornerRadius(8)
    }
    
    private func calculateConflicts() -> [ConflictInfo] {
        var conflicts: [ConflictInfo] = []
        let timedEvents = events.filter { !$0.isAllDay }
        
        for i in 0..<timedEvents.count {
            for j in (i+1)..<timedEvents.count {
                let e1 = timedEvents[i]
                let e2 = timedEvents[j]
                
                // Different people and overlapping
                if e1.clientName != e2.clientName &&
                   e1.startDate < e2.endDate && e2.startDate < e1.endDate {
                    let overlapStart = max(e1.startDate, e2.startDate)
                    let overlapEnd = min(e1.endDate, e2.endDate)
                    let minutes = Int(overlapEnd.timeIntervalSince(overlapStart) / 60)
                    
                    conflicts.append(ConflictInfo(
                        id: "\(e1.id)-\(e2.id)",
                        person1: e1.clientName,
                        person2: e2.clientName,
                        event1Title: e1.title,
                        event2Title: e2.title,
                        overlapStart: overlapStart,
                        overlapMinutes: minutes
                    ))
                }
            }
        }
        
        return conflicts.sorted { $0.overlapStart < $1.overlapStart }
    }
}

struct ConflictInfo: Identifiable {
    let id: String
    let person1: String
    let person2: String
    let event1Title: String
    let event2Title: String
    let overlapStart: Date
    let overlapMinutes: Int
}

struct ConflictMatrixRow: View {
    let conflict: ConflictInfo
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 6) {
            // Person indicators
            HStack(spacing: 2) {
                Circle()
                    .fill(CalendarColors.color(for: conflict.person1))
                    .frame(width: 8, height: 8)
                
                Text("↔")
                    .font(.system(size: 8))
                    .foregroundColor(Color(hex: "FF3B30"))
                
                Circle()
                    .fill(CalendarColors.color(for: conflict.person2))
                    .frame(width: 8, height: 8)
            }
            
            // Time
            Text(formatTime(conflict.overlapStart))
                .font(.custom("HelveticaNeue", size: 9))
                .foregroundColor(theme.secondaryTextColor.color)
                .frame(width: 44, alignment: .leading)
            
            // Duration badge
            Text("\(conflict.overlapMinutes)m")
                .font(.custom("HelveticaNeue-Bold", size: 8))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color(hex: "FF3B30"))
                .cornerRadius(3)
            
            Spacer()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Family Radar View (Alternative conflict visualization)

struct FamilyRadarView: View {
    let events: [ScheduleEvent]
    let theme: WidgetTheme
    
    private var people: [String] {
        Array(Set(events.map { $0.clientName })).sorted()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // People chips row
            HStack(spacing: 6) {
                ForEach(people, id: \.self) { person in
                    PersonBusyChip(
                        person: person,
                        events: events.filter { $0.clientName == person },
                        theme: theme
                    )
                }
            }
            
            // Main radar area
            SwimlanesView(
                events: events,
                people: people,
                theme: theme
            )
            
            // Hot spots summary
            ConflictMatrixView(
                events: events,
                people: people,
                theme: theme
            )
        }
    }
}

struct PersonBusyChip: View {
    let person: String
    let events: [ScheduleEvent]
    let theme: WidgetTheme
    
    private var color: Color {
        CalendarColors.color(for: person)
    }
    
    private var isBusyNow: Bool {
        events.contains { $0.isHappeningNow }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Initial badge
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                
                Text(CalendarColors.initial(for: person))
                    .font(.custom("HelveticaNeue-Bold", size: 12))
                    .foregroundColor(.white)
                
                // Busy indicator
                if isBusyNow {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    Circle()
                        .fill(Color(hex: "FF3B30"))
                        .frame(width: 8, height: 8)
                        .offset(x: 10, y: -10)
                }
            }
            
            Text(String(person.prefix(4)))
                .font(.custom("HelveticaNeue", size: 8))
                .foregroundColor(theme.secondaryTextColor.color)
            
            Text("\(events.count)")
                .font(.custom("HelveticaNeue-Bold", size: 8))
                .foregroundColor(color)
        }
    }
}


