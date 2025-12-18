//
//  MacAmbientAgendaWidget.swift
//  AMFScheduleWidget
//
//  Mac Desktop Widget: "Ambient Agenda"
//  A low-contrast, always-visible agenda designed to blend with wallpaper
//  Features: Timeline with hour ticks, colored event bars, "Now line", next hard stop
//

import SwiftUI
import WidgetKit

// Note: Color.init(hex:) is defined in AMFScheduleWidget.swift

// MARK: - Ambient Agenda Desktop Widget View

struct MacAmbientAgendaView: View {
    let entry: ScheduleWidgetEntry
    let family: WidgetFamily
    
    private var theme: WidgetTheme { entry.theme }
    private var events: [ScheduleEvent] {
        switch entry.viewType {
        case .today:
            return entry.events.todayOnly().sortedByTime()
        case .sevenDay:
            return entry.events.nextFiveDays().sortedByTime()
        case .nextWeek:
            return entry.events.nextWeek().sortedByTime()
        }
    }
    
    var body: some View {
        switch family {
        case .systemSmall:
            ambientSmall
        case .systemMedium:
            ambientMedium
        case .systemLarge:
            ambientLarge
        default:
            ambientMedium
        }
    }
    
    // MARK: - Small: Minimal glance
    
    private var ambientSmall: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date + Weather header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayOfWeek)
                        .font(.custom("HelveticaNeue-Bold", size: 10))
                        .foregroundColor(theme.secondaryTextColor.color.opacity(0.7))
                    
                    Text(dayNumber)
                        .font(.custom("Helvetica-Bold", size: 24))
                        .foregroundColor(theme.primaryTextColor.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: entry.weather.symbolName)
                        .font(.system(size: 16, weight: .light))
                    Text(entry.weather.temperatureFormatted)
                        .font(.custom("HelveticaNeue", size: 12))
                }
                .foregroundColor(theme.primaryTextColor.color.opacity(0.8))
            }
            
            Spacer()
            
            // Next event
            if let next = nextUpcomingEvent {
                VStack(alignment: .leading, spacing: 2) {
                    Text(next.title)
                        .font(.custom("HelveticaNeue-Medium", size: 12))
                        .foregroundColor(theme.primaryTextColor.color)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(CalendarColors.color(for: next.clientName))
                            .frame(width: 6, height: 6)
                        
                        Text(next.formattedTime)
                            .font(.custom("HelveticaNeue", size: 10))
                            .foregroundColor(theme.secondaryTextColor.color)
                    }
                }
            } else {
                Text("Clear schedule")
                    .font(.custom("HelveticaNeue", size: 11))
                    .foregroundColor(theme.secondaryTextColor.color.opacity(0.6))
                    .italic()
            }
            
            // Next hard stop countdown
            if let next = nextUpcomingEvent {
                HStack {
                    Spacer()
                    Text("in \(timeUntil(next.startDate))")
                        .font(.custom("HelveticaNeue-Medium", size: 10))
                        .foregroundColor(theme.accentColor.color)
                }
            }
        }
        .padding(14)
    }
    
    // MARK: - Medium: Timeline with hour markers
    
    private var ambientMedium: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Date + Weather + View Cycle Button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayOfWeek)
                        .font(.custom("HelveticaNeue-Bold", size: 9))
                        .foregroundColor(theme.secondaryTextColor.color.opacity(0.5))
                        .tracking(1)
                    
                    Text(dayNumber)
                        .font(.custom("Helvetica-Bold", size: 28))
                        .foregroundColor(theme.primaryTextColor.color.opacity(0.9))
                    
                    Text(monthName)
                        .font(.custom("HelveticaNeue", size: 10))
                        .foregroundColor(theme.secondaryTextColor.color.opacity(0.6))
                }
                
                Spacer()
                
                // Weather mini
                HStack(spacing: 4) {
                    Image(systemName: entry.weather.symbolName)
                        .font(.system(size: 11, weight: .light))
                    Text(entry.weather.temperatureFormatted)
                        .font(.custom("HelveticaNeue", size: 10))
                }
                .foregroundColor(theme.primaryTextColor.color.opacity(0.6))
                
                // View cycle button (subtle)
                ViewCycleButton(currentView: entry.viewType, theme: theme)
            }
            .padding(.bottom, 12)
            
            // Hour tick bar (9a, 12p, 3p, 6p)
            HourTickBar(theme: theme, hours: [9, 12, 15, 18])
                .frame(height: 18)
                .padding(.bottom, 8)
            
            // Event bars visualization with Now line
            AmbientTimelineBar(
                events: events.filter { !$0.isAllDay },
                theme: theme,
                hourRange: 9...18
            )
            .frame(height: 24)
            
            Spacer()
            
            // Footer: next hard stop + conflicts
            HStack(spacing: 8) {
                if let next = nextHardStop {
                    HStack(spacing: 4) {
                        Text("Next:")
                            .font(.custom("HelveticaNeue", size: 9))
                            .foregroundColor(theme.secondaryTextColor.color.opacity(0.5))
                        
                        Text("\(next.title)")
                            .font(.custom("HelveticaNeue-Medium", size: 9))
                            .foregroundColor(theme.primaryTextColor.color.opacity(0.7))
                            .lineLimit(1)
                        
                        Text("in \(timeUntil(next.startDate))")
                            .font(.custom("HelveticaNeue-Medium", size: 9))
                            .foregroundColor(theme.accentColor.color.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if conflictCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 8))
                        Text("\(conflictCount)")
                            .font(.custom("HelveticaNeue-Bold", size: 9))
                    }
                    .foregroundColor(Color(hex: "FF3B30").opacity(0.7))
                }
            }
        }
        .padding(14)
    }
    
    // MARK: - Large: Full agenda with all events
    
    @ViewBuilder
    private var ambientLarge: some View {
        // Show different content based on view type
        switch entry.viewType {
        case .today:
            todayLargeView
        case .sevenDay:
            sevenDayLargeView
        case .nextWeek:
            nextWeekLargeView
        }
    }
    
    private var todayLargeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayOfWeek.uppercased())
                        .font(.custom("HelveticaNeue-Bold", size: 10))
                        .foregroundColor(theme.secondaryTextColor.color.opacity(0.6))
                        .tracking(1.5)
                    
                    Text("\(monthName) \(dayNumber)")
                        .font(.custom("Helvetica-Bold", size: 20))
                        .foregroundColor(theme.primaryTextColor.color)
                }
                
                Spacer()
                
                // Weather
                HStack(spacing: 6) {
                    Image(systemName: entry.weather.symbolName)
                        .font(.system(size: 18, weight: .light))
                    
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(entry.weather.temperatureFormatted)
                            .font(.custom("HelveticaNeue-Medium", size: 14))
                        Text(entry.weather.highLowFormatted)
                            .font(.custom("HelveticaNeue", size: 9))
                            .foregroundColor(theme.secondaryTextColor.color)
                    }
                }
                .foregroundColor(theme.primaryTextColor.color.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Hour tick bar
            HourTickBar(theme: theme, hours: [6, 9, 12, 15, 18, 21])
                .padding(.horizontal, 16)
                .frame(height: 18)
            
            // Timeline visualization
            AmbientTimelineBar(
                events: events.filter { !$0.isAllDay },
                theme: theme,
                showLabels: true
            )
            .padding(.horizontal, 16)
            .frame(height: 32)
            
            // Divider
            Rectangle()
                .fill(theme.secondaryTextColor.color.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            // Event list
            VStack(alignment: .leading, spacing: 6) {
                ForEach(events.prefix(8)) { event in
                    AmbientEventRow(event: event, theme: theme)
                }
                
                if events.count > 8 {
                    Text("+\(events.count - 8) more events")
                        .font(.custom("HelveticaNeue", size: 10))
                        .foregroundColor(theme.secondaryTextColor.color.opacity(0.6))
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Footer: Next hard stop + conflicts + view cycle
            HStack {
                if let next = nextHardStop {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text("Next hard stop in \(timeUntil(next.startDate))")
                            .font(.custom("HelveticaNeue-Medium", size: 9))
                    }
                    .foregroundColor(theme.accentColor.color.opacity(0.7))
                }
                
                Spacer()
                
                if conflictCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 8))
                        Text("\(conflictCount)")
                            .font(.custom("HelveticaNeue-Bold", size: 9))
                    }
                    .foregroundColor(Color(hex: "FF3B30").opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "FF3B30").opacity(0.1))
                    .cornerRadius(4)
                }
                
                // View cycle button
                ViewCycleButton(currentView: entry.viewType, theme: theme)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    private var sevenDayLargeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("5-DAY OUTLOOK")
                        .font(.custom("HelveticaNeue-Bold", size: 10))
                        .foregroundColor(Color(hex: "34C759"))
                        .tracking(1.5)
                    
                    Text(dateRange)
                        .font(.custom("Helvetica-Bold", size: 18))
                        .foregroundColor(theme.primaryTextColor.color)
                    
                    Text("\(upcomingEventCount) events")
                        .font(.custom("HelveticaNeue-Medium", size: 9))
                        .foregroundColor(theme.secondaryTextColor.color)
                }
                
                Spacer()
                
                // View cycle button
                ViewCycleButton(currentView: entry.viewType, theme: theme)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)
            
            // 5-Day Grid: Show each day with artist breakdown
            HStack(alignment: .top, spacing: 8) {
                ForEach(nextFiveDays, id: \.self) { date in
                    DayColumnView(
                        date: date,
                        events: eventsForDay(date),
                        weather: entry.weather,
                        theme: theme
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
            
            Spacer()
        }
    }
    
    private var nextFiveDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
    
    private func eventsForDay(_ date: Date) -> [ScheduleEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return events.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }
    }
    
    private var upcomingEventCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 5, to: today)!
        return events.filter { $0.startDate >= today && $0.startDate < endDate }.count
    }
    
    private var nextWeekLargeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("NEXT WEEK")
                    .font(.custom("HelveticaNeue-Bold", size: 11))
                    .foregroundColor(Color(hex: "AF52DE"))
                    .tracking(1.5)
                
                Text(nextWeekRange)
                    .font(.custom("Helvetica-Bold", size: 22))
                    .foregroundColor(theme.primaryTextColor.color)
                
                Text("\(events.count) events")
                    .font(.custom("HelveticaNeue-Medium", size: 10))
                    .foregroundColor(theme.secondaryTextColor.color)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Summary text
            MarkdownText(entry.nextWeekSummary, fontSize: 12, lineLimit: nil, textColor: theme.primaryTextColor.color)
                .padding(.horizontal, 16)
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: entry.date)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: entry.date)
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: entry.date)
    }
    
    private var nextUpcomingEvent: ScheduleEvent? {
        events.first { !$0.isPast && !$0.isAllDay }
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
    
    /// Get the next "hard stop" - an important commitment (not just any event)
    private var nextHardStop: ScheduleEvent? {
        let upcoming = events.filter { !$0.isPast && !$0.isAllDay }
        
        // Prioritize events that are:
        // 1. Starting soon (within next 2 hours)
        // 2. Have a location (likely requires travel/prep)
        // 3. Are for specific people (not generic)
        
        let now = Date()
        let twoHoursFromNow = now.addingTimeInterval(2 * 60 * 60)
        
        // First, try to find an event starting within 2 hours with a location
        if let soonWithLocation = upcoming.first(where: { event in
            event.startDate <= twoHoursFromNow && event.location != nil && !event.location!.isEmpty
        }) {
            return soonWithLocation
        }
        
        // Otherwise, return the next upcoming event
        return upcoming.first
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
    
    private var dateRange: String {
        let calendar = Calendar.current
        let today = Date()
        guard let fiveDaysLater = calendar.date(byAdding: .day, value: 5, to: today) else {
            return "Next 5 days"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: today)
        let end = formatter.string(from: fiveDaysLater)
        return "\(start) – \(end)"
    }
    
    private var nextWeekRange: String {
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
            return "Next week"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: nextMonday)
        let end = formatter.string(from: nextSunday)
        return "\(start) – \(end)"
    }
}

// MARK: - Ambient Timeline Bar

struct AmbientTimelineBar: View {
    let events: [ScheduleEvent]
    let theme: WidgetTheme
    var showLabels: Bool = false
    var hourRange: ClosedRange<Int> = 9...18  // Default to business hours for ambient view
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.secondaryTextColor.color.opacity(0.08))
                
                // Event bars
                ForEach(events) { event in
                    eventBar(for: event, in: geometry.size)
                }
                
                // Now indicator
                nowIndicator(in: geometry.size)
            }
        }
    }
    
    private func eventBar(for event: ScheduleEvent, in size: CGSize) -> some View {
        let startHour = Calendar.current.component(.hour, from: event.startDate)
        let startMinute = Calendar.current.component(.minute, from: event.startDate)
        let endHour = Calendar.current.component(.hour, from: event.endDate)
        let endMinute = Calendar.current.component(.minute, from: event.endDate)
        
        let totalHours = CGFloat(hourRange.count)
        let hourWidth = size.width / totalHours
        
        let clampedStartHour = max(startHour, hourRange.lowerBound)
        let clampedEndHour = min(endHour, hourRange.upperBound)
        
        let startFraction = CGFloat(clampedStartHour - hourRange.lowerBound) + CGFloat(startMinute) / 60
        let endFraction = CGFloat(clampedEndHour - hourRange.lowerBound) + CGFloat(endMinute) / 60
        
        let xOffset = max(0, startFraction * hourWidth)
        let barWidth = max((endFraction - startFraction) * hourWidth, 4)
        
        let color = CalendarColors.color(for: event.clientName)
        
        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(event.isPast ? 0.15 : 0.4))  // More subtle for ambient
                .frame(width: barWidth, height: showLabels ? size.height * 0.7 : size.height - 4)
            
            if showLabels && barWidth > 40 {
                Text(event.title)
                    .font(.custom("HelveticaNeue", size: 8))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            }
        }
        .offset(x: xOffset, y: showLabels ? size.height * 0.15 : 2)
    }
    
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
            ZStack {
                // Subtle glow
                Rectangle()
                    .fill(Color(hex: "FF3B30").opacity(0.3))
                    .frame(width: 4, height: size.height)
                    .blur(radius: 1)
                
                // Now line
                Rectangle()
                    .fill(Color(hex: "FF3B30").opacity(0.8))
                    .frame(width: 1.5, height: size.height)
            }
            .offset(x: xOffset)
        )
    }
}

// MARK: - Ambient Event Row

struct AmbientEventRow: View {
    let event: ScheduleEvent
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 8) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(CalendarColors.color(for: event.clientName))
                .frame(width: 3, height: 16)
            
            // Time
            Text(event.isAllDay ? "All day" : event.formattedTime)
                .font(.custom("HelveticaNeue", size: 10))
                .foregroundColor(theme.secondaryTextColor.color)
                .frame(width: 52, alignment: .leading)
            
            // Title
            Text(event.title)
                .font(.custom("HelveticaNeue-Medium", size: 11))
                .foregroundColor(event.isPast ? theme.secondaryTextColor.color : theme.primaryTextColor.color)
                .lineLimit(1)
            
            Spacer()
            
            // Client name
            Text(event.clientName)
                .font(.custom("HelveticaNeue", size: 9))
                .foregroundColor(CalendarColors.color(for: event.clientName))
            
            // Now badge
            if event.isHappeningNow {
                Text("NOW")
                    .font(.custom("HelveticaNeue-Bold", size: 7))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color(hex: "FF3B30"))
                    .cornerRadius(3)
            }
        }
        .opacity(event.isPast ? 0.5 : 1)
    }
}

// MARK: - Day Column View (for 5-day grid)

struct DayColumnView: View {
    let date: Date
    let events: [ScheduleEvent]
    let weather: WeatherData?
    let theme: WidgetTheme
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var dayForecast: DailyForecast? {
        weather?.forecast(for: date)
    }
    
    // Group events by artist/calendar
    private var eventsByArtist: [String: [ScheduleEvent]] {
        Dictionary(grouping: events.sortedByTime()) { $0.clientName }
    }
    
    private var artists: [String] {
        let priority = ["Theo", "Adam", "Hudson", "Tom", "Ruby", "Conall", "Leon", "Jack"]
        let allArtists = Array(eventsByArtist.keys)
        return allArtists.sorted { a1, a2 in
            let idx1 = priority.firstIndex(of: a1) ?? 999
            let idx2 = priority.firstIndex(of: a2) ?? 999
            return idx1 < idx2
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Day header
            VStack(alignment: .leading, spacing: 2) {
                Text(dayLabel)
                    .font(.custom("HelveticaNeue-Bold", size: 9))
                    .foregroundColor(isToday ? .white : theme.primaryTextColor.color.opacity(0.8))
                    .padding(.horizontal, isToday ? 5 : 0)
                    .padding(.vertical, isToday ? 2 : 0)
                    .background(isToday ? Color(hex: "007AFF") : Color.clear)
                    .cornerRadius(3)
                
                Text(dateFormatted)
                    .font(.custom("HelveticaNeue", size: 8))
                    .foregroundColor(theme.secondaryTextColor.color.opacity(0.7))
                
                // Mini weather
                if let forecast = dayForecast {
                    HStack(spacing: 2) {
                        Image(systemName: forecast.symbolName)
                            .font(.system(size: 8))
                        Text(forecast.highFormatted)
                            .font(.custom("HelveticaNeue", size: 8))
                    }
                    .foregroundColor(theme.secondaryTextColor.color.opacity(0.6))
                }
                
                // Event count badge
                if !events.isEmpty {
                    Text("\(events.count)")
                        .font(.custom("HelveticaNeue-Bold", size: 8))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(events.count > 0 ? Color(hex: "333333") : Color(hex: "CCCCCC"))
                        .cornerRadius(3)
                }
            }
            
            // Artist rows - show what each artist is doing
            if events.isEmpty {
                Text("Free")
                    .font(.custom("HelveticaNeue", size: 8))
                    .foregroundColor(theme.secondaryTextColor.color.opacity(0.4))
                    .italic()
                    .padding(.top, 4)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(artists.prefix(4), id: \.self) { artist in
                        ArtistDayRow(
                            artist: artist,
                            events: eventsByArtist[artist] ?? [],
                            theme: theme
                        )
                    }
                    
                    if artists.count > 4 {
                        Text("+\(artists.count - 4) more")
                            .font(.custom("HelveticaNeue", size: 7))
                            .foregroundColor(theme.secondaryTextColor.color.opacity(0.5))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(isToday ? Color(hex: "007AFF").opacity(0.06) : Color.clear)
        .cornerRadius(6)
    }
    
    private var dayLabel: String {
        if isToday {
            return "TODAY"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Artist Day Row

struct ArtistDayRow: View {
    let artist: String
    let events: [ScheduleEvent]
    let theme: WidgetTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Artist header with color
            HStack(spacing: 3) {
                Circle()
                    .fill(CalendarColors.color(for: artist))
                    .frame(width: 6, height: 6)
                
                Text(CalendarColors.initial(for: artist))
                    .font(.custom("HelveticaNeue-Bold", size: 7))
                    .foregroundColor(CalendarColors.color(for: artist))
            }
            
            // Events for this artist
            VStack(alignment: .leading, spacing: 1) {
                ForEach(events.prefix(2)) { event in
                    HStack(spacing: 3) {
                        Text(event.formattedTime)
                            .font(.custom("HelveticaNeue", size: 7))
                            .foregroundColor(theme.secondaryTextColor.color.opacity(0.7))
                        
                        Text(event.title)
                            .font(.custom("HelveticaNeue", size: 7))
                            .foregroundColor(theme.primaryTextColor.color.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                
                if events.count > 2 {
                    Text("+\(events.count - 2)")
                        .font(.custom("HelveticaNeue", size: 6))
                        .foregroundColor(theme.secondaryTextColor.color.opacity(0.5))
                }
            }
            .padding(.leading, 9)
        }
    }
}

