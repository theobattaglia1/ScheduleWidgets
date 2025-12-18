//
//  BackgroundScheduler.swift
//  AMF Schedule
//
//  Background refresh task scheduling for calendar updates
//

import Foundation
import BackgroundTasks
import WidgetKit

/// Background task scheduler for periodic calendar and summary refreshes
@available(iOSApplicationExtension, unavailable)
final class BackgroundScheduler {
    
    // MARK: - Configuration
    
    /// Background task identifier (must match Info.plist)
    static let taskIdentifier = "Theo.Schedule-Summary-Widget-Nov-26-2025.refresh"
    
    /// Refresh interval (30 minutes)
    private static let refreshInterval: TimeInterval = 1800
    
    // MARK: - Singleton
    
    static let shared = BackgroundScheduler()
    
    private let calendarService = CalendarService.shared
    private let geminiSummarizer = GeminiSummarizer.shared
    private let weatherService = WeatherService.shared
    private let store = AppGroupStore.shared
    
    #if DEBUG
    private let debugLogging = true
    #else
    private let debugLogging = false
    #endif
    
    private init() {}
    
    private func log(_ message: String) {
        if debugLogging {
            print("[BackgroundScheduler] \(message)")
        }
    }
    
    // MARK: - Registration
    
    /// Register background tasks - call from AppDelegate.application(_:didFinishLaunchingWithOptions:)
    @available(iOSApplicationExtension, unavailable)
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        log("Background task registered")
    }
    
    // MARK: - Scheduling
    
    /// Schedule the next background refresh
    @available(iOSApplicationExtension, unavailable)
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: Self.refreshInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            log("Scheduled next refresh for \(Self.refreshInterval/60) minutes")
        } catch {
            log("Failed to schedule refresh: \(error)")
        }
    }
    
    /// Cancel all pending background tasks
    @available(iOSApplicationExtension, unavailable)
    func cancelAllTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        log("Cancelled all background tasks")
    }
    
    // MARK: - Task Handling
    
    @available(iOSApplicationExtension, unavailable)
    private func handleAppRefresh(task: BGAppRefreshTask) {
        log("Background refresh started")
        
        // Schedule the next refresh
        scheduleAppRefresh()
        
        // Create a task to refresh data
        let refreshTask = Task {
            do {
                try await performFullRefresh()
                task.setTaskCompleted(success: true)
                log("Background refresh completed successfully")
            } catch {
                log("Background refresh failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
        
        // Handle task expiration
        task.expirationHandler = {
            refreshTask.cancel()
            self.log("Background task expired")
        }
    }
    
    // MARK: - Full Refresh
    
    /// Perform a full refresh of all data
    func performFullRefresh() async throws {
        print("[BackgroundScheduler] 🔄 Starting full refresh...")
        
        // Fetch events for the week
        print("[BackgroundScheduler] Fetching events...")
        let events = try await calendarService.fetchUpcomingEvents(days: 7)
        print("[BackgroundScheduler] ✓ Fetched \(events.count) events")
        
        // Generate summaries
        print("[BackgroundScheduler] Generating summaries...")
        async let todaySummary = geminiSummarizer.generateTodaySummary(events: events)
        async let weekSummary = geminiSummarizer.generateWeekSummary(events: events)
        
        // Fetch weather
        print("[BackgroundScheduler] Fetching weather...")
        let weatherData = await weatherService.getWeather()
        print("[BackgroundScheduler] ✓ Weather: \(weatherData.temperatureFormatted)")
        
        // Wait for summaries
        let _ = try await (todaySummary, weekSummary)
        print("[BackgroundScheduler] ✓ Summaries generated")
        
        // Update last refresh time
        store.saveLastRefreshTime()
        
        // Reload widgets
        #if !os(watchOS)
        reloadWidgets()
        #endif
        
        print("[BackgroundScheduler] ✅ Full refresh completed")
    }
    
    /// Refresh only if data is stale
    @available(iOSApplicationExtension, unavailable)
    func refreshIfNeeded() async {
        guard store.needsRefresh() else {
            log("Refresh not needed")
            return
        }
        
        do {
            try await performFullRefresh()
        } catch {
            log("Refresh failed: \(error)")
        }
    }
    
    // MARK: - Widget Reload
    
    /// Reload all widgets
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        log("Widgets reloaded")
    }
    
    /// Reload specific widget
    func reloadWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        log("Widget \(kind) reloaded")
    }
}

// MARK: - Foreground Refresh

extension BackgroundScheduler {
    
    /// Called when app becomes active - refresh if data is stale
    func handleAppBecameActive() {
        Task {
            await refreshIfNeeded()
        }
    }
    
    /// Called when app enters background - schedule refresh
    func handleAppEnteredBackground() {
        scheduleAppRefresh()
    }
}

