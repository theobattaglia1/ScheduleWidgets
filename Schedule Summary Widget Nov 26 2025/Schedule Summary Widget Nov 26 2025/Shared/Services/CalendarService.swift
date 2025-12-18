//
//  CalendarService.swift
//  AMF Schedule
//
//  Unified calendar service combining Google Calendar and EventKit (iCloud)
//

import Foundation
import EventKit
#if canImport(UIKit)
import UIKit
#endif

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
            return status == .fullAccess
        } else {
            // For iOS < 17, check raw value to avoid deprecated .authorized
            return status.rawValue == 3 // EKAuthorizationStatus.authorized rawValue (3)
        }
    }
    
    /// Request EventKit access - uses a FRESH EKEventStore to ensure dialog shows
    func requestEventKitAccess() async throws -> Bool {
        let currentStatus = eventKitAuthorizationStatus
        
        // Log detailed status
        let statusName: String
        switch currentStatus {
        case .notDetermined: statusName = "notDetermined"
        case .restricted: statusName = "restricted"
        case .denied: statusName = "denied"
        case .authorized: statusName = "authorized (legacy)"
        case .fullAccess: statusName = "fullAccess"
        case .writeOnly: statusName = "writeOnly"
        @unknown default: statusName = "unknown(\(currentStatus.rawValue))"
        }
        print("[CalendarService] 📅 Current EventKit status: \(statusName)")
        
        // If already authorized, return true
        if isEventKitAuthorized {
            print("[CalendarService] ✓ Already authorized")
            return true
        }
        
        // If restricted (parental controls, MDM), we can't request
        if currentStatus == .restricted {
            print("[CalendarService] ⚠️ Access restricted by device policy")
            return false
        }
        
        // If denied, we can't show the dialog again - user must go to Settings
        if currentStatus == .denied {
            print("[CalendarService] ⚠️ Previously denied - user must enable in Settings")
            return false
        }
        
        // Create a FRESH EKEventStore for the permission request
        // This is important - reusing an old store can sometimes prevent the dialog
        let freshStore = EKEventStore()
        
        print("[CalendarService] 📅 Requesting EventKit access with fresh store...")
        
        if #available(iOS 17.0, *) {
            print("[CalendarService] Using iOS 17+ requestFullAccessToEvents()")
            do {
                let granted = try await freshStore.requestFullAccessToEvents()
                print("[CalendarService] 📅 Access result: \(granted)")
                return granted
            } catch {
                print("[CalendarService] ❌ Request error: \(error)")
                throw error
            }
        } else {
            print("[CalendarService] Using legacy requestAccess(to:)")
            return try await withCheckedThrowingContinuation { continuation in
                freshStore.requestAccess(to: .event) { granted, error in
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
        
        // Load enabled calendars from preferences
        let enabledCalendars = store.loadEnabledCalendars()
        
        // Fetch from Google Calendar
        if googleAPI.isAuthenticated {
            do {
                var googleEvents = try await googleAPI.fetchAllEvents(from: startDate, to: endDate)
                
                // Filter by enabled calendars if preferences exist (filter by clientName)
                if let enabled = enabledCalendars {
                    googleEvents = googleEvents.filter { enabled.contains($0.clientName) }
                    log("Filtered to \(googleEvents.count) enabled Google events")
                }
                
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
    
    /// List all available iCloud calendars (for debugging/configuration)
    func listAvailableCalendars() -> [String] {
        let calendars = eventStore.calendars(for: .event)
        print("📅 [CalendarService] Available calendars:")
        for cal in calendars {
            print("   - \"\(cal.title)\" (source: \(cal.source.title), type: \(cal.type.rawValue))")
        }
        return calendars.map { $0.title }
    }
    
    /// Fetch events from iCloud via EventKit
    private func fetchEventKitEvents(from startDate: Date, to endDate: Date) -> [ScheduleEvent] {
        var events: [ScheduleEvent] = []
        
        // Load enabled calendars from preferences
        let enabledCalendars = store.loadEnabledCalendars() ?? Set(["JACK × THEO"])
        
        // Get all calendars on device
        let allCalendars = eventStore.calendars(for: .event)
        print("📅 [CalendarService] Found \(allCalendars.count) calendars on device")
        print("📅 [CalendarService] Enabled iCloud calendars: \(enabledCalendars.filter { !$0.contains("@") && !$0.contains("group.calendar") })")
        
        // Fetch from ALL enabled iCloud calendars (by name)
        for ekCalendar in allCalendars {
            // Check if this calendar is enabled
            guard enabledCalendars.contains(ekCalendar.title) else {
                continue
            }
            
            print("📅 [CalendarService] Fetching from iCloud calendar: \"\(ekCalendar.title)\"")
            
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
                    clientName: ekCalendar.title,  // Use calendar title as client name
                    calendarSource: .icloud
                )
                events.append(scheduleEvent)
            }
            
            log("Fetched \(ekEvents.count) events from \(ekCalendar.title)")
        }
        
        return events
    }
    
    /// Fetch events from iCloud via EventKit (OLD - keeping for reference)
    private func fetchEventKitEventsOLD(from startDate: Date, to endDate: Date) -> [ScheduleEvent] {
        var events: [ScheduleEvent] = []
        
        // Find configured iCloud calendars
        let icloudCalendars = ClientCalendars.icloudCalendars
        print("📅 [CalendarService] Looking for \(icloudCalendars.count) configured iCloud calendars")
        
        for clientCalendar in icloudCalendars {
            print("📅 [CalendarService] Searching for: \"\(clientCalendar.calendarId)\"")
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


