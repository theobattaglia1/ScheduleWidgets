//
//  CalendarService.swift
//  AMF Schedule
//
//  Unified calendar service combining Google Calendar and EventKit (iCloud)
//

import Foundation
import EventKit

/// Unified calendar service for fetching events from all sources
final class CalendarService {
    
    // MARK: - Singleton
    
    static let shared = CalendarService()
    
    // MARK: - Dependencies
    
    private let googleAPI = GoogleCalendarAPI.shared
    private let eventStore = EKEventStore()
    private let store = AppGroupStore.shared
    
    #if DEBUG
    private let debugLogging = true
    #else
    private let debugLogging = false
    #endif
    
    private init() {}
    
    private func log(_ message: String) {
        if debugLogging {
            print("[CalendarService] \(message)")
        }
    }
    
    // MARK: - EventKit Authorization
    
    /// Check EventKit authorization status
    var eventKitAuthorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }
    
    /// Check if EventKit is authorized (handles iOS 17+ fullAccess)
    var isEventKitAuthorized: Bool {
        let status = eventKitAuthorizationStatus
        if #available(iOS 17.0, *) {
            return status == .fullAccess || status == .authorized
        } else {
            return status == .authorized
        }
    }
    
    /// Request EventKit access
    func requestEventKitAccess() async throws -> Bool {
        let currentStatus = eventKitAuthorizationStatus
        print("[CalendarService] 📅 Current EventKit status: \(currentStatus.rawValue)")
        
        // If already authorized, return true
        if isEventKitAuthorized {
            print("[CalendarService] ✓ Already authorized")
            return true
        }
        
        // If denied, user must go to Settings
        if currentStatus == .denied {
            print("[CalendarService] ⚠️ Access denied - user must enable in Settings > Privacy > Calendars")
            return false
        }
        
        // Request access
        print("[CalendarService] 📅 Requesting EventKit access...")
        
        if #available(iOS 17.0, *) {
            print("[CalendarService] Using iOS 17+ requestFullAccessToEvents()")
            let granted = try await eventStore.requestFullAccessToEvents()
            print("[CalendarService] 📅 Access result: \(granted)")
            return granted
        } else {
            print("[CalendarService] Using legacy requestAccess(to:)")
            return try await withCheckedThrowingContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    print("[CalendarService] 📅 Legacy access result: \(granted), error: \(String(describing: error))")
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    // MARK: - Fetch All Events
    
    /// Fetch events from all calendars (Google + iCloud)
    func fetchAllEvents(from startDate: Date, to endDate: Date) async throws -> [ScheduleEvent] {
        var allEvents: [ScheduleEvent] = []
        
        // Fetch from Google Calendar
        if googleAPI.isAuthenticated {
            do {
                let googleEvents = try await googleAPI.fetchAllEvents(from: startDate, to: endDate)
                allEvents.append(contentsOf: googleEvents)
                log("Fetched \(googleEvents.count) Google events")
            } catch {
                log("Google Calendar error: \(error)")
                // Continue with iCloud events
            }
        } else {
            log("Google Calendar not authenticated")
        }
        
        // Fetch from iCloud (EventKit)
        if isEventKitAuthorized {
            let icloudEvents = fetchEventKitEvents(from: startDate, to: endDate)
            allEvents.append(contentsOf: icloudEvents)
            log("Fetched \(icloudEvents.count) iCloud events")
        } else {
            log("EventKit not authorized")
        }
        
        // Sort by start time
        let sortedEvents = allEvents.sortedByTime()
        
        // Cache events
        store.saveEvents(sortedEvents)
        
        return sortedEvents
    }
    
    /// Fetch today's events
    func fetchTodayEvents() async throws -> [ScheduleEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await fetchAllEvents(from: startOfDay, to: endOfDay)
    }
    
    /// Fetch this week's events (Monday start)
    func fetchWeekEvents() async throws -> [ScheduleEvent] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return []
        }
        
        return try await fetchAllEvents(from: weekInterval.start, to: weekInterval.end)
    }
    
    /// Fetch events for the next N days
    func fetchUpcomingEvents(days: Int) async throws -> [ScheduleEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: days, to: startOfDay)!
        
        return try await fetchAllEvents(from: startOfDay, to: endDate)
    }
    
    // MARK: - EventKit (iCloud)
    
    /// Fetch events from iCloud via EventKit
    private func fetchEventKitEvents(from startDate: Date, to endDate: Date) -> [ScheduleEvent] {
        var events: [ScheduleEvent] = []
        
        // Find the "JACK × THEO" calendar
        let icloudCalendars = ClientCalendars.icloudCalendars
        
        for clientCalendar in icloudCalendars {
            // Find matching EKCalendar by title
            guard let ekCalendar = eventStore.calendars(for: .event).first(where: {
                $0.title == clientCalendar.calendarId || 
                $0.title.lowercased() == clientCalendar.calendarId.lowercased()
            }) else {
                log("Could not find iCloud calendar: \(clientCalendar.calendarId)")
                continue
            }
            
            let predicate = eventStore.predicateForEvents(
                withStart: startDate,
                end: endDate,
                calendars: [ekCalendar]
            )
            
            let ekEvents = eventStore.events(matching: predicate)
            
            for ekEvent in ekEvents {
                let scheduleEvent = ScheduleEvent(
                    id: ekEvent.eventIdentifier,
                    title: ekEvent.title ?? "Untitled",
                    startDate: ekEvent.startDate,
                    endDate: ekEvent.endDate,
                    isAllDay: ekEvent.isAllDay,
                    location: ekEvent.location,
                    notes: ekEvent.notes,
                    clientName: clientCalendar.name,
                    calendarSource: .icloud
                )
                events.append(scheduleEvent)
            }
            
            log("Found \(ekEvents.count) events in \(clientCalendar.name)")
        }
        
        return events
    }
    
    // MARK: - Cached Events
    
    /// Load cached events (for widget use when fresh fetch isn't possible)
    func loadCachedEvents() -> [ScheduleEvent] {
        store.loadEvents() ?? []
    }
    
    /// Get cached today events
    func getCachedTodayEvents() -> [ScheduleEvent] {
        loadCachedEvents().todayOnly()
    }
    
    /// Get cached week events
    func getCachedWeekEvents() -> [ScheduleEvent] {
        loadCachedEvents().thisWeekOnly()
    }
    
    // MARK: - Event Grouping
    
    /// Group events by client name
    func groupEventsByClient(_ events: [ScheduleEvent]) -> [String: [ScheduleEvent]] {
        var grouped: [String: [ScheduleEvent]] = [:]
        
        for event in events {
            if grouped[event.clientName] != nil {
                grouped[event.clientName]?.append(event)
            } else {
                grouped[event.clientName] = [event]
            }
        }
        
        return grouped
    }
    
    /// Get events for a specific client
    func eventsForClient(_ clientName: String, from events: [ScheduleEvent]) -> [ScheduleEvent] {
        events.filter { $0.clientName == clientName }
    }
}


