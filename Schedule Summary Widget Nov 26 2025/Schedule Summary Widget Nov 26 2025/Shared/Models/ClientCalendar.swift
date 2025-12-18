//
//  ClientCalendar.swift
//  AMF Schedule
//
//  Client calendar configuration with embedded credentials
//

import Foundation

/// Represents a client's calendar configuration
struct ClientCalendar: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let calendarId: String
    let source: CalendarSourceType
    let color: String
    let sortOrder: Int
    
    enum CalendarSourceType: String, Codable {
        case google
        case icloud
    }
    
    /// Deep link URL to open this client's calendar
    var calendarDeepLink: URL? {
        switch source {
        case .google:
            // Opens Google Calendar app or web
            return URL(string: "googlecalendar://")
        case .icloud:
            // Opens Apple Calendar app
            return URL(string: "calshow://")
        }
    }
}

/// Pre-configured client calendars with real credentials
struct ClientCalendars {
    
    /// All configured client calendars in display order
    /// Order: Theo first → then clients alphabetical → JACK × THEO last
    static let all: [ClientCalendar] = [
        // Theo (primary) - First
        ClientCalendar(
            id: "theo",
            name: "Theo",
            calendarId: "theo@allmyfriendsinc.com",
            source: .google,
            color: "#000000",
            sortOrder: 0
        ),
        
        // Clients alphabetically
        ClientCalendar(
            id: "adam",
            name: "Adam",
            calendarId: "mixedmanagement.com_srjbj5qn2pqr58rngcu88aruf0@group.calendar.google.com",
            source: .google,
            color: "#333333",
            sortOrder: 1
        ),
        
        ClientCalendar(
            id: "conall",
            name: "Conall",
            calendarId: "c_e0137e9b47187e28b634ae2e074bdcc5b8df6bdf0c54cd0f4f1379ea58578fed@group.calendar.google.com",
            source: .google,
            color: "#333333",
            sortOrder: 2
        ),
        
        ClientCalendar(
            id: "hudson",
            name: "Hudson",
            calendarId: "c_160f7987c0107a7996dc0ad5f1c3ccbce7bece10b7828e6da5dff2bb6279f2b6@group.calendar.google.com",
            source: .google,
            color: "#333333",
            sortOrder: 3
        ),
        
        ClientCalendar(
            id: "ruby",
            name: "Ruby",
            calendarId: "c_0299ce218cb9a83dcb3ae64b3c349d0595c50f8449e8ef8be63128d34bef05e7@group.calendar.google.com",
            source: .google,
            color: "#333333",
            sortOrder: 4
        ),
        
        ClientCalendar(
            id: "tom",
            name: "Tom",
            calendarId: "c_781d3afd4ef46456a9cb97c290fdeea3e12ab6f9b0877b715428c40138dd2e4e@group.calendar.google.com",
            source: .google,
            color: "#333333",
            sortOrder: 5
        ),
        
        // JACK × THEO (iCloud) - Last
        ClientCalendar(
            id: "jack-theo",
            name: "JACK × THEO",
            calendarId: "JACK × THEO", // EventKit calendar title match
            source: .icloud,
            color: "#333333",
            sortOrder: 6
        )
    ]
    
    /// Google calendars only
    static var googleCalendars: [ClientCalendar] {
        all.filter { $0.source == .google }
    }
    
    /// iCloud calendars only
    static var icloudCalendars: [ClientCalendar] {
        all.filter { $0.source == .icloud }
    }
    
    /// Find calendar by ID
    static func find(byId id: String) -> ClientCalendar? {
        all.first { $0.id == id }
    }
    
    /// Find calendar by calendar ID (Google or iCloud identifier)
    static func find(byCalendarId calendarId: String) -> ClientCalendar? {
        all.first { $0.calendarId == calendarId }
    }
}

