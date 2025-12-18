//
//  GoogleCalendarAPI.swift
//  AMF Schedule
//
//  Google Calendar API with PKCE OAuth flow
//

import Foundation
import AuthenticationServices
import CryptoKit

/// Google Calendar API client with PKCE authentication
final class GoogleCalendarAPI: NSObject {
    
    // MARK: - Configuration (Real Credentials)
    
    private let clientId = "874000025146-0guq8ghng3crr9tucb6105emaarc7uvr.apps.googleusercontent.com"
    private let redirectUri = "com.googleusercontent.apps.874000025146-0guq8ghng3crr9tucb6105emaarc7uvr:/oauth2redirect"
    private let scopes = "https://www.googleapis.com/auth/calendar.readonly"
    
    private let authorizationEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    private let tokenEndpoint = "https://oauth2.googleapis.com/token"
    private let calendarEndpoint = "https://www.googleapis.com/calendar/v3"
    
    // MARK: - Singleton
    
    static let shared = GoogleCalendarAPI()
    
    // MARK: - State
    
    private var codeVerifier: String?
    private var authSession: ASWebAuthenticationSession?
    private var presentationAnchor: ASPresentationAnchor?
    private var isAuthenticating = false
    
    private let store = AppGroupStore.shared
    
    #if DEBUG
    private let debugLogging = true
    #else
    private let debugLogging = false
    #endif
    
    private override init() {
        super.init()
    }
    
    private func log(_ message: String) {
        if debugLogging {
            print("[GoogleCalendarAPI] \(message)")
        }
    }
    
    // MARK: - PKCE Helpers
    
    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    // MARK: - Authentication
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        if let token = store.loadGoogleAuthToken() {
            return !token.isExpired || token.refreshToken != nil
        }
        return false
    }
    
    /// Get valid access token (refreshing if needed)
    func getAccessToken() async throws -> String {
        guard let token = store.loadGoogleAuthToken() else {
            throw GoogleCalendarError.notAuthenticated
        }
        
        if !token.isExpired {
            return token.accessToken
        }
        
        // Try to refresh
        guard let refreshToken = token.refreshToken else {
            throw GoogleCalendarError.notAuthenticated
        }
        
        return try await refreshAccessToken(refreshToken)
    }
    
    /// Start OAuth flow
    func authenticate(from anchor: ASPresentationAnchor) async throws {
        // Prevent multiple concurrent auth sessions
        guard !isAuthenticating else {
            log("Auth already in progress, ignoring duplicate call")
            return
        }
        
        isAuthenticating = true
        defer { isAuthenticating = false }
        
        self.presentationAnchor = anchor
        
        // Generate PKCE codes
        let verifier = generateCodeVerifier()
        let challenge = generateCodeChallenge(from: verifier)
        self.codeVerifier = verifier
        
        log("Generated verifier: \(verifier.prefix(10))...")
        
        // Build authorization URL
        var components = URLComponents(string: authorizationEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        
        guard let authURL = components.url else {
            throw GoogleCalendarError.invalidURL
        }
        
        log("Starting OAuth flow")
        
        // Use ASWebAuthenticationSession
        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "com.googleusercontent.apps.874000025146-0guq8ghng3crr9tucb6105emaarc7uvr"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let callbackURL = callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: GoogleCalendarError.authenticationFailed)
                }
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.authSession = session
            
            if !session.start() {
                continuation.resume(throwing: GoogleCalendarError.authenticationFailed)
            }
        }
        
        // Extract authorization code
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw GoogleCalendarError.noAuthorizationCode
        }
        
        // Exchange code for tokens
        try await exchangeCodeForTokens(code)
        
        log("Authentication successful")
    }
    
    /// Exchange authorization code for tokens
    private func exchangeCodeForTokens(_ code: String) async throws {
        guard let verifier = codeVerifier else {
            log("Missing code verifier!")
            throw GoogleCalendarError.missingCodeVerifier
        }
        
        log("Exchanging code with verifier: \(verifier.prefix(10))...")
        
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // URL encode all parameters properly
        let params: [(String, String)] = [
            ("client_id", clientId),
            ("code", code),
            ("code_verifier", verifier),
            ("grant_type", "authorization_code"),
            ("redirect_uri", redirectUri)
        ]
        
        let bodyString = params
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            log("Token exchange failed: \(String(data: data, encoding: .utf8) ?? "")")
            throw GoogleCalendarError.tokenExchangeFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        let authToken = AppGroupStore.GoogleAuthToken(
            accessToken: tokenResponse.access_token,
            refreshToken: tokenResponse.refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in - 60))
        )
        
        store.saveGoogleAuthToken(authToken)
        codeVerifier = nil
    }
    
    /// Refresh access token
    private func refreshAccessToken(_ refreshToken: String) async throws -> String {
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "client_id": clientId,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        request.httpBody = body.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            store.clearGoogleAuthToken()
            throw GoogleCalendarError.tokenRefreshFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        let authToken = AppGroupStore.GoogleAuthToken(
            accessToken: tokenResponse.access_token,
            refreshToken: refreshToken, // Keep original refresh token
            expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in - 60))
        )
        
        store.saveGoogleAuthToken(authToken)
        log("Token refreshed")
        
        return tokenResponse.access_token
    }
    
    /// Sign out
    func signOut() {
        store.clearGoogleAuthToken()
        log("Signed out")
    }
    
    // MARK: - Calendar API
    
    /// Fetch events from a specific calendar
    func fetchEvents(
        calendarId: String,
        clientName: String,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [ScheduleEvent] {
        let accessToken = try await getAccessToken()
        
        let encodedCalendarId = calendarId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? calendarId
        
        var components = URLComponents(string: "\(calendarEndpoint)/calendars/\(encodedCalendarId)/events")!
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: formatter.string(from: startDate)),
            URLQueryItem(name: "timeMax", value: formatter.string(from: endDate)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "maxResults", value: "250")
        ]
        
        guard let url = components.url else {
            throw GoogleCalendarError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleCalendarError.networkError
        }
        
        if httpResponse.statusCode == 401 {
            // Token might be invalid, clear and retry
            store.clearGoogleAuthToken()
            throw GoogleCalendarError.notAuthenticated
        }
        
        guard httpResponse.statusCode == 200 else {
            log("API error: \(httpResponse.statusCode) - \(String(data: data, encoding: .utf8) ?? "")")
            throw GoogleCalendarError.apiError(httpResponse.statusCode)
        }
        
        let eventsResponse = try JSONDecoder().decode(GoogleEventsResponse.self, from: data)
        
        return eventsResponse.items?.compactMap { item -> ScheduleEvent? in
            guard let id = item.id,
                  let title = item.summary,
                  let start = item.start,
                  let end = item.end else {
                return nil
            }
            
            let startDate: Date
            let endDate: Date
            let isAllDay: Bool
            
            if let dateStr = start.date {
                // All-day event
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                startDate = dateFormatter.date(from: dateStr) ?? Date()
                endDate = dateFormatter.date(from: end.date ?? dateStr) ?? startDate
                isAllDay = true
            } else if let dateTimeStr = start.dateTime {
                // Timed event
                startDate = formatter.date(from: dateTimeStr) ?? Date()
                endDate = formatter.date(from: end.dateTime ?? dateTimeStr) ?? startDate
                isAllDay = false
            } else {
                return nil
            }
            
            return ScheduleEvent(
                id: id,
                title: title,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                location: item.location,
                notes: item.description,
                clientName: clientName,
                calendarSource: .google
            )
        } ?? []
    }
    
    /// Fetch events from all configured Google calendars
    func fetchAllEvents(from startDate: Date, to endDate: Date) async throws -> [ScheduleEvent] {
        var allEvents: [ScheduleEvent] = []
        
        print("[GoogleCalendarAPI] 📅 Fetching from \(ClientCalendars.googleCalendars.count) Google calendars...")
        
        for calendar in ClientCalendars.googleCalendars {
            print("[GoogleCalendarAPI] 📅 Fetching \(calendar.name) (\(calendar.calendarId))...")
            do {
                let events = try await fetchEvents(
                    calendarId: calendar.calendarId,
                    clientName: calendar.name,
                    from: startDate,
                    to: endDate
                )
                allEvents.append(contentsOf: events)
                print("[GoogleCalendarAPI] ✅ \(calendar.name): \(events.count) events")
            } catch let error as GoogleCalendarError {
                print("[GoogleCalendarAPI] ❌ \(calendar.name) FAILED: \(error.localizedDescription)")
                // Continue with other calendars
            } catch {
                print("[GoogleCalendarAPI] ❌ \(calendar.name) FAILED: \(error)")
                // Continue with other calendars
            }
        }
        
        print("[GoogleCalendarAPI] 📅 Total: \(allEvents.count) events from all calendars")
        return allEvents.sortedByTime()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension GoogleCalendarAPI: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor ?? ASPresentationAnchor()
    }
}

// MARK: - Response Models

private struct TokenResponse: Codable {
    let access_token: String
    let refresh_token: String?
    let expires_in: Int
    let token_type: String
}

private struct GoogleEventsResponse: Codable {
    let items: [GoogleEvent]?
}

private struct GoogleEvent: Codable {
    let id: String?
    let summary: String?
    let description: String?
    let location: String?
    let start: GoogleDateTime?
    let end: GoogleDateTime?
}

private struct GoogleDateTime: Codable {
    let date: String?
    let dateTime: String?
    let timeZone: String?
}

// MARK: - Errors

enum GoogleCalendarError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case authenticationFailed
    case noAuthorizationCode
    case missingCodeVerifier
    case tokenExchangeFailed
    case tokenRefreshFailed
    case networkError
    case apiError(Int)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in to Google Calendar"
        case .invalidURL:
            return "Invalid URL"
        case .authenticationFailed:
            return "Authentication failed"
        case .noAuthorizationCode:
            return "No authorization code received"
        case .missingCodeVerifier:
            return "Missing code verifier"
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code"
        case .tokenRefreshFailed:
            return "Failed to refresh access token"
        case .networkError:
            return "Network error"
        case .apiError(let code):
            return "API error: \(code)"
        }
    }
}

