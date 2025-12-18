//
//  AMFScheduleWidget.swift
//  AMFScheduleWidget
//
//  Unified configurable schedule widget with Liquid Glass design
//

import WidgetKit
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date Extension for Short Relative Time

extension Date {
    /// Returns a short relative time string like "5m", "2h", "1d"
    var shortRelativeTime: String {
        let seconds = Int(Date().timeIntervalSince(self))
        
        if seconds < 60 {
            return "now"
        } else if seconds < 3600 {
            return "\(seconds / 60)m ago"
        } else if seconds < 86400 {
            return "\(seconds / 3600)h ago"
        } else {
            return "\(seconds / 86400)d ago"
        }
    }
}

// MARK: - Markdown Text Helper
// iOS-only (Mac has its own in MacWidgetDefinitions.swift)
#if !os(macOS)
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
#endif

// MARK: - Main Widget

struct AMFScheduleWidget: Widget {
    let kind: String = "AMFScheduleWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ScheduleWidgetConfigIntent.self,
            provider: ScheduleWidgetProvider()
        ) { entry in
            ScheduleWidgetEntryView(entry: entry)
                .widgetGlassBackground(theme: entry.theme)
        }
        .configurationDisplayName("AMF Schedule")
        .description("View your schedule in different formats")
        #if os(iOS)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        #else
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        #endif
    }
}

// MARK: - System Glass Background Support
// iOS-only (Mac has its own in MacWidgetDefinitions.swift)
#if !os(macOS)
extension View {
    func widgetGlassBackground(theme: WidgetTheme) -> some View {
        modifier(WidgetGlassBackground(theme: theme))
    }
}
#endif

private struct WidgetGlassBackground: ViewModifier {
    let theme: WidgetTheme
    
    func body(content: Content) -> some View {
        content
            .background(overlayTint)
            .containerBackground(for: .widget) {
                backgroundSurface
            }
    }
    
    @ViewBuilder
    private var overlayTint: some View {
        if theme.prefersSystemGlass, theme.backgroundOpacity > 0 {
            theme.backgroundColor.color.opacity(theme.backgroundOpacity)
        }
    }
    
    @ViewBuilder
    private var backgroundSurface: some View {
        if let name = theme.backgroundImageName,
           let image = WidgetBackgroundImageCache.shared.image(named: name) {
            #if os(iOS)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(theme.backgroundImageOpacity)
                .blur(radius: theme.backgroundImageBlur)
                .overlay {
                    if let overlayColor = theme.backgroundOverlayColor, theme.backgroundOverlayOpacity > 0 {
                        overlayColor.color.opacity(theme.backgroundOverlayOpacity)
                    }
                }
            #elseif os(macOS)
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(theme.backgroundImageOpacity)
                .blur(radius: theme.backgroundImageBlur)
                .overlay {
                    if let overlayColor = theme.backgroundOverlayColor, theme.backgroundOverlayOpacity > 0 {
                        overlayColor.color.opacity(theme.backgroundOverlayOpacity)
                    }
                }
            #endif
        } else if theme.prefersSystemGlass {
            Color.clear
        } else {
            theme.backgroundSurface
        }
    }
}

private extension WidgetTheme {
    var prefersSystemGlass: Bool {
        useTransparentBackground && backgroundImageName == nil
    }
}

// PlatformImage is defined in WidgetThemeStore.swift (shared between app and widgets)
// No need to redefine it here

private final class WidgetBackgroundImageCache {
    static let shared = WidgetBackgroundImageCache()
    
    private let cache = NSCache<NSString, PlatformImage>()
    private let appGroupId = "group.Theo.Schedule-Summary-Widget-Nov-26-2025"
    
    private init() {}
    
    func image(named name: String) -> PlatformImage? {
        let key = name as NSString
        
        if let cached = cache.object(forKey: key) {
            return cached
        }
        
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }
        
        let imageURL = containerURL
            .appendingPathComponent("BackgroundImages")
            .appendingPathComponent(name)
        
        guard let data = try? Data(contentsOf: imageURL) else {
            return nil
        }
        
        #if os(iOS)
        guard let image = UIImage(data: data) else { return nil }
        let resized = resizeForWidget(image, maxDimension: 400)
        #elseif os(macOS)
        guard let image = NSImage(data: data) else { return nil }
        let resized = resizeForWidget(image, maxDimension: 400)
        #endif
        
        cache.setObject(resized, forKey: key)
        return resized
    }
    
    #if os(iOS)
    private func resizeForWidget(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        let ratio = size.width / size.height
        let newSize: CGSize = size.width > size.height
            ? CGSize(width: maxDimension, height: maxDimension / ratio)
            : CGSize(width: maxDimension * ratio, height: maxDimension)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    #elseif os(macOS)
    private func resizeForWidget(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        let ratio = size.width / size.height
        let newSize: CGSize = size.width > size.height
            ? CGSize(width: maxDimension, height: maxDimension / ratio)
            : CGSize(width: maxDimension * ratio, height: maxDimension)
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        newImage.unlockFocus()
        return newImage
    }
    #endif
}

// MARK: - Entry View Router

struct ScheduleWidgetEntryView: View {
    var entry: ScheduleWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch entry.viewType {
        case .today:
            TodayViewContent(entry: entry, family: family)
        case .sevenDay:
            SevenDayViewContent(entry: entry, family: family)
        case .nextWeek:
            NextWeekViewContent(entry: entry, family: family)
        }
    }
}

// MARK: - Today View Content

struct TodayViewContent: View {
    let entry: ScheduleWidgetEntry
    let family: WidgetFamily
    
    var body: some View {
        switch family {
        case .systemSmall:
            TodaySmallView(entry: entry)
        case .systemMedium:
            TodayMediumView(entry: entry)
        case .systemLarge:
            TodayLargeView(entry: entry)
        case .systemExtraLarge:
            TodayExtraLargeView(entry: entry)
        default:
            TodayMediumView(entry: entry)
        }
    }
}

// MARK: - Today Extra Large View (iPad)

struct TodayExtraLargeView: View {
    let entry: ScheduleWidgetEntry
    
    private var theme: WidgetTheme { entry.theme }
    private var events: [ScheduleEvent] { entry.events.todayOnly().sortedByTime() }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left column: Today details
            leftColumn
                .frame(maxWidth: .infinity)
            
            // Divider
            Rectangle()
                .fill(theme.secondaryTextColor.color.opacity(0.15))
                .frame(width: 1)
            
            // Right column: Tomorrow + Week preview
            rightColumn
                .frame(width: 280)
        }
        .widgetURL(DeepLinkRoute.todayURL(date: entry.date))
    }
    
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("TODAY")
                        .font(.custom("HelveticaNeue-Bold", size: 11))
                        .foregroundColor(theme.accentColor.color)
                        .tracking(1.5)
                    
                    Text(formattedDate)
                        .font(.custom("Helvetica-Bold", size: 24))
                        .foregroundColor(theme.primaryTextColor.color)
                        .tracking(-0.5)
                    
                    Text("\(events.count) events")
                        .font(.custom("HelveticaNeue-Medium", size: 10))
                        .foregroundColor(theme.secondaryTextColor.color)
                }
                
                Spacer()
                
                // Large weather display
                WeatherClusterView(weather: entry.weather, size: .detailed, theme: theme)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(theme.headerSurface)
            
            // Summary
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.todaySummary.summary)
                    .font(.custom("HelveticaNeue", size: 12))
                    .foregroundColor(theme.primaryTextColor.color)
                    .lineLimit(3)
                    .padding(.top, 12)
                
                // Events list - each event is a deep link
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(events) { event in
                        Link(destination: DeepLinkRoute.eventURL(id: event.id, date: event.startDate)) {
                            DetailedEventRow(event: event, theme: theme)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
    
    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tomorrow section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("TOMORROW")
                        .font(.custom("HelveticaNeue-Bold", size: 9))
                        .foregroundColor(theme.secondaryTextColor.color)
                        .tracking(1)
                    
                    Spacer()
                    
                    TomorrowWeatherBadge(weather: entry.weather, theme: theme)
                }
                
                ForEach(tomorrowEvents.prefix(4)) { event in
                    MiniEventRow(event: event, theme: theme)
                }
                
                if tomorrowEvents.isEmpty {
                    Text("No events")
                        .font(.custom("HelveticaNeue", size: 10))
                        .foregroundColor(theme.secondaryTextColor.color.opacity(0.6))
                        .italic()
                }
            }
            .padding(12)
            .background(theme.glassTintColor.opacity(0.04))
            .cornerRadius(10)
            
            // Week preview
            VStack(alignment: .leading, spacing: 6) {
                Text("THIS WEEK")
                    .font(.custom("HelveticaNeue-Bold", size: 9))
                    .foregroundColor(theme.secondaryTextColor.color)
                    .tracking(1)
                
                ForEach(nextFiveDays, id: \.self) { date in
                    WeekDayMiniRow(date: date, events: eventsForDay(date), theme: theme)
                }
            }
            .padding(12)
            .background(theme.glassTintColor.opacity(0.04))
            .cornerRadius(10)
            
            Spacer()
        }
        .padding(16)
        .background(theme.backgroundColor.color.opacity(0.3))
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: entry.date)
    }
    
    private var tomorrowEvents: [ScheduleEvent] {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: entry.date))!
        let dayAfter = calendar.date(byAdding: .day, value: 1, to: tomorrow)!
        
        return entry.events
            .filter { $0.startDate >= tomorrow && $0.startDate < dayAfter }
            .sorted { $0.startDate < $1.startDate }
    }
    
    private var nextFiveDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (1..<6).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
    
    private func eventsForDay(_ date: Date) -> [ScheduleEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return entry.events.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }
    }
}

// MARK: - Supporting Views for Extra Large

struct DetailedEventRow: View {
    let event: ScheduleEvent
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 10) {
            // Color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(calendarColor)
                .frame(width: 4, height: 32)
            
            // Time
            VStack(alignment: .leading, spacing: 0) {
                Text(event.isAllDay ? "All day" : event.formattedTime)
                    .font(.custom("HelveticaNeue", size: 10))
                    .foregroundColor(theme.secondaryTextColor.color)
                
                if !event.isAllDay {
                    Text("\(event.durationMinutes)m")
                        .font(.custom("HelveticaNeue", size: 9))
                        .foregroundColor(theme.secondaryTextColor.color.opacity(0.6))
                }
            }
            .frame(width: 48, alignment: .leading)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.custom("HelveticaNeue-Medium", size: 12))
                    .foregroundColor(event.isPast ? theme.secondaryTextColor.color : theme.primaryTextColor.color)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(event.clientName)
                        .font(.custom("HelveticaNeue", size: 10))
                        .foregroundColor(calendarColor)
                    
                    if let location = event.location, !location.isEmpty {
                        Text("•")
                            .foregroundColor(theme.secondaryTextColor.color.opacity(0.4))
                        Text(location)
                            .font(.custom("HelveticaNeue", size: 9))
                            .foregroundColor(theme.secondaryTextColor.color.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Status
            if event.isHappeningNow {
                Text("NOW")
                    .font(.custom("HelveticaNeue-Bold", size: 8))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(calendarColor)
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(event.isHappeningNow ? calendarColor.opacity(0.08) : theme.glassTintColor.opacity(0.02))
        .cornerRadius(8)
        .opacity(event.isPast ? 0.5 : 1)
    }
    
    private var calendarColor: Color {
        switch event.clientName.lowercased() {
        case "theo": return Color(hex: "007AFF")
        case "adam": return Color(hex: "FF9500")
        case "hudson": return Color(hex: "34C759")
        case "tom": return Color(hex: "FF3B30")
        case "ruby": return Color(hex: "AF52DE")
        case "conall": return Color(hex: "FF2D55")
        case "leon": return Color(hex: "5856D6")
        case "jack × theo", "jack x theo": return Color(hex: "00C7BE")
        default: return Color(hex: "8E8E93")
        }
    }
}

struct MiniEventRow: View {
    let event: ScheduleEvent
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(calendarColor)
                .frame(width: 6, height: 6)
            
            Text(event.isAllDay ? "All day" : event.formattedTime)
                .font(.custom("HelveticaNeue", size: 9))
                .foregroundColor(theme.secondaryTextColor.color)
                .frame(width: 40, alignment: .leading)
            
            Text(event.title)
                .font(.custom("HelveticaNeue-Medium", size: 10))
                .foregroundColor(theme.primaryTextColor.color)
                .lineLimit(1)
            
            Spacer()
            
            Text(event.clientName)
                .font(.custom("HelveticaNeue", size: 8))
                .foregroundColor(calendarColor)
        }
    }
    
    private var calendarColor: Color {
        switch event.clientName.lowercased() {
        case "theo": return Color(hex: "007AFF")
        case "adam": return Color(hex: "FF9500")
        case "hudson": return Color(hex: "34C759")
        case "tom": return Color(hex: "FF3B30")
        case "ruby": return Color(hex: "AF52DE")
        case "conall": return Color(hex: "FF2D55")
        case "leon": return Color(hex: "5856D6")
        case "jack × theo", "jack x theo": return Color(hex: "00C7BE")
        default: return Color(hex: "8E8E93")
        }
    }
}

struct WeekDayMiniRow: View {
    let date: Date
    let events: [ScheduleEvent]
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 8) {
            Text(dayLabel)
                .font(.custom("HelveticaNeue-Medium", size: 9))
                .foregroundColor(theme.primaryTextColor.color)
                .frame(width: 32, alignment: .leading)
            
            if events.isEmpty {
                Text("Free")
                    .font(.custom("HelveticaNeue", size: 9))
                    .foregroundColor(theme.secondaryTextColor.color.opacity(0.5))
                    .italic()
            } else {
                HStack(spacing: 3) {
                    ForEach(uniqueClients.prefix(4), id: \.self) { client in
                        Circle()
                            .fill(calendarColor(for: client))
                            .frame(width: 6, height: 6)
                    }
                    
                    if uniqueClients.count > 4 {
                        Text("+\(uniqueClients.count - 4)")
                            .font(.custom("HelveticaNeue", size: 7))
                            .foregroundColor(theme.secondaryTextColor.color)
                    }
                }
                
                Spacer()
                
                Text("\(events.count)")
                    .font(.custom("HelveticaNeue-Medium", size: 9))
                    .foregroundColor(theme.secondaryTextColor.color)
            }
        }
    }
    
    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private var uniqueClients: [String] {
        Array(Set(events.map { $0.clientName }))
    }
    
    private func calendarColor(for client: String) -> Color {
        switch client.lowercased() {
        case "theo": return Color(hex: "007AFF")
        case "adam": return Color(hex: "FF9500")
        case "hudson": return Color(hex: "34C759")
        case "tom": return Color(hex: "FF3B30")
        case "ruby": return Color(hex: "AF52DE")
        case "conall": return Color(hex: "FF2D55")
        case "leon": return Color(hex: "5856D6")
        case "jack × theo", "jack x theo": return Color(hex: "00C7BE")
        default: return Color(hex: "8E8E93")
        }
    }
}

// MARK: - Today Small View

struct TodaySmallView: View {
    let entry: ScheduleWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header - consistent style
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY")
                        .font(.custom("HelveticaNeue-Bold", size: 9))
                        .foregroundColor(Color(hex: "888888"))
                        .tracking(1)
                    
                    Text(formattedDate)
                        .font(.custom("HelveticaNeue-Bold", size: 14))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                WeatherClusterView(weather: entry.weather, size: .small)
            }
            
            Spacer(minLength: 4)
            
            MarkdownText(entry.todaySummary.summary, fontSize: 11, lineLimit: 5)
            
            Spacer()
            
            if entry.todaySummary.eventCount > 0 {
                Text("\(entry.todaySummary.eventCount) events")
                    .font(.custom("HelveticaNeue", size: 10))
                    .foregroundColor(Color(hex: "666666"))
            }
        }
        .padding(12)
        .widgetURL(DeepLinkRoute.todayURL(date: entry.date))
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }
}

// MARK: - Today Medium View

struct TodayMediumView: View {
    let entry: ScheduleWidgetEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                // Header - consistent style
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY")
                        .font(.custom("HelveticaNeue-Bold", size: 9))
                        .foregroundColor(Color(hex: "888888"))
                        .tracking(1)
                    
                    Text(formattedDate)
                        .font(.custom("HelveticaNeue-Bold", size: 16))
                        .foregroundColor(.black)
                    
                    Text("\(upcomingEvents.count) events")
                        .font(.custom("HelveticaNeue", size: 10))
                        .foregroundColor(Color(hex: "666666"))
                }
                
                Spacer(minLength: 4)
                
                MarkdownText(entry.todaySummary.summary, fontSize: 12, lineLimit: 4)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .trailing, spacing: 8) {
                WeatherClusterView(weather: entry.weather, size: .medium)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(upcomingEvents.prefix(4)) { event in
                        Link(destination: DeepLinkRoute.eventURL(id: event.id, date: event.startDate)) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(calendarColor(for: event.clientName))
                                    .frame(width: 5, height: 5)
                                
                                Text(event.formattedTime)
                                    .font(.custom("HelveticaNeue", size: 9))
                                    .foregroundColor(Color(hex: "666666"))
                                
                                Text(event.clientName)
                                    .font(.custom("HelveticaNeue-Medium", size: 9))
                                    .foregroundColor(calendarColor(for: event.clientName))
                            }
                        }
                    }
                }
                
                if upcomingEvents.count > 4 {
                    Text("+\(upcomingEvents.count - 4) more")
                        .font(.custom("HelveticaNeue", size: 9))
                        .foregroundColor(Color(hex: "666666"))
                }
            }
            .frame(width: 95)
        }
        .padding(12)
        .widgetURL(DeepLinkRoute.todayURL(date: entry.date))
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE dd MMM yyyy"
        return formatter.string(from: entry.date)
    }
    
    private var upcomingEvents: [ScheduleEvent] {
        entry.events
            .todayOnly()
            .filter { !$0.isPast }
            .sortedByTime()
    }
    
    private func calendarColor(for clientName: String) -> Color {
        switch clientName.lowercased() {
        case "theo": return Color(hex: "007AFF")
        case "adam": return Color(hex: "FF9500")
        case "hudson": return Color(hex: "34C759")
        case "tom": return Color(hex: "FF3B30")
        case "ruby": return Color(hex: "AF52DE")
        case "conall": return Color(hex: "FF2D55")
        case "leon": return Color(hex: "5856D6")
        case "jack × theo", "jack x theo": return Color(hex: "00C7BE")
        default: return Color(hex: "8E8E93")
        }
    }
}

// MARK: - Today Large View

struct TodayLargeView: View {
    let entry: ScheduleWidgetEntry
    
    private var theme: WidgetTheme { entry.theme }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row - edge-to-edge ribbon
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("TODAY")
                        .font(.custom("HelveticaNeue-Bold", size: 10))
                        .foregroundColor(theme.accentColor.color)
                        .tracking(1.5)
                    
                    Text(formattedDate)
                        .font(.custom("Helvetica-Bold", size: 20))
                        .foregroundColor(theme.primaryTextColor.color)
                        .tracking(-2)
                    
                    Text("\(todayEvents.count) EVENTS")
                        .font(.custom("HelveticaNeue-Medium", size: 9))
                        .foregroundColor(theme.secondaryTextColor.color)
                        .tracking(1)
                }
                
                Spacer()
                
                // Detailed weather with sunset
                WeatherClusterView(weather: entry.weather, size: .detailed, theme: theme)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(theme.headerSurface)
            
            // Content area with matching horizontal padding
            VStack(alignment: .leading, spacing: 6) {
                // Summary - 2 lines max
                MarkdownText(entry.todaySummary.summary, fontSize: 11, lineLimit: 2, textColor: theme.primaryTextColor.color)
                    .padding(.top, 8)
                
                // Today's event list - show ALL events
                if todayEvents.isEmpty {
                    Text("No events today")
                        .font(.custom("HelveticaNeue", size: 10))
                        .foregroundColor(theme.secondaryTextColor.color)
                        .italic()
                        .padding(.vertical, 2)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(todayEvents) { event in
                            CompactEventRow(event: event, theme: theme)
                        }
                    }
                }
                
                // Tomorrow section - only show if there's space (today has few events)
                if todayEvents.count <= 6 {
                    Rectangle()
                        .fill(theme.secondaryTextColor.color.opacity(0.3))
                        .frame(height: 0.5)
                        .padding(.top, 4)
                    
                    HStack {
                        Text("TOMORROW")
                            .font(.custom("HelveticaNeue-Bold", size: 8))
                            .foregroundColor(theme.secondaryTextColor.color)
                            .tracking(0.5)
                        
                        Text(tomorrowDateLabel)
                            .font(.custom("HelveticaNeue", size: 8))
                            .foregroundColor(theme.secondaryTextColor.color.opacity(0.7))
                        
                        Spacer()
                        
                        // Tomorrow's weather with sunrise
                        TomorrowWeatherBadge(weather: entry.weather, theme: theme)
                        
                        Text("•")
                            .font(.custom("HelveticaNeue", size: 8))
                            .foregroundColor(theme.secondaryTextColor.color.opacity(0.5))
                        
                        Text("\(tomorrowEvents.count) events")
                            .font(.custom("HelveticaNeue", size: 8))
                            .foregroundColor(theme.secondaryTextColor.color)
                    }
                    
                    // Tomorrow's event list - show ALL events
                    if tomorrowEvents.isEmpty {
                        Text("No events tomorrow")
                            .font(.custom("HelveticaNeue", size: 10))
                            .foregroundColor(theme.secondaryTextColor.color)
                            .italic()
                            .padding(.vertical, 2)
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(tomorrowEvents) { event in
                                CompactEventRow(event: event, theme: theme)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .widgetURL(DeepLinkRoute.todayURL(date: entry.date))
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: entry.date).uppercased()
    }
    
    private var tomorrowDateLabel: String {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: entry.date)!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        return formatter.string(from: tomorrow)
    }
    
    private var todayEvents: [ScheduleEvent] {
        entry.events.todayOnly().sortedByTime()
    }
    
    private var tomorrowEvents: [ScheduleEvent] {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: entry.date))!
        let dayAfter = calendar.date(byAdding: .day, value: 1, to: tomorrow)!
        
        return entry.events
            .filter { $0.startDate >= tomorrow && $0.startDate < dayAfter }
            .sorted { $0.startDate < $1.startDate }
    }
    
    private var isStale: Bool {
        guard let lastRefresh = entry.lastRefresh else { return true }
        return Date().timeIntervalSince(lastRefresh) > 3600 // 1 hour
    }
}

// MARK: - Compact Event Row (for fitting more events)
// iOS-only (Mac has its own in MacWidgetDefinitions.swift)
#if !os(macOS)
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
            
            // Client badge
            Text(event.clientName)
                .font(.custom("HelveticaNeue", size: 9))
                .foregroundColor(calendarColor)
                .lineLimit(1)
        }
        .opacity(event.isPast ? 0.6 : 1)
    }
    
    // Calendar-specific colors
    private var calendarColor: Color {
        switch event.clientName.lowercased() {
        case "theo":
            return Color(hex: "007AFF") // Blue - like iCal default
        case "adam":
            return Color(hex: "FF9500") // Orange
        case "hudson":
            return Color(hex: "34C759") // Green
        case "tom":
            return Color(hex: "FF3B30") // Red
        case "ruby":
            return Color(hex: "AF52DE") // Purple
        case "conall":
            return Color(hex: "FF2D55") // Pink
        case "leon":
            return Color(hex: "5856D6") // Indigo
        case "jack × theo", "jack x theo":
            return Color(hex: "00C7BE") // Teal
        default:
            return Color(hex: "8E8E93") // Gray
        }
    }
}
#endif

// MARK: - Event Row View

struct EventRowView: View {
    let event: ScheduleEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Color indicator
            Circle()
                .fill(calendarColor)
                .frame(width: 8, height: 8)
                .padding(.top, 4)
            
            Text(event.formattedTime)
                .font(.custom("HelveticaNeue", size: 11))
                .foregroundColor(Color(hex: "666666"))
                .frame(width: 50, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.custom("HelveticaNeue-Medium", size: 12))
                    .foregroundColor(event.isPast ? Color(hex: "999999") : .black)
                    .lineLimit(1)
                
                Text(event.clientName)
                    .font(.custom("HelveticaNeue", size: 10))
                    .foregroundColor(calendarColor)
            }
            
            Spacer()
            
            if event.isHappeningNow {
                Text("NOW")
                    .font(.custom("HelveticaNeue-Bold", size: 8))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(calendarColor)
                    .cornerRadius(3)
            }
        }
        .opacity(event.isPast ? 0.6 : 1)
    }
    
    // Calendar-specific colors
    private var calendarColor: Color {
        switch event.clientName.lowercased() {
        case "theo":
            return Color(hex: "007AFF") // Blue
        case "adam":
            return Color(hex: "FF9500") // Orange
        case "hudson":
            return Color(hex: "34C759") // Green
        case "tom":
            return Color(hex: "FF3B30") // Red
        case "ruby":
            return Color(hex: "AF52DE") // Purple
        case "conall":
            return Color(hex: "FF2D55") // Pink
        case "leon":
            return Color(hex: "5856D6") // Indigo
        case "jack × theo", "jack x theo":
            return Color(hex: "00C7BE") // Teal
        default:
            return Color(hex: "8E8E93") // Gray
        }
    }
}

// MARK: - 7-Day View Content

struct SevenDayViewContent: View {
    let entry: ScheduleWidgetEntry
    let family: WidgetFamily
    
    var body: some View {
        switch family {
        case .systemSmall:
            SevenDaySmallView(entry: entry)
        case .systemMedium:
            SevenDayMediumView(entry: entry)
        case .systemLarge:
            SevenDayLargeView(entry: entry)
        case .systemExtraLarge:
            SevenDayExtraLargeView(entry: entry)
        default:
            SevenDayMediumView(entry: entry)
        }
    }
}

// MARK: - 5-Day Extra Large View (iPad)

struct SevenDayExtraLargeView: View {
    let entry: ScheduleWidgetEntry
    
    private var theme: WidgetTheme { entry.theme }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Summary + Weather
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("5-DAY OUTLOOK")
                        .font(.custom("HelveticaNeue-Bold", size: 11))
                        .foregroundColor(Color(hex: "34C759"))
                        .tracking(1.5)
                    
                    Text(dateRange)
                        .font(.custom("Helvetica-Bold", size: 22))
                        .foregroundColor(theme.primaryTextColor.color)
                    
                    Text("\(upcomingEventCount) events")
                        .font(.custom("HelveticaNeue-Medium", size: 10))
                        .foregroundColor(theme.secondaryTextColor.color)
                }
                .padding(16)
                .background(theme.headerSurface)
                
                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.sevenDaySummary)
                        .font(.custom("HelveticaNeue", size: 12))
                        .foregroundColor(theme.primaryTextColor.color)
                        .lineLimit(4)
                    
                    // Weather forecast row
                    HStack(spacing: 12) {
                        ForEach(nextFiveDays.prefix(5), id: \.self) { date in
                            if let forecast = entry.weather.forecast(for: date) {
                                VStack(spacing: 2) {
                                    Text(dayLabel(date))
                                        .font(.custom("HelveticaNeue-Bold", size: 8))
                                        .foregroundColor(theme.secondaryTextColor.color)
                                    
                                    Image(systemName: forecast.symbolName)
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.primaryTextColor.color.opacity(0.7))
                                    
                                    Text("\(forecast.highFormatted)")
                                        .font(.custom("HelveticaNeue", size: 9))
                                        .foregroundColor(theme.primaryTextColor.color)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(theme.glassTintColor.opacity(0.04))
                    .cornerRadius(8)
                }
                .padding(16)
                
                Spacer()
            }
            .frame(width: 240)
            
            // Divider
            Rectangle()
                .fill(theme.secondaryTextColor.color.opacity(0.15))
                .frame(width: 1)
            
            // Right: Day-by-day breakdown
            VStack(alignment: .leading, spacing: 8) {
                ForEach(nextFiveDays, id: \.self) { date in
                    ExpandedDayRow(date: date, events: eventsForDay(date), weather: entry.weather, theme: theme)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .widgetURL(DeepLinkRoute.fiveDayURL())
    }
    
    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let today = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 4, to: today)!
        return "\(formatter.string(from: today)) – \(formatter.string(from: endDate))"
    }
    
    private var nextFiveDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
    
    private var upcomingEventCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 5, to: today)!
        return entry.events.filter { $0.startDate >= today && $0.startDate < endDate }.count
    }
    
    private func eventsForDay(_ date: Date) -> [ScheduleEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return entry.events.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }.sorted { $0.startDate < $1.startDate }
    }
    
    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
}

struct ExpandedDayRow: View {
    let date: Date
    let events: [ScheduleEvent]
    let weather: WeatherData?
    let theme: WidgetTheme
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Day header
            HStack {
                Text(isToday ? "TODAY" : dayLabel)
                    .font(.custom("HelveticaNeue-Bold", size: 10))
                    .foregroundColor(isToday ? .white : theme.primaryTextColor.color)
                    .padding(.horizontal, isToday ? 6 : 0)
                    .padding(.vertical, isToday ? 3 : 0)
                    .background(isToday ? Color(hex: "007AFF") : Color.clear)
                    .cornerRadius(4)
                
                Text(dateFormatted)
                    .font(.custom("HelveticaNeue", size: 9))
                    .foregroundColor(theme.secondaryTextColor.color)
                
                Spacer()
                
                // Weather
                if let forecast = weather?.forecast(for: date) {
                    HStack(spacing: 3) {
                        Image(systemName: forecast.symbolName)
                            .font(.system(size: 10))
                        Text(forecast.highFormatted)
                            .font(.custom("HelveticaNeue", size: 9))
                    }
                    .foregroundColor(theme.secondaryTextColor.color)
                }
                
                Text("\(events.count)")
                    .font(.custom("HelveticaNeue-Bold", size: 9))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(events.count > 0 ? Color(hex: "333333") : Color(hex: "CCCCCC"))
                    .cornerRadius(4)
            }
            
            // Events
            if events.isEmpty {
                Text("Free")
                    .font(.custom("HelveticaNeue", size: 9))
                    .foregroundColor(theme.secondaryTextColor.color.opacity(0.5))
                    .italic()
                    .padding(.leading, 4)
            } else {
                FlowLayout(spacing: 4) {
                    ForEach(events.prefix(8)) { event in
                        CompactEventChip(event: event, theme: theme)
                    }
                    
                    if events.count > 8 {
                        Text("+\(events.count - 8)")
                            .font(.custom("HelveticaNeue", size: 8))
                            .foregroundColor(theme.secondaryTextColor.color)
                    }
                }
            }
        }
        .padding(8)
        .background(isToday ? Color(hex: "007AFF").opacity(0.06) : Color.clear)
        .cornerRadius(8)
    }
    
    private var dayLabel: String {
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

// MARK: - Next Week View Content

struct NextWeekViewContent: View {
    let entry: ScheduleWidgetEntry
    let family: WidgetFamily
    
    var body: some View {
        switch family {
        case .systemSmall:
            NextWeekSmallView(entry: entry)
        case .systemMedium:
            NextWeekMediumView(entry: entry)
        case .systemLarge:
            NextWeekLargeView(entry: entry)
        case .systemExtraLarge:
            NextWeekExtraLargeView(entry: entry)
        default:
            NextWeekMediumView(entry: entry)
        }
    }
}

// MARK: - Next Week Extra Large View (iPad)

struct NextWeekExtraLargeView: View {
    let entry: ScheduleWidgetEntry
    
    private var theme: WidgetTheme { entry.theme }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Summary
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT WEEK")
                        .font(.custom("HelveticaNeue-Bold", size: 11))
                        .foregroundColor(Color(hex: "AF52DE"))
                        .tracking(1.5)
                    
                    Text(nextWeekRange)
                        .font(.custom("Helvetica-Bold", size: 22))
                        .foregroundColor(theme.primaryTextColor.color)
                    
                    Text("\(nextWeekEventCount) events")
                        .font(.custom("HelveticaNeue-Medium", size: 10))
                        .foregroundColor(theme.secondaryTextColor.color)
                }
                .padding(16)
                .background(theme.headerSurface)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(entry.nextWeekSummary)
                        .font(.custom("HelveticaNeue", size: 12))
                        .foregroundColor(theme.primaryTextColor.color)
                        .lineLimit(5)
                    
                    // People overview
                    VStack(alignment: .leading, spacing: 6) {
                        Text("BY PERSON")
                            .font(.custom("HelveticaNeue-Bold", size: 9))
                            .foregroundColor(theme.secondaryTextColor.color)
                            .tracking(0.5)
                        
                        ForEach(peopleWithCounts, id: \.0) { person, count in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(calendarColor(for: person))
                                    .frame(width: 8, height: 8)
                                
                                Text(person)
                                    .font(.custom("HelveticaNeue-Medium", size: 10))
                                    .foregroundColor(theme.primaryTextColor.color)
                                
                                Spacer()
                                
                                Text("\(count) events")
                                    .font(.custom("HelveticaNeue", size: 9))
                                    .foregroundColor(theme.secondaryTextColor.color)
                            }
                        }
                    }
                    .padding(12)
                    .background(theme.glassTintColor.opacity(0.04))
                    .cornerRadius(8)
                }
                .padding(16)
                
                Spacer()
            }
            .frame(width: 240)
            
            // Divider
            Rectangle()
                .fill(theme.secondaryTextColor.color.opacity(0.15))
                .frame(width: 1)
            
            // Right: Full week view
            VStack(alignment: .leading, spacing: 6) {
                ForEach(nextWeekDays, id: \.self) { date in
                    ExpandedDayRow(date: date, events: eventsForDay(date), weather: entry.weather, theme: theme)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .widgetURL(DeepLinkRoute.nextWeekURL())
    }
    
    private var nextWeekRange: String {
        let (monday, sunday) = getNextWeekDates()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: monday)) – \(formatter.string(from: sunday))"
    }
    
    private var nextWeekDays: [Date] {
        let (monday, _) = getNextWeekDates()
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: monday) }
    }
    
    private var nextWeekEventCount: Int {
        let (monday, sunday) = getNextWeekDates()
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: sunday)!
        return entry.events.filter { $0.startDate >= monday && $0.startDate < endDate }.count
    }
    
    private var nextWeekEvents: [ScheduleEvent] {
        let (monday, sunday) = getNextWeekDates()
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: sunday)!
        return entry.events.filter { $0.startDate >= monday && $0.startDate < endDate }
    }
    
    private var peopleWithCounts: [(String, Int)] {
        let grouped = Dictionary(grouping: nextWeekEvents) { $0.clientName }
        let priority = ["Theo", "Adam", "Hudson", "Tom", "Ruby", "Conall", "Leon"]
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { p1, p2 in
                let idx1 = priority.firstIndex(of: p1.0) ?? 999
                let idx2 = priority.firstIndex(of: p2.0) ?? 999
                return idx1 < idx2
            }
    }
    
    private func eventsForDay(_ date: Date) -> [ScheduleEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return entry.events.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }.sorted { $0.startDate < $1.startDate }
    }
    
    private func getNextWeekDates() -> (Date, Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        
        var nextMonday = calendar.startOfDay(for: Date())
        while calendar.component(.weekday, from: nextMonday) != 2 {
            nextMonday = calendar.date(byAdding: .day, value: 1, to: nextMonday)!
        }
        if calendar.component(.weekday, from: Date()) == 2 {
            nextMonday = calendar.date(byAdding: .day, value: 7, to: nextMonday)!
        }
        
        let nextSunday = calendar.date(byAdding: .day, value: 6, to: nextMonday)!
        return (nextMonday, nextSunday)
    }
    
    private func calendarColor(for clientName: String) -> Color {
        switch clientName.lowercased() {
        case "theo": return Color(hex: "007AFF")
        case "adam": return Color(hex: "FF9500")
        case "hudson": return Color(hex: "34C759")
        case "tom": return Color(hex: "FF3B30")
        case "ruby": return Color(hex: "AF52DE")
        case "conall": return Color(hex: "FF2D55")
        case "leon": return Color(hex: "5856D6")
        case "jack × theo", "jack x theo": return Color(hex: "00C7BE")
        default: return Color(hex: "8E8E93")
        }
    }
}

// MARK: - 5-Day Small View

struct SevenDaySmallView: View {
    let entry: ScheduleWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header - consistent style
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("5-DAY OUTLOOK")
                        .font(.custom("HelveticaNeue-Bold", size: 9))
                        .foregroundColor(Color(hex: "888888"))
                        .tracking(1)
                    
                    Text(dateRange)
                        .font(.custom("HelveticaNeue-Bold", size: 14))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                WeatherClusterView(weather: entry.weather, size: .small)
            }
            
            Spacer(minLength: 4)
            
            MarkdownText(entry.sevenDaySummary, fontSize: 11, lineLimit: 5)
            
            Spacer()
            
            Text("\(upcomingEventCount) events")
                .font(.custom("HelveticaNeue", size: 10))
                .foregroundColor(Color(hex: "666666"))
        }
        .padding(12)
        .widgetURL(DeepLinkRoute.fiveDayURL())
    }
    
    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let today = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 4, to: today)!
        return "\(formatter.string(from: today)) – \(formatter.string(from: endDate))"
    }
    
    private var upcomingEventCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 5, to: today)!
        return entry.events.filter { $0.startDate >= today && $0.startDate < endDate }.count
    }
}

// MARK: - 5-Day Medium View

struct SevenDayMediumView: View {
    let entry: ScheduleWidgetEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                // Header - consistent style
                VStack(alignment: .leading, spacing: 2) {
                    Text("5-DAY OUTLOOK")
                        .font(.custom("HelveticaNeue-Bold", size: 9))
                        .foregroundColor(Color(hex: "888888"))
                        .tracking(1)
                    
                    Text(dateRange)
                        .font(.custom("HelveticaNeue-Bold", size: 16))
                        .foregroundColor(.black)
                    
                    Text("\(upcomingEventCount) events")
                        .font(.custom("HelveticaNeue", size: 10))
                        .foregroundColor(Color(hex: "666666"))
                }
                
                Spacer(minLength: 4)
                
                MarkdownText(entry.sevenDaySummary, fontSize: 12, lineLimit: 4)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .trailing, spacing: 8) {
                WeatherClusterView(weather: entry.weather, size: .medium)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    ForEach(nextFiveDays, id: \.self) { date in
                        DayIndicatorRow(date: date, events: eventsForDay(date))
                    }
                }
            }
            .frame(width: 80)
        }
        .padding(12)
        .widgetURL(DeepLinkRoute.fiveDayURL())
    }
    
    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let today = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 4, to: today)!
        return "\(formatter.string(from: today)) – \(formatter.string(from: endDate))"
    }
    
    private var nextFiveDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
    
    private var upcomingEventCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 5, to: today)!
        return entry.events.filter { $0.startDate >= today && $0.startDate < endDate }.count
    }
    
    private func eventsForDay(_ date: Date) -> [ScheduleEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return entry.events.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }
    }
}

// MARK: - 5-Day Large View (was 7-day, reduced to fit)

struct SevenDayLargeView: View {
    let entry: ScheduleWidgetEntry
    
    private var theme: WidgetTheme { entry.theme }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // Header - edge-to-edge ribbon
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("5-DAY OUTLOOK")
                            .font(.custom("HelveticaNeue-Bold", size: 10))
                            .foregroundColor(Color(hex: "34C759"))
                            .tracking(1.5)
                        
                        Text(dateRange)
                            .font(.custom("Helvetica-Bold", size: 18))
                            .foregroundColor(.black)
                            .tracking(-2)
                        
                        Text("\(upcomingEventCount) EVENTS")
                            .font(.custom("HelveticaNeue-Medium", size: 9))
                            .foregroundColor(Color(hex: "888888"))
                            .tracking(1)
                    }
                    
                    Spacer()
                    
                    WeatherClusterView(weather: entry.weather, size: .medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(theme.headerSurface)
                
                // Day rows - overflow clips at bottom
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(nextFiveDays, id: \.self) { date in
                        DayEventBlock(date: date, events: eventsForDay(date), weather: entry.weather, theme: theme)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .clipped()
        .widgetURL(DeepLinkRoute.fiveDayURL())
    }
    
    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let today = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 4, to: today)!
        return "\(formatter.string(from: today)) – \(formatter.string(from: endDate))".uppercased()
    }
    
    private var nextFiveDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
    
    private var upcomingEventCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 5, to: today)!
        return entry.events.filter { $0.startDate >= today && $0.startDate < endDate }.count
    }
    
    private func eventsForDay(_ date: Date) -> [ScheduleEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return entry.events.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }.sorted { $0.startDate < $1.startDate }
    }
}

// MARK: - Day Event Block (allows wrapping to multiple lines)

struct DayEventBlock: View {
    let date: Date
    let events: [ScheduleEvent]
    let weather: WeatherData?
    let theme: WidgetTheme
    
    init(date: Date, events: [ScheduleEvent], weather: WeatherData? = nil, theme: WidgetTheme) {
        self.date = date
        self.events = events
        self.weather = weather
        self.theme = theme
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var dayForecast: DailyForecast? {
        weather?.forecast(for: date)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // Day label on the left
            VStack(alignment: .leading, spacing: 1) {
                Text(dayLabel)
                    .font(.custom("HelveticaNeue-Bold", size: 9))
                    .foregroundColor(isToday ? .white : Color(hex: "555555"))
                    .padding(.horizontal, isToday ? 4 : 0)
                    .padding(.vertical, isToday ? 2 : 0)
                    .background(isToday ? Color(hex: "007AFF") : Color.clear)
                    .cornerRadius(3)
                
                // Mini weather for the day
                if let forecast = dayForecast {
                    MiniDayWeather(forecast: forecast)
                }
            }
            .frame(width: 44, alignment: .leading)
            
            // Events - flow and wrap
            if events.isEmpty {
                Text("— Free")
                    .font(.custom("HelveticaNeue", size: 9))
                    .foregroundColor(Color(hex: "BBBBBB"))
                    .italic()
            } else {
                // Wrap events in a flexible layout
                FlowLayout(spacing: 4) {
                    ForEach(events.prefix(6)) { event in
                        CompactEventChip(event: event, theme: theme)
                    }
                    
                    if events.count > 6 {
                        Text("+\(events.count - 6)")
                            .font(.custom("HelveticaNeue", size: 8))
                            .foregroundColor(Color(hex: "999999"))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(isToday ? Color(hex: "007AFF").opacity(0.06) : Color.clear)
        .cornerRadius(6)
    }
    
    private var dayLabel: String {
        if isToday {
            return "TODAY"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - Compact Event Chip

struct CompactEventChip: View {
    let event: ScheduleEvent
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(calendarColor)
                .frame(width: 5, height: 5)
            
            Text(shortTime)
                .font(.custom("HelveticaNeue", size: 8))
                .foregroundColor(Color(hex: "666666"))
            
            Text(clientInitial)
                .font(.custom("HelveticaNeue-Bold", size: 7))
                .foregroundColor(.white)
                .frame(width: 11, height: 11)
                .background(calendarColor)
                .cornerRadius(2)
            
            Text(event.title)
                .font(.custom("HelveticaNeue", size: 8))
                .foregroundColor(Color(hex: "333333"))
                .lineLimit(1)
                .frame(maxWidth: 80)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(chipBackground)
        .cornerRadius(4)
    }
    
    private var shortTime: String {
        if event.isAllDay {
            return "All"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: event.startDate)
    }
    
    private var clientInitial: String {
        switch event.clientName.lowercased() {
        case "theo": return "T"
        case "adam": return "A"
        case "hudson": return "H"
        case "tom": return "T"
        case "ruby": return "R"
        case "conall": return "C"
        case "leon": return "L"
        case "jack × theo", "jack x theo": return "J"
        default: return String(event.clientName.prefix(1)).uppercased()
        }
    }
    
    private var calendarColor: Color {
        switch event.clientName.lowercased() {
        case "theo": return Color(hex: "007AFF")
        case "adam": return Color(hex: "FF9500")
        case "hudson": return Color(hex: "34C759")
        case "tom": return Color(hex: "FF3B30")
        case "ruby": return Color(hex: "AF52DE")
        case "conall": return Color(hex: "FF2D55")
        case "leon": return Color(hex: "5856D6")
        case "jack × theo", "jack x theo": return Color(hex: "00C7BE")
        default: return Color(hex: "8E8E93")
        }
    }
    
    private var chipBackground: Color {
        theme.useTransparentBackground
            ? theme.glassTintColor.opacity(0.15)
            : Color(hex: "F5F5F5")
    }
}

// MARK: - Flow Layout (wrapping horizontal layout)

struct FlowLayout: Layout {
    var spacing: CGFloat = 4
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            if index < result.positions.count {
                let position = result.positions[index]
                subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
            }
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }
        
        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

// MARK: - Inline Event Item (super compact)

struct InlineEventItem: View {
    let event: ScheduleEvent
    
    var body: some View {
        HStack(spacing: 3) {
            // Color dot
            Circle()
                .fill(calendarColor)
                .frame(width: 5, height: 5)
            
            // Short time
            Text(shortTime)
                .font(.custom("HelveticaNeue", size: 8))
                .foregroundColor(Color(hex: "888888"))
            
            // Client initial badge
            Text(clientInitial)
                .font(.custom("HelveticaNeue-Bold", size: 7))
                .foregroundColor(.white)
                .frame(width: 11, height: 11)
                .background(calendarColor)
                .cornerRadius(2)
            
            // Truncated title
            Text(event.title)
                .font(.custom("HelveticaNeue", size: 8))
                .foregroundColor(Color(hex: "444444"))
                .lineLimit(1)
                .frame(maxWidth: 70, alignment: .leading)
        }
    }
    
    private var shortTime: String {
        if event.isAllDay {
            return "All"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: event.startDate)
    }
    
    private var clientInitial: String {
        switch event.clientName.lowercased() {
        case "theo": return "T"
        case "adam": return "A"
        case "hudson": return "H"
        case "tom": return "T"
        case "ruby": return "R"
        case "conall": return "C"
        case "leon": return "L"
        case "jack × theo", "jack x theo": return "J"
        default: return String(event.clientName.prefix(1)).uppercased()
        }
    }
    
    private var calendarColor: Color {
        switch event.clientName.lowercased() {
        case "theo": return Color(hex: "007AFF")
        case "adam": return Color(hex: "FF9500")
        case "hudson": return Color(hex: "34C759")
        case "tom": return Color(hex: "FF3B30")
        case "ruby": return Color(hex: "AF52DE")
        case "conall": return Color(hex: "FF2D55")
        case "leon": return Color(hex: "5856D6")
        case "jack × theo", "jack x theo": return Color(hex: "00C7BE")
        default: return Color(hex: "8E8E93")
        }
    }
}

// MARK: - Next Week Small View

struct NextWeekSmallView: View {
    let entry: ScheduleWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NEXT WEEK")
                .font(.custom("HelveticaNeue-Bold", size: 10))
                .foregroundColor(Color(hex: "666666"))
                .tracking(1)
            
            Text(nextWeekRange)
                .font(.custom("HelveticaNeue-Bold", size: 11))
                .foregroundColor(.black)
            
            Spacer(minLength: 4)
            
            MarkdownText(entry.nextWeekSummary, fontSize: 11, lineLimit: 5)
            
            Spacer()
            
            Text("\(nextWeekEventCount) events")
                .font(.custom("HelveticaNeue", size: 10))
                .foregroundColor(Color(hex: "666666"))
        }
        .padding(12)
        .widgetURL(DeepLinkRoute.nextWeekURL())
    }
    
    private var nextWeekRange: String {
        let (monday, sunday) = getNextWeekDates()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: monday)) – \(formatter.string(from: sunday))"
    }
    
    private var nextWeekEventCount: Int {
        let (monday, sunday) = getNextWeekDates()
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: sunday)!
        return entry.events.filter { $0.startDate >= monday && $0.startDate < endDate }.count
    }
    
    private func getNextWeekDates() -> (Date, Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        
        var nextMonday = Date()
        while calendar.component(.weekday, from: nextMonday) != 2 {
            nextMonday = calendar.date(byAdding: .day, value: 1, to: nextMonday)!
        }
        if calendar.component(.weekday, from: Date()) == 2 {
            nextMonday = calendar.date(byAdding: .day, value: 7, to: nextMonday)!
        }
        
        let nextSunday = calendar.date(byAdding: .day, value: 6, to: nextMonday)!
        return (nextMonday, nextSunday)
    }
}

// MARK: - Next Week Medium View

struct NextWeekMediumView: View {
    let entry: ScheduleWidgetEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("NEXT WEEK")
                    .font(.custom("HelveticaNeue-Bold", size: 10))
                    .foregroundColor(Color(hex: "666666"))
                    .tracking(1)
                
                Text(nextWeekRange)
                    .font(.custom("HelveticaNeue-Bold", size: 12))
                    .foregroundColor(.black)
                
                Spacer(minLength: 4)
                
                MarkdownText(entry.nextWeekSummary, fontSize: 12, lineLimit: 4)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .trailing, spacing: 3) {
                ForEach(nextWeekDays, id: \.self) { date in
                    DayIndicatorRow(date: date, events: eventsForDay(date))
                }
            }
            .frame(width: 80)
        }
        .padding(14)
        .widgetURL(DeepLinkRoute.nextWeekURL())
    }
    
    private var nextWeekRange: String {
        let (monday, sunday) = getNextWeekDates()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: monday)) – \(formatter.string(from: sunday))"
    }
    
    private var nextWeekDays: [Date] {
        let (monday, _) = getNextWeekDates()
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: monday) }
    }
    
    private func eventsForDay(_ date: Date) -> [ScheduleEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return entry.events.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }
    }
    
    private func getNextWeekDates() -> (Date, Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        
        var nextMonday = Date()
        while calendar.component(.weekday, from: nextMonday) != 2 {
            nextMonday = calendar.date(byAdding: .day, value: 1, to: nextMonday)!
        }
        if calendar.component(.weekday, from: Date()) == 2 {
            nextMonday = calendar.date(byAdding: .day, value: 7, to: nextMonday)!
        }
        
        let nextSunday = calendar.date(byAdding: .day, value: 6, to: nextMonday)!
        return (nextMonday, nextSunday)
    }
}

// MARK: - Next Week Large View

struct NextWeekLargeView: View {
    let entry: ScheduleWidgetEntry
    
    private var theme: WidgetTheme { entry.theme }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // Header - edge-to-edge ribbon
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("NEXT WEEK")
                            .font(.custom("HelveticaNeue-Bold", size: 10))
                            .foregroundColor(Color(hex: "AF52DE"))
                            .tracking(1.5)
                        
                        Text(nextWeekRange)
                            .font(.custom("Helvetica-Bold", size: 18))
                            .foregroundColor(.black)
                            .tracking(-2)
                        
                        Text("\(nextWeekEventCount) EVENTS")
                            .font(.custom("HelveticaNeue-Medium", size: 9))
                            .foregroundColor(Color(hex: "888888"))
                            .tracking(1)
                    }
                    
                    Spacer()
                    
                    WeatherClusterView(weather: entry.weather, size: .medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(theme.headerSurface)
                
                // Day rows - overflow clips at bottom
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(nextWeekDays, id: \.self) { date in
                        NextWeekDayRow(date: date, events: eventsForDay(date), weather: entry.weather, theme: theme)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .clipped()
        .widgetURL(DeepLinkRoute.nextWeekURL())
    }
    
    private var nextWeekRange: String {
        let (monday, sunday) = getNextWeekDates()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: monday)) – \(formatter.string(from: sunday))".uppercased()
    }
    
    private var nextWeekDays: [Date] {
        let (monday, _) = getNextWeekDates()
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: monday) }
    }
    
    private var nextWeekEventCount: Int {
        let (monday, sunday) = getNextWeekDates()
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: sunday)!
        return entry.events.filter { $0.startDate >= monday && $0.startDate < endDate }.count
    }
    
    private func eventsForDay(_ date: Date) -> [ScheduleEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return entry.events.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }.sorted { $0.startDate < $1.startDate }
    }
    
    private func getNextWeekDates() -> (Date, Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        
        var nextMonday = calendar.startOfDay(for: Date())
        // Find the next Monday
        while calendar.component(.weekday, from: nextMonday) != 2 {
            nextMonday = calendar.date(byAdding: .day, value: 1, to: nextMonday)!
        }
        // If today IS Monday, go to next week's Monday
        if calendar.component(.weekday, from: Date()) == 2 {
            nextMonday = calendar.date(byAdding: .day, value: 7, to: nextMonday)!
        }
        
        let nextSunday = calendar.date(byAdding: .day, value: 6, to: nextMonday)!
        return (nextMonday, nextSunday)
    }
}

// MARK: - Next Week Day Row (no times, more compact)

struct NextWeekDayRow: View {
    let date: Date
    let events: [ScheduleEvent]
    let weather: WeatherData?
    let theme: WidgetTheme
    
    init(date: Date, events: [ScheduleEvent], weather: WeatherData? = nil, theme: WidgetTheme) {
        self.date = date
        self.events = events
        self.weather = weather
        self.theme = theme
    }
    
    private var dayForecast: DailyForecast? {
        weather?.forecast(for: date)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // Day label with mini weather
            VStack(alignment: .leading, spacing: 1) {
                Text(dayLabel)
                    .font(.custom("HelveticaNeue-Bold", size: 9))
                    .foregroundColor(Color(hex: "555555"))
                
                // Mini weather for the day
                if let forecast = dayForecast {
                    MiniDayWeather(forecast: forecast)
                }
            }
            .frame(width: 38, alignment: .leading)
            
            // Events - compact chips without time
            if events.isEmpty {
                Text("— Free")
                    .font(.custom("HelveticaNeue", size: 9))
                    .foregroundColor(Color(hex: "BBBBBB"))
                    .italic()
            } else {
                FlowLayout(spacing: 3) {
                    ForEach(events.prefix(8)) { event in
                        NoTimeEventChip(event: event, theme: theme)
                    }
                    
                    if events.count > 8 {
                        Text("+\(events.count - 8)")
                            .font(.custom("HelveticaNeue", size: 8))
                            .foregroundColor(Color(hex: "999999"))
                            .padding(.horizontal, 3)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
    }
    
    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - No Time Event Chip (for Next Week view)

struct NoTimeEventChip: View {
    let event: ScheduleEvent
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 2) {
            Text(clientInitial)
                .font(.custom("HelveticaNeue-Bold", size: 7))
                .foregroundColor(.white)
                .frame(width: 11, height: 11)
                .background(calendarColor)
                .cornerRadius(2)
            
            Text(event.title)
                .font(.custom("HelveticaNeue", size: 8))
                .foregroundColor(Color(hex: "333333"))
                .lineLimit(1)
                .frame(maxWidth: 75)
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
        .background(theme.useTransparentBackground ? theme.glassTintColor.opacity(0.12) : Color(hex: "F0F0F0"))
        .cornerRadius(4)
    }
    
    private var clientInitial: String {
        switch event.clientName.lowercased() {
        case "theo": return "T"
        case "adam": return "A"
        case "hudson": return "H"
        case "tom": return "T"
        case "ruby": return "R"
        case "conall": return "C"
        case "leon": return "L"
        case "jack × theo", "jack x theo": return "J"
        default: return String(event.clientName.prefix(1)).uppercased()
        }
    }
    
    private var calendarColor: Color {
        switch event.clientName.lowercased() {
        case "theo": return Color(hex: "007AFF")
        case "adam": return Color(hex: "FF9500")
        case "hudson": return Color(hex: "34C759")
        case "tom": return Color(hex: "FF3B30")
        case "ruby": return Color(hex: "AF52DE")
        case "conall": return Color(hex: "FF2D55")
        case "leon": return Color(hex: "5856D6")
        case "jack × theo", "jack x theo": return Color(hex: "00C7BE")
        default: return Color(hex: "8E8E93")
        }
    }
}

// MARK: - Helper Views

struct DayIndicatorRow: View {
    let date: Date
    let events: [ScheduleEvent]
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // Unique clients for this day
    private var uniqueClients: [String] {
        Array(Set(events.map { $0.clientName })).sorted { lhs, rhs in
            if lhs.lowercased() == "theo" { return true }
            if rhs.lowercased() == "theo" { return false }
            return lhs < rhs
        }
    }
    
    var body: some View {
        HStack(spacing: 3) {
            Text(dayName)
                .font(.custom(isToday ? "HelveticaNeue-Bold" : "HelveticaNeue", size: 9))
                .foregroundColor(isToday ? .black : Color(hex: "666666"))
                .frame(width: 22, alignment: .leading)
            
            // Show client initials as mini pills
            HStack(spacing: 2) {
                ForEach(uniqueClients.prefix(3), id: \.self) { client in
                    Text(clientInitial(for: client))
                        .font(.custom("HelveticaNeue-Bold", size: 7))
                        .foregroundColor(.white)
                        .frame(width: 12, height: 12)
                        .background(calendarColor(for: client))
                        .cornerRadius(2)
                }
                if uniqueClients.count > 3 {
                    Text("+")
                        .font(.custom("HelveticaNeue", size: 7))
                        .foregroundColor(Color(hex: "888888"))
                }
            }
            
            if isToday {
                Circle()
                    .fill(Color(hex: "007AFF"))
                    .frame(width: 4, height: 4)
            }
        }
    }
    
    private func clientInitial(for name: String) -> String {
        switch name.lowercased() {
        case "theo": return "T"
        case "adam": return "A"
        case "hudson": return "H"
        case "tom": return "T"
        case "ruby": return "R"
        case "conall": return "C"
        case "leon": return "L"
        case "jack × theo", "jack x theo": return "J"
        default: return String(name.prefix(1)).uppercased()
        }
    }
    
    private func calendarColor(for clientName: String) -> Color {
        switch clientName.lowercased() {
        case "theo": return Color(hex: "007AFF")
        case "adam": return Color(hex: "FF9500")
        case "hudson": return Color(hex: "34C759")
        case "tom": return Color(hex: "FF3B30")
        case "ruby": return Color(hex: "AF52DE")
        case "conall": return Color(hex: "FF2D55")
        case "leon": return Color(hex: "5856D6")
        case "jack × theo", "jack x theo": return Color(hex: "00C7BE")
        default: return Color(hex: "8E8E93")
        }
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct SevenDayRowView: View {
    let date: Date
    let events: [ScheduleEvent]
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // Group events by client
    private var eventsByClient: [(client: String, count: Int)] {
        var grouped: [String: Int] = [:]
        for event in events {
            grouped[event.clientName, default: 0] += 1
        }
        // Sort: Theo first, then alphabetically
        return grouped.sorted { lhs, rhs in
            if lhs.key.lowercased() == "theo" { return true }
            if rhs.key.lowercased() == "theo" { return false }
            return lhs.key < rhs.key
        }.map { (client: $0.key, count: $0.value) }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Day name
            Text(dayName)
                .font(.custom(isToday ? "HelveticaNeue-Bold" : "HelveticaNeue", size: 10))
                .foregroundColor(isToday ? .black : Color(hex: "666666"))
                .frame(width: 26, alignment: .leading)
            
            // Event count
            Text("\(events.count)")
                .font(.custom("HelveticaNeue-Bold", size: 9))
                .foregroundColor(.white)
                .frame(width: 16, height: 16)
                .background(events.count > 0 ? Color(hex: "333333") : Color(hex: "CCCCCC"))
                .cornerRadius(4)
            
            // Client pills - stacked compactly
            if events.isEmpty {
                Text("Free")
                    .font(.custom("HelveticaNeue", size: 9))
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .italic()
            } else {
                HStack(spacing: 3) {
                    ForEach(eventsByClient.prefix(3), id: \.client) { item in
                        ClientPill(
                            name: item.client,
                            count: item.count,
                            color: calendarColor(for: item.client)
                        )
                    }
                    
                    if eventsByClient.count > 3 {
                        Text("+\(eventsByClient.count - 3)")
                            .font(.custom("HelveticaNeue", size: 8))
                            .foregroundColor(Color(hex: "888888"))
                    }
                }
            }
            
            Spacer()
            
            if isToday {
                Text("TODAY")
                    .font(.custom("HelveticaNeue-Bold", size: 7))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(hex: "007AFF"))
                    .cornerRadius(3)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isToday ? Color(hex: "007AFF").opacity(0.08) : Color.clear)
        .cornerRadius(6)
    }
    
    private func calendarColor(for clientName: String) -> Color {
        switch clientName.lowercased() {
        case "theo": return Color(hex: "007AFF")
        case "adam": return Color(hex: "FF9500")
        case "hudson": return Color(hex: "34C759")
        case "tom": return Color(hex: "FF3B30")
        case "ruby": return Color(hex: "AF52DE")
        case "conall": return Color(hex: "FF2D55")
        case "leon": return Color(hex: "5856D6")
        case "jack × theo", "jack x theo": return Color(hex: "00C7BE")
        default: return Color(hex: "8E8E93")
        }
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Client Pill (compact client indicator)

struct ClientPill: View {
    let name: String
    let count: Int
    let color: Color
    
    // Get short name (first 3-4 chars or initials)
    private var shortName: String {
        let lower = name.lowercased()
        switch lower {
        case "theo": return "T"
        case "adam": return "A"
        case "hudson": return "H"
        case "tom": return "TM"
        case "ruby": return "R"
        case "conall": return "C"
        case "leon": return "L"
        case "jack × theo", "jack x theo": return "J×T"
        default: return String(name.prefix(2)).uppercased()
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Text(shortName)
                .font(.custom("HelveticaNeue-Bold", size: 8))
            
            if count > 1 {
                Text("×\(count)")
                    .font(.custom("HelveticaNeue", size: 7))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(color)
        .cornerRadius(3)
    }
}

// MARK: - Preview

struct AMFScheduleWidget_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleWidgetEntryView(entry: .placeholder(viewType: .today))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

