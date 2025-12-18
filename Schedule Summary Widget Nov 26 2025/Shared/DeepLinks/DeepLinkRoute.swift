//
//  DeepLinkRoute.swift
//  AMF Schedule
//
//  Canonical deep link routing system for widget-to-app navigation
//

import Foundation

// MARK: - Deep Link Destination

/// Represents the possible destinations from a deep link
enum DeepLinkDestination: Equatable {
    case today(date: Date?)
    case fiveDay(anchor: Date?)
    case nextWeek(anchor: Date?)
    case event(id: String, date: Date?)
    
    /// User-facing display name for this destination
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .fiveDay: return "5-Day Outlook"
        case .nextWeek: return "Next Week"
        case .event: return "Event"
        }
    }
}

// MARK: - Deep Link Route

/// Handles parsing and generation of canonical deep link URLs
struct DeepLinkRoute {
    
    // MARK: - URL Scheme
    
    static let scheme = "amfschedule"
    static let host = "open"
    
    // MARK: - View Parameter Values
    
    private enum ViewType: String {
        case today
        case fiveDay
        case nextWeek
        case event
    }
    
    // MARK: - Parse URL to Destination
    
    /// Parses a URL into a deep link destination
    /// Supports both canonical URLs and legacy URLs for backwards compatibility
    static func parse(_ url: URL) -> DeepLinkDestination? {
        guard url.scheme == scheme else { return nil }
        
        // Try canonical format first: amfschedule://open?view=today&date=YYYY-MM-DD
        if url.host == host {
            return parseCanonicalURL(url)
        }
        
        // Fall back to legacy format: amfschedule://today, amfschedule://week, etc.
        return parseLegacyURL(url)
    }
    
    /// Parses canonical URL format: amfschedule://open?view=...&date=...
    private static func parseCanonicalURL(_ url: URL) -> DeepLinkDestination? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        // Extract parameters
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item -> (String, String)? in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })
        
        guard let viewString = params["view"],
              let viewType = ViewType(rawValue: viewString) else {
            return nil
        }
        
        let date = params["date"].flatMap { parseDate($0) }
        let eventId = params["id"]
        
        switch viewType {
        case .today:
            return .today(date: date)
        case .fiveDay:
            return .fiveDay(anchor: date)
        case .nextWeek:
            return .nextWeek(anchor: date)
        case .event:
            guard let id = eventId else { return nil }
            return .event(id: id, date: date)
        }
    }
    
    /// Parses legacy URL format for backwards compatibility
    private static func parseLegacyURL(_ url: URL) -> DeepLinkDestination? {
        // Legacy URLs use the host as the action:
        // - amfschedule://today
        // - amfschedule://week
        // - amfschedule://sevenday
        // - amfschedule://nextweek
        guard let host = url.host?.lowercased() else { return nil }
        
        switch host {
        case "today":
            return .today(date: nil)
        case "week", "sevenday", "fiveday", "5day":
            return .fiveDay(anchor: nil)
        case "nextweek", "next-week":
            return .nextWeek(anchor: nil)
        default:
            return nil
        }
    }
    
    // MARK: - Generate URL from Destination
    
    /// Creates a canonical URL for a given destination
    static func makeURL(_ destination: DeepLinkDestination) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        
        var queryItems: [URLQueryItem] = []
        
        switch destination {
        case .today(let date):
            queryItems.append(URLQueryItem(name: "view", value: ViewType.today.rawValue))
            if let date = date {
                queryItems.append(URLQueryItem(name: "date", value: formatDate(date)))
            }
            
        case .fiveDay(let anchor):
            queryItems.append(URLQueryItem(name: "view", value: ViewType.fiveDay.rawValue))
            if let anchor = anchor {
                queryItems.append(URLQueryItem(name: "date", value: formatDate(anchor)))
            }
            
        case .nextWeek(let anchor):
            queryItems.append(URLQueryItem(name: "view", value: ViewType.nextWeek.rawValue))
            if let anchor = anchor {
                queryItems.append(URLQueryItem(name: "date", value: formatDate(anchor)))
            }
            
        case .event(let id, let date):
            queryItems.append(URLQueryItem(name: "view", value: ViewType.event.rawValue))
            queryItems.append(URLQueryItem(name: "id", value: id))
            if let date = date {
                queryItems.append(URLQueryItem(name: "date", value: formatDate(date)))
            }
        }
        
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        // Force unwrap is safe here because we're constructing a valid URL
        return components.url!
    }
    
    // MARK: - Convenience URL Generators
    
    /// Creates a URL for opening the Today view
    static func todayURL(date: Date? = nil) -> URL {
        makeURL(.today(date: date))
    }
    
    /// Creates a URL for opening the 5-Day Outlook view
    static func fiveDayURL(date: Date? = nil) -> URL {
        makeURL(.fiveDay(anchor: date))
    }
    
    /// Creates a URL for opening the Next Week view
    static func nextWeekURL(date: Date? = nil) -> URL {
        makeURL(.nextWeek(anchor: date))
    }
    
    /// Creates a URL for opening a specific event
    static func eventURL(id: String, date: Date? = nil) -> URL {
        makeURL(.event(id: id, date: date))
    }
    
    /// Creates a URL for opening a specific day (defaults to Today view)
    static func dayURL(_ date: Date) -> URL {
        makeURL(.today(date: date))
    }
    
    // MARK: - Date Formatting
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    private static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
    
    private static func parseDate(_ string: String) -> Date? {
        dateFormatter.date(from: string)
    }
}

// MARK: - URL Extension for Deep Links

extension URL {
    /// Checks if this URL is an AMF Schedule deep link
    var isAMFScheduleDeepLink: Bool {
        scheme == DeepLinkRoute.scheme
    }
    
    /// Parses this URL as an AMF Schedule deep link destination
    var deepLinkDestination: DeepLinkDestination? {
        DeepLinkRoute.parse(self)
    }
}
