//
//  TimelineView.swift
//  AMFScheduleWidget
//
//  Visual timeline component with hour markers and "Now" line
//  Used in iPad Dayboard and Mac Ambient Agenda widgets
//

import SwiftUI

// Note: Color.init(hex:) is defined in AMFScheduleWidget.swift

// MARK: - Calendar Colors

struct CalendarColors {
    /// Returns a consistent color for a given person/client name
    static func color(for name: String) -> Color {
        // Color mapping for known people
        let colorMap: [String: String] = [
            "Theo": "007AFF",      // Blue
            "Adam": "34C759",      // Green
            "Hudson": "FF9500",    // Orange
            "Tom": "AF52DE",       // Purple
            "Ruby": "FF3B30",      // Red
            "Conall": "5AC8FA",    // Light Blue
            "Leon": "FFCC00",      // Yellow
            "Jack": "FF2D55",      // Pink
        ]
        
        // Return mapped color or generate from name hash
        if let hex = colorMap[name] {
            return Color(hex: hex)
        }
        
        // Generate consistent color from name hash
        let hash = name.hashValue
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
    
    /// Returns the first letter/initial of a person's name
    static func initial(for name: String) -> String {
        guard let firstChar = name.first else { return "?" }
        return String(firstChar).uppercased()
    }
}

// MARK: - Timeline View

struct TimelineView: View {
    let events: [ScheduleEvent]
    let theme: WidgetTheme
    var showNowLine: Bool = true
    var hourRange: ClosedRange<Int> = 6...22  // 6 AM to 10 PM
    
    private let hourHeight: CGFloat = 28
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Hour grid lines
                VStack(spacing: 0) {
                    ForEach(Array(hourRange), id: \.self) { hour in
                        HStack(spacing: 8) {
                            // Hour label
                            Text(formatHour(hour))
                                .font(.custom("HelveticaNeue", size: 9))
                                .foregroundColor(theme.secondaryTextColor.color.opacity(0.6))
                                .frame(width: 32, alignment: .trailing)
                            
                            // Grid line
                            Rectangle()
                                .fill(theme.secondaryTextColor.color.opacity(0.1))
                                .frame(height: 1)
                        }
                        .frame(height: hourHeight)
                    }
                }
                
                // Event blocks
                ForEach(events.filter { !$0.isAllDay }) { event in
                    eventBlock(for: event, in: geometry.size)
                }
                
                // Now line
                if showNowLine {
                    nowLine(in: geometry.size)
                }
            }
        }
        .frame(height: CGFloat(hourRange.count) * hourHeight)
    }
    
    // MARK: - Event Block
    
    private func eventBlock(for event: ScheduleEvent, in size: CGSize) -> some View {
        let startHour = Calendar.current.component(.hour, from: event.startDate)
        let startMinute = Calendar.current.component(.minute, from: event.startDate)
        let endHour = Calendar.current.component(.hour, from: event.endDate)
        let endMinute = Calendar.current.component(.minute, from: event.endDate)
        
        let startOffset = CGFloat(startHour - hourRange.lowerBound) * hourHeight + CGFloat(startMinute) / 60 * hourHeight
        let endOffset = CGFloat(endHour - hourRange.lowerBound) * hourHeight + CGFloat(endMinute) / 60 * hourHeight
        let blockHeight = max(endOffset - startOffset, 18)
        
        let color = CalendarColors.color(for: event.clientName)
        
        return HStack(spacing: 0) {
            // Color bar
            Rectangle()
                .fill(color)
                .frame(width: 3)
            
            // Content
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.custom("HelveticaNeue-Medium", size: 10))
                    .foregroundColor(theme.primaryTextColor.color)
                    .lineLimit(1)
                
                if blockHeight > 30 {
                    HStack(spacing: 4) {
                        Text(event.formattedTime)
                            .font(.custom("HelveticaNeue", size: 8))
                        Text("•")
                            .font(.custom("HelveticaNeue", size: 8))
                        Text(event.clientName)
                            .font(.custom("HelveticaNeue", size: 8))
                    }
                    .foregroundColor(color)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            
            Spacer(minLength: 0)
            
            // Now badge
            if event.isHappeningNow {
                Text("NOW")
                    .font(.custom("HelveticaNeue-Bold", size: 7))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(color)
                    .cornerRadius(3)
                    .padding(.trailing, 4)
            }
        }
        .frame(height: blockHeight)
        .background(color.opacity(event.isPast ? 0.05 : 0.12))
        .cornerRadius(4)
        .opacity(event.isPast ? 0.6 : 1)
        .offset(x: 44, y: max(0, startOffset))
        .frame(width: size.width - 48, alignment: .leading)
    }
    
    // MARK: - Now Line
    
    private func nowLine(in size: CGSize) -> some View {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let minute = Calendar.current.component(.minute, from: now)
        
        guard hourRange.contains(hour) else { return AnyView(EmptyView()) }
        
        let offset = CGFloat(hour - hourRange.lowerBound) * hourHeight + CGFloat(minute) / 60 * hourHeight
        
        return AnyView(
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: "FF3B30"))
                    .frame(width: 8, height: 8)
                
                Rectangle()
                    .fill(Color(hex: "FF3B30"))
                    .frame(height: 2)
            }
            .offset(x: 28, y: offset - 4)
        )
    }
    
    // MARK: - Helpers
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12a" }
        if hour == 12 { return "12p" }
        if hour < 12 { return "\(hour)a" }
        return "\(hour - 12)p"
    }
}

// MARK: - Compact Timeline (for smaller widgets)

struct CompactTimelineView: View {
    let events: [ScheduleEvent]
    let theme: WidgetTheme
    var maxEvents: Int = 6
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(events.prefix(maxEvents).enumerated()), id: \.element.id) { index, event in
                CompactTimelineRow(
                    event: event,
                    isFirst: index == 0,
                    isLast: index == min(events.count, maxEvents) - 1,
                    theme: theme
                )
            }
            
            if events.count > maxEvents {
                HStack {
                    Spacer()
                    Text("+\(events.count - maxEvents) more")
                        .font(.custom("HelveticaNeue", size: 9))
                        .foregroundColor(theme.secondaryTextColor.color)
                }
            }
        }
    }
}

struct CompactTimelineRow: View {
    let event: ScheduleEvent
    let isFirst: Bool
    let isLast: Bool
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 8) {
            // Timeline dot and line
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(theme.secondaryTextColor.color.opacity(0.2))
                        .frame(width: 1, height: 6)
                }
                
                Circle()
                    .fill(event.isHappeningNow ? Color(hex: "FF3B30") : CalendarColors.color(for: event.clientName))
                    .frame(width: 8, height: 8)
                
                if !isLast {
                    Rectangle()
                        .fill(theme.secondaryTextColor.color.opacity(0.2))
                        .frame(width: 1, height: 6)
                }
            }
            
            // Time
            Text(event.isAllDay ? "All day" : event.formattedTime)
                .font(.custom("HelveticaNeue", size: 10))
                .foregroundColor(theme.secondaryTextColor.color)
                .frame(width: 50, alignment: .leading)
            
            // Title
            Text(event.title)
                .font(.custom("HelveticaNeue-Medium", size: 11))
                .foregroundColor(event.isPast ? theme.secondaryTextColor.color : theme.primaryTextColor.color)
                .lineLimit(1)
            
            Spacer()
            
            // Client badge
            Text(event.clientName)
                .font(.custom("HelveticaNeue", size: 9))
                .foregroundColor(CalendarColors.color(for: event.clientName))
        }
        .opacity(event.isPast ? 0.6 : 1)
    }
}

// MARK: - Hour Tick Bar (for Mac widget)

struct HourTickBar: View {
    let theme: WidgetTheme
    var hours: [Int] = [9, 12, 15, 18]  // 9am, 12pm, 3pm, 6pm
    
    var body: some View {
        HStack {
            ForEach(hours, id: \.self) { hour in
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(theme.secondaryTextColor.color.opacity(0.3))
                        .frame(width: 1, height: 6)
                    
                    Text(formatHour(hour))
                        .font(.custom("HelveticaNeue", size: 8))
                        .foregroundColor(theme.secondaryTextColor.color.opacity(0.6))
                }
                
                if hour != hours.last {
                    Spacer()
                }
            }
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 12 { return "12p" }
        if hour < 12 { return "\(hour)a" }
        return "\(hour - 12)p"
    }
}

