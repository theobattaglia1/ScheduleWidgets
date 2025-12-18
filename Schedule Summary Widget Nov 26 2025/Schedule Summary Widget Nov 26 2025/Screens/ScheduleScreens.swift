//
//  ScheduleScreens.swift
//  AMF Schedule
//
//  Main screen views for deep link navigation destinations
//  These views match the widget view types and provide the full app experience
//

import SwiftUI

// MARK: - Today Screen

/// Full-screen Today view accessible via deep links
struct TodayScreen: View {
    @EnvironmentObject var viewModel: ScheduleViewModel
    @EnvironmentObject var router: AppRouter
    
    private let date: Date
    
    init(date: Date = Date()) {
        self.date = date
    }
    
    private var todayEvents: [ScheduleEvent] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: targetDay) else {
            return []
        }
        
        return (viewModel.events ?? [])
            .filter { $0.startDate >= targetDay && $0.startDate < nextDay }
            .sorted { $0.startDate < $1.startDate }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(isToday ? "TODAY" : formattedWeekday.uppercased())
                        .font(.custom("HelveticaNeue-Bold", size: 11))
                        .foregroundStyle(.secondary)
                        .tracking(2)
                    
                    Text(formattedDate)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    if let weather = viewModel.weather {
                        HStack(spacing: 6) {
                            Image(systemName: weather.symbolName)
                                .font(.system(size: 16))
                                .foregroundStyle(.blue)
                            Text(weather.temperatureFormatted)
                                .font(.system(size: 16, weight: .medium))
                            Text(weather.conditionDescription)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                
                // AI Summary
                if let summary = viewModel.todaySummary {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SUMMARY")
                            .font(.custom("HelveticaNeue-Bold", size: 10))
                            .foregroundStyle(.secondary)
                            .tracking(1)
                        
                        Text(summary.summary)
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
                }
                
                // Events List
                VStack(alignment: .leading, spacing: 12) {
                    Text("EVENTS")
                        .font(.custom("HelveticaNeue-Bold", size: 10))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                    
                    if todayEvents.isEmpty {
                        Text("No events scheduled")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        ForEach(todayEvents) { event in
                            NavigationLink(value: NavigationDestination.eventDetail(eventId: event.id, date: event.startDate)) {
                                EventRowView(event: event)
                            }
                            .buttonStyle(.plain)
                            
                            if event.id != todayEvents.last?.id {
                                Divider()
                                    .opacity(0.5)
                            }
                        }
                    }
                }
                .padding(16)
                .glassCard()
            }
            .padding(20)
        }
        .navigationTitle(isToday ? "Today" : formattedShortDate)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    private var formattedWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private var formattedShortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Event Row View (App version)

struct EventRowView: View {
    let event: ScheduleEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(calendarColor)
                .frame(width: 4, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(event.isPast ? .secondary : .primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(event.formattedTimeRange)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.tertiary)
                    
                    Text(event.clientName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(calendarColor)
                }
            }
            
            Spacer()
            
            if event.isHappeningNow {
                Text("NOW")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(calendarColor)
                    .cornerRadius(4)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .opacity(event.isPast ? 0.6 : 1)
    }
    
    private var calendarColor: Color {
        CalendarColorHelper.color(for: event.clientName)
    }
}

// MARK: - Five Day Screen

/// Full-screen 5-Day Outlook view accessible via deep links
struct FiveDayScreen: View {
    @EnvironmentObject var viewModel: ScheduleViewModel
    @EnvironmentObject var router: AppRouter
    
    private let anchorDate: Date
    
    init(anchor: Date = Date()) {
        self.anchorDate = anchor
    }
    
    private var fiveDays: [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: anchorDate)
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("5-DAY OUTLOOK")
                        .font(.custom("HelveticaNeue-Bold", size: 11))
                        .foregroundStyle(Color.green)
                        .tracking(2)
                    
                    Text(dateRangeString)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("\(totalEventCount) events")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                
                // Days
                ForEach(fiveDays, id: \.self) { date in
                    DayCard(date: date, events: eventsForDay(date))
                }
            }
            .padding(20)
        }
        .navigationTitle("5-Day Outlook")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: fiveDays.first ?? Date())
        let end = formatter.string(from: fiveDays.last ?? Date())
        return "\(start) – \(end)"
    }
    
    private var totalEventCount: Int {
        fiveDays.reduce(0) { $0 + eventsForDay($1).count }
    }
    
    private func eventsForDay(_ date: Date) -> [ScheduleEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return []
        }
        
        return (viewModel.events ?? [])
            .filter { $0.startDate >= dayStart && $0.startDate < dayEnd }
            .sorted { $0.startDate < $1.startDate }
    }
}

// MARK: - Day Card

struct DayCard: View {
    let date: Date
    let events: [ScheduleEvent]
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isToday ? "TODAY" : dayName.uppercased())
                        .font(.custom("HelveticaNeue-Bold", size: 10))
                        .foregroundStyle(isToday ? .blue : .secondary)
                        .tracking(1)
                    
                    Text(formattedDate)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Text("\(events.count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(events.isEmpty ? Color.gray.opacity(0.5) : Color.primary)
                    .cornerRadius(6)
            }
            
            // Events
            if events.isEmpty {
                Text("No events")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                ForEach(events) { event in
                    NavigationLink(value: NavigationDestination.eventDetail(eventId: event.id, date: event.startDate)) {
                        CompactEventRowView(event: event)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Compact Event Row View

struct CompactEventRowView: View {
    let event: ScheduleEvent
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(calendarColor)
                .frame(width: 8, height: 8)
            
            Text(event.formattedTime)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            
            Text(event.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Text(event.clientName)
                .font(.system(size: 12))
                .foregroundStyle(calendarColor)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .opacity(event.isPast ? 0.6 : 1)
    }
    
    private var calendarColor: Color {
        CalendarColorHelper.color(for: event.clientName)
    }
}

// MARK: - Next Week Screen

/// Full-screen Next Week view accessible via deep links
struct NextWeekScreen: View {
    @EnvironmentObject var viewModel: ScheduleViewModel
    @EnvironmentObject var router: AppRouter
    
    private let anchorDate: Date
    
    init(anchor: Date? = nil) {
        self.anchorDate = anchor ?? Date()
    }
    
    private var weekDays: [Date] {
        let (monday, _) = getNextWeekDates()
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: monday) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT WEEK")
                        .font(.custom("HelveticaNeue-Bold", size: 11))
                        .foregroundStyle(Color.purple)
                        .tracking(2)
                    
                    Text(dateRangeString)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("\(totalEventCount) events")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                
                // Days
                ForEach(weekDays, id: \.self) { date in
                    DayCard(date: date, events: eventsForDay(date))
                }
            }
            .padding(20)
        }
        .navigationTitle("Next Week")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private var dateRangeString: String {
        let (monday, sunday) = getNextWeekDates()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: monday)) – \(formatter.string(from: sunday))"
    }
    
    private var totalEventCount: Int {
        weekDays.reduce(0) { $0 + eventsForDay($1).count }
    }
    
    private func eventsForDay(_ date: Date) -> [ScheduleEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return []
        }
        
        return (viewModel.events ?? [])
            .filter { $0.startDate >= dayStart && $0.startDate < dayEnd }
            .sorted { $0.startDate < $1.startDate }
    }
    
    private func getNextWeekDates() -> (Date, Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        
        var nextMonday = calendar.startOfDay(for: anchorDate)
        
        // Find the next Monday
        while calendar.component(.weekday, from: nextMonday) != 2 {
            guard let newDate = calendar.date(byAdding: .day, value: 1, to: nextMonday) else { break }
            nextMonday = newDate
        }
        
        // If today IS Monday, go to next week's Monday
        if calendar.component(.weekday, from: Date()) == 2 && calendar.isDate(nextMonday, inSameDayAs: Date()) {
            if let newDate = calendar.date(byAdding: .day, value: 7, to: nextMonday) {
                nextMonday = newDate
            }
        }
        
        let nextSunday = calendar.date(byAdding: .day, value: 6, to: nextMonday) ?? nextMonday
        return (nextMonday, nextSunday)
    }
}

// MARK: - Event Detail Screen

/// Full event detail view accessible via deep links
struct EventDetailScreen: View {
    @EnvironmentObject var viewModel: ScheduleViewModel
    @EnvironmentObject var router: AppRouter
    
    let eventId: String
    let date: Date?
    
    private var event: ScheduleEvent? {
        (viewModel.events ?? []).first { $0.id == eventId }
    }
    
    var body: some View {
        Group {
            if let event = event {
                eventContent(event)
            } else {
                eventNotFoundView
            }
        }
        .navigationTitle("Event")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func eventContent(_ event: ScheduleEvent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title and calendar
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(CalendarColorHelper.color(for: event.clientName))
                            .frame(width: 4, height: 20)
                        
                        Text(event.clientName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(CalendarColorHelper.color(for: event.clientName))
                        
                        Text("•")
                            .foregroundStyle(.tertiary)
                        
                        Text(event.calendarSource == .google ? "Google Calendar" : "iCloud")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Time
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            if event.isAllDay {
                                Text("All Day")
                                    .font(.system(size: 16, weight: .medium))
                            } else {
                                Text(event.formattedTimeRange)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("\(event.durationMinutes) minutes")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(formattedEventDate(event.startDate))
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "clock")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()
                
                // Location
                if let location = event.location, !location.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text(location)
                                .font(.system(size: 16))
                        } icon: {
                            Image(systemName: "location")
                                .font(.system(size: 16))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
                }
                
                // Notes
                if let notes = event.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES")
                            .font(.custom("HelveticaNeue-Bold", size: 10))
                            .foregroundStyle(.secondary)
                            .tracking(1)
                        
                        Text(notes)
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
                }
                
                // Status
                if event.isHappeningNow {
                    HStack {
                        Image(systemName: "clock.badge.fill")
                            .foregroundStyle(.green)
                        Text("Happening Now")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.green)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                } else if event.isPast {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("Past Event")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(20)
        }
    }
    
    private var eventNotFoundView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("Event Not Found")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text("This event may have been deleted or modified.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                router.goToToday()
            } label: {
                Text("Go to Today")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .onAppear {
            router.showEventNotFound()
        }
    }
    
    private func formattedEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Calendar Color Helper

/// Shared calendar color helper for app screens
enum CalendarColorHelper {
    static func color(for name: String) -> Color {
        switch name.lowercased() {
        case "theo":
            return Color(red: 0, green: 0.478, blue: 1) // #007AFF Blue
        case "adam":
            return Color(red: 1, green: 0.584, blue: 0) // #FF9500 Orange
        case "hudson":
            return Color(red: 0.204, green: 0.78, blue: 0.349) // #34C759 Green
        case "tom":
            return Color(red: 1, green: 0.231, blue: 0.188) // #FF3B30 Red
        case "ruby":
            return Color(red: 0.686, green: 0.322, blue: 0.871) // #AF52DE Purple
        case "conall":
            return Color(red: 1, green: 0.176, blue: 0.333) // #FF2D55 Pink
        case "leon":
            return Color(red: 0.345, green: 0.337, blue: 0.839) // #5856D6 Indigo
        case "jack × theo", "jack x theo":
            return Color(red: 0, green: 0.78, blue: 0.745) // #00C7BE Teal
        default:
            return Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93 Gray
        }
    }
}

// MARK: - Toast View

/// Toast message overlay view
struct ToastView: View {
    let message: ToastMessage
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)
            
            Text(message.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var iconName: String {
        switch message.type {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch message.type {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}
