//
//  AppGroupStore.swift
//  AMF Schedule
//
//  Shared storage via App Groups for widget/app communication
//

import Foundation

/// Thread-safe App Group storage manager
final class AppGroupStore {
    
    // MARK: - Configuration
    
    static let shared = AppGroupStore()
    
    /// App Group identifier
    private let appGroupIdentifier = "group.Theo.Schedule-Summary-Widget-Nov-26-2025"
    
    /// File names
    private enum FileName: String {
        case todaySummary = "todaySummary.txt"
        case weekSummary = "weekSummary.txt"
        case weather = "weather.json"
        case clients = "clients.json"
        case events = "events.json"
        case lastRefresh = "lastRefresh.txt"
        case authToken = "googleAuthToken.json"
    }
    
    /// Expiration time in seconds (2 hours)
    private let expirationInterval: TimeInterval = 7200
    
    /// Debug logging (dev only)
    #if DEBUG
    private let debugLogging = true
    #else
    private let debugLogging = false
    #endif
    
    // MARK: - Container URL
    
    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    private init() {
        // Ensure container directory exists
        if let url = containerURL {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            log("App Group container: \(url.path)")
        } else {
            log("⚠️ Failed to access App Group container")
        }
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        if debugLogging {
            print("[AppGroupStore] \(message)")
        }
    }
    
    // MARK: - Generic Read/Write
    
    private func fileURL(for fileName: FileName) -> URL? {
        containerURL?.appendingPathComponent(fileName.rawValue)
    }
    
    private func write<T: Encodable>(_ value: T, to fileName: FileName) {
        guard let url = fileURL(for: fileName) else {
            log("⚠️ Cannot write \(fileName.rawValue): no container URL")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
            log("✓ Wrote \(fileName.rawValue)")
        } catch {
            log("⚠️ Failed to write \(fileName.rawValue): \(error)")
        }
    }
    
    private func read<T: Decodable>(_ type: T.Type, from fileName: FileName) -> T? {
        guard let url = fileURL(for: fileName),
              FileManager.default.fileExists(atPath: url.path) else {
            log("No file: \(fileName.rawValue)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let value = try decoder.decode(type, from: data)
            log("✓ Read \(fileName.rawValue)")
            return value
        } catch {
            log("⚠️ Failed to read \(fileName.rawValue): \(error)")
            // Handle corruption gracefully - delete corrupt file
            try? FileManager.default.removeItem(at: url)
            return nil
        }
    }
    
    private func writeText(_ text: String, to fileName: FileName) {
        guard let url = fileURL(for: fileName) else { return }
        
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            log("✓ Wrote \(fileName.rawValue)")
        } catch {
            log("⚠️ Failed to write \(fileName.rawValue): \(error)")
        }
    }
    
    private func readText(from fileName: FileName) -> String? {
        guard let url = fileURL(for: fileName),
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            log("⚠️ Failed to read \(fileName.rawValue): \(error)")
            return nil
        }
    }
    
    // MARK: - Today Summary
    
    func saveTodaySummary(_ summary: TodaySummary) {
        write(summary, to: .todaySummary)
    }
    
    func loadTodaySummary() -> TodaySummary? {
        guard let summary: TodaySummary = read(TodaySummary.self, from: .todaySummary) else {
            return nil
        }
        
        // Check expiration
        if summary.isExpired {
            log("Today summary expired")
            return nil
        }
        
        return summary
    }
    
    // MARK: - Week Summary
    
    func saveWeekSummary(_ summary: WeekSummary) {
        write(summary, to: .weekSummary)
    }
    
    func loadWeekSummary() -> WeekSummary? {
        guard let summary: WeekSummary = read(WeekSummary.self, from: .weekSummary) else {
            return nil
        }
        
        if summary.isExpired {
            log("Week summary expired")
            return nil
        }
        
        return summary
    }
    
    // MARK: - Weather
    
    func saveWeather(_ weather: WeatherData) {
        write(weather, to: .weather)
    }
    
    func loadWeather() -> WeatherData? {
        guard let weather: WeatherData = read(WeatherData.self, from: .weather) else {
            return nil
        }
        
        if weather.isStale {
            log("Weather data stale")
            return nil
        }
        
        return weather
    }
    
    // MARK: - Events Cache
    
    func saveEvents(_ events: [ScheduleEvent]) {
        write(events, to: .events)
    }
    
    func loadEvents() -> [ScheduleEvent]? {
        read([ScheduleEvent].self, from: .events)
    }
    
    // MARK: - Google Auth Token
    
    struct GoogleAuthToken: Codable {
        let accessToken: String
        let refreshToken: String?
        let expiresAt: Date
        
        var isExpired: Bool {
            Date() > expiresAt
        }
    }
    
    func saveGoogleAuthToken(_ token: GoogleAuthToken) {
        write(token, to: .authToken)
    }
    
    func loadGoogleAuthToken() -> GoogleAuthToken? {
        read(GoogleAuthToken.self, from: .authToken)
    }
    
    func clearGoogleAuthToken() {
        guard let url = fileURL(for: .authToken) else { return }
        try? FileManager.default.removeItem(at: url)
        log("Cleared auth token")
    }
    
    // MARK: - Last Refresh Tracking
    
    func saveLastRefreshTime(_ date: Date = Date()) {
        let formatter = ISO8601DateFormatter()
        writeText(formatter.string(from: date), to: .lastRefresh)
    }
    
    func loadLastRefreshTime() -> Date? {
        guard let text = readText(from: .lastRefresh) else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: text)
    }
    
    func needsRefresh() -> Bool {
        guard let lastRefresh = loadLastRefreshTime() else {
            return true
        }
        return Date().timeIntervalSince(lastRefresh) > 1800 // 30 minutes
    }
    
    // MARK: - Clear All
    
    func clearAll() {
        guard let containerURL = containerURL else { return }
        
        let fileManager = FileManager.default
        if let files = try? fileManager.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
        log("Cleared all stored data")
    }
}

