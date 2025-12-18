//
//  GeminiSummarizer.swift
//  AMF Schedule
//
//  Gemini AI integration for schedule summarization with AMF editorial voice
//

import Foundation

/// Gemini AI summarizer for generating schedule summaries
final class GeminiSummarizer {
    
    // MARK: - Configuration (Real Credentials)
    
    private let apiKey = "AIzaSyDpf_U3pbBEpER_ZGU6H8dBus9n696m_2Y"
    private let model = "gemini-1.5-flash"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    // MARK: - Character Limits
    
    private let todayCharacterLimit = 320
    private let weekMediumCharacterLimit = 280
    private let weekLargeCharacterLimit = 460
    
    // MARK: - Singleton
    
    static let shared = GeminiSummarizer()
    
    private let store = AppGroupStore.shared
    
    #if DEBUG
    private let debugLogging = true
    #else
    private let debugLogging = false
    #endif
    
    private init() {}
    
    private func log(_ message: String) {
        if debugLogging {
            print("[GeminiSummarizer] \(message)")
        }
    }
    
    // MARK: - Today Summary
    
    /// Generate today's schedule summary
    func generateTodaySummary(events: [ScheduleEvent]) async throws -> TodaySummary {
        let todayEvents = events.todayOnly().sortedByTime()
        
        if todayEvents.isEmpty {
            return TodaySummary.empty
        }
        
        let prompt = buildTodayPrompt(events: todayEvents)
        
        do {
            let summary = try await callGemini(prompt: prompt)
            let trimmedSummary = trimToLimit(summary, limit: todayCharacterLimit)
            
            let todaySummary = TodaySummary(summary: trimmedSummary, eventCount: todayEvents.count)
            store.saveTodaySummary(todaySummary)
            
            log("Generated today summary: \(trimmedSummary.count) chars")
            return todaySummary
            
        } catch {
            log("Gemini error: \(error)")
            
            // Try local fallback
            let fallback = generateLocalTodaySummary(events: todayEvents)
            store.saveTodaySummary(fallback)
            return fallback
        }
    }
    
    // MARK: - Week Summary
    
    /// Generate week ahead summary
    func generateWeekSummary(events: [ScheduleEvent]) async throws -> WeekSummary {
        let weekEvents = events.thisWeekOnly().sortedByTime()
        
        if weekEvents.isEmpty {
            return WeekSummary.empty
        }
        
        let promptMedium = buildWeekPrompt(events: weekEvents, characterLimit: weekMediumCharacterLimit)
        let promptLarge = buildWeekPrompt(events: weekEvents, characterLimit: weekLargeCharacterLimit)
        
        do {
            async let mediumResult = callGemini(prompt: promptMedium)
            async let largeResult = callGemini(prompt: promptLarge)
            
            let (medium, large) = try await (mediumResult, largeResult)
            
            let dayBreakdown = buildDayBreakdown(from: weekEvents)
            
            let weekSummary = WeekSummary(
                summaryMedium: trimToLimit(medium, limit: weekMediumCharacterLimit),
                summaryLarge: trimToLimit(large, limit: weekLargeCharacterLimit),
                eventCount: weekEvents.count,
                dayBreakdown: dayBreakdown
            )
            
            store.saveWeekSummary(weekSummary)
            log("Generated week summary")
            
            return weekSummary
            
        } catch {
            log("Gemini error: \(error)")
            
            // Try local fallback
            let fallback = generateLocalWeekSummary(events: weekEvents)
            store.saveWeekSummary(fallback)
            return fallback
        }
    }
    
    // MARK: - Prompt Building
    
    private func buildTodayPrompt(events: [ScheduleEvent]) -> String {
        // Group events by client, Theo first then alphabetical
        let grouped = Dictionary(grouping: events) { $0.clientName }
        let sortedClients = grouped.keys.sorted { client1, client2 in
            if client1 == "Theo" { return true }
            if client2 == "Theo" { return false }
            return client1 < client2
        }
        
        var eventList = ""
        for client in sortedClients {
            guard let clientEvents = grouped[client] else { continue }
            eventList += "\n\(client):\n"
            for event in clientEvents.sorted(by: { $0.startDate < $1.startDate }) {
                let timeRange = event.isAllDay ? "All day" : event.formattedTimeRange
                eventList += "  - \(event.title) | \(timeRange)\n"
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        let todayString = dateFormatter.string(from: Date())
        
        return """
        You are writing a schedule summary for a talent management company (AMF).
        
        MANDATORY FORMAT:
        - ALWAYS start with Theo's events first, then other clients alphabetically
        - Put client names in **bold** using markdown: **Theo**, **Hudson**, etc.
        - Include event name and time range
        - Example: "**Theo** has Lila meeting 12:00–1:00 PM. **Hudson** has studio session 2:00–5:00 PM."
        - Group by person, not by time
        
        CLIENTS (in order):
        1. **Theo** = the user (always first)
        2. Then alphabetically: Adam, Conall, Hudson, JACK × THEO, Ruby, Tom
        
        VOICE: Crisp, clear, informative. No emojis.
        
        CHARACTER LIMIT: \(todayCharacterLimit) characters maximum.
        
        TODAY: \(todayString)
        
        EVENTS BY CLIENT:
        \(eventList)
        
        Write the summary. **Bold** each client name. Theo first, then others alphabetically.
        
        Output only the summary text.
        """
    }
    
    private func buildWeekPrompt(events: [ScheduleEvent], characterLimit: Int) -> String {
        // Group events by client, Theo first then alphabetical
        let grouped = Dictionary(grouping: events) { $0.clientName }
        let sortedClients = grouped.keys.sorted { client1, client2 in
            if client1 == "Theo" { return true }
            if client2 == "Theo" { return false }
            return client1 < client2
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        
        var eventList = ""
        for client in sortedClients {
            guard let clientEvents = grouped[client] else { continue }
            eventList += "\n\(client):\n"
            for event in clientEvents.sorted(by: { $0.startDate < $1.startDate }) {
                let dayName = dateFormatter.string(from: event.startDate)
                let timeRange = event.isAllDay ? "All day" : event.formattedTimeRange
                eventList += "  - \(dayName): \(event.title) | \(timeRange)\n"
            }
        }
        
        return """
        You are writing a week-ahead summary for a talent management company (AMF).
        
        MANDATORY FORMAT:
        - Organize BY CLIENT, not by day
        - ALWAYS start with **Theo** first, then other clients alphabetically
        - Put client names in **bold** using markdown
        - Example: "**Theo** has team sync Monday 2–3 PM and review Friday. **Hudson** has studio Tuesday all day. **Ruby** wraps photoshoot Wednesday."
        
        CLIENTS (in order):
        1. **Theo** = the user (always first)
        2. Then alphabetically: Adam, Conall, Hudson, JACK × THEO, Ruby, Tom
        
        VOICE: Crisp, clear, informative. No emojis.
        
        CHARACTER LIMIT: \(characterLimit) characters maximum.
        
        EVENTS BY CLIENT:
        \(eventList)
        
        Write the summary. **Bold** each client name. Theo first, then others alphabetically.
        
        Output only the summary text.
        """
    }
    
    // MARK: - Gemini API Call
    
    private func callGemini(prompt: String) async throws -> String {
        let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 256
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            log("Gemini API error \(httpResponse.statusCode): \(errorBody)")
            throw GeminiError.apiError(httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parseError
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Local Fallback
    
    private func generateLocalTodaySummary(events: [ScheduleEvent]) -> TodaySummary {
        let count = events.count
        
        if count == 0 {
            return TodaySummary.empty
        }
        
        // Group by client, Theo first then alphabetical
        let grouped = Dictionary(grouping: events) { $0.clientName }
        let sortedClients = grouped.keys.sorted { client1, client2 in
            if client1 == "Theo" { return true }
            if client2 == "Theo" { return false }
            return client1 < client2
        }
        
        var parts: [String] = []
        for client in sortedClients.prefix(4) {
            guard let clientEvents = grouped[client] else { continue }
            let eventDescs = clientEvents.prefix(2).map { event in
                let timeStr = event.isAllDay ? "all day" : event.formattedTimeRange
                return "\(event.title) \(timeStr)"
            }.joined(separator: ", ")
            parts.append("**\(client)** has \(eventDescs)")
        }
        
        var summary = parts.joined(separator: ". ") + "."
        
        if sortedClients.count > 4 {
            summary += " +\(sortedClients.count - 4) more clients."
        }
        
        return TodaySummary(summary: trimToLimit(summary, limit: todayCharacterLimit), eventCount: count)
    }
    
    private func generateLocalWeekSummary(events: [ScheduleEvent]) -> WeekSummary {
        let count = events.count
        
        if count == 0 {
            return WeekSummary.empty
        }
        
        // Group by client, Theo first then alphabetical
        let grouped = Dictionary(grouping: events) { $0.clientName }
        let sortedClients = grouped.keys.sorted { client1, client2 in
            if client1 == "Theo" { return true }
            if client2 == "Theo" { return false }
            return client1 < client2
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        
        // Medium summary
        var mediumParts: [String] = []
        for client in sortedClients.prefix(3) {
            guard let clientEvents = grouped[client] else { continue }
            mediumParts.append("**\(client)**: \(clientEvents.count) events")
        }
        let medium = mediumParts.joined(separator: ". ") + "."
        
        // Large summary with more detail
        var largeParts: [String] = []
        for client in sortedClients.prefix(4) {
            guard let clientEvents = grouped[client] else { continue }
            let eventDescs = clientEvents.prefix(2).map { event in
                let dayName = dateFormatter.string(from: event.startDate)
                return "\(event.title) \(dayName)"
            }.joined(separator: ", ")
            largeParts.append("**\(client)** has \(eventDescs)")
        }
        let large = largeParts.joined(separator: ". ") + "."
        
        return WeekSummary(
            summaryMedium: trimToLimit(medium, limit: weekMediumCharacterLimit),
            summaryLarge: trimToLimit(large, limit: weekLargeCharacterLimit),
            eventCount: count,
            dayBreakdown: buildDayBreakdown(from: events)
        )
    }
    
    // MARK: - Helpers
    
    private func trimToLimit(_ text: String, limit: Int) -> String {
        if text.count <= limit {
            return text
        }
        
        // Try to cut at a sentence boundary
        let truncated = String(text.prefix(limit - 3))
        if let lastPeriod = truncated.lastIndex(of: ".") {
            return String(truncated[...lastPeriod])
        }
        
        // Cut at word boundary
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        
        return truncated + "..."
    }
    
    private func buildDayBreakdown(from events: [ScheduleEvent]) -> [DaySummary] {
        let grouped = events.groupedByDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        
        return grouped.keys.sorted().map { date in
            let dayEvents = grouped[date] ?? []
            let highlight = dayEvents.first?.title
            
            return DaySummary(
                date: date,
                dayName: dateFormatter.string(from: date),
                eventCount: dayEvents.count,
                highlight: highlight
            )
        }
    }
}

// MARK: - Errors

enum GeminiError: Error, LocalizedError {
    case networkError
    case apiError(Int)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error"
        case .apiError(let code):
            return "API error: \(code)"
        case .parseError:
            return "Failed to parse response"
        }
    }
}

