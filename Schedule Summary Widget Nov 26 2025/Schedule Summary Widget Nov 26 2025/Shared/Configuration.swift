//
//  Configuration.swift
//  AMF Schedule
//
//  Centralized configuration with all credentials and settings
//

import Foundation

/// App-wide configuration constants
enum AppConfiguration {
    
    // MARK: - App Metadata
    
    static let appName = "AMF Schedule"
    static let bundleIdentifier = "Theo.Schedule-Summary-Widget-Nov-26-2025"
    static let widgetBundleIdentifier = "Theo.Schedule-Summary-Widget-Nov-26-2025.AMFScheduleWidget"
    static let appGroupIdentifier = "group.Theo.Schedule-Summary-Widget-Nov-26-2025"
    static let teamId = "VR6F23HLU3"
    
    // MARK: - Google Calendar API
    
    enum Google {
        static let clientId = "874000025146-0guq8ghng3crr9tucb6105emaarc7uvr.apps.googleusercontent.com"
        static let redirectUri = "com.googleusercontent.apps.874000025146-0guq8ghng3crr9tucb6105emaarc7uvr:/oauth2redirect"
        static let scopes = "https://www.googleapis.com/auth/calendar.readonly"
        static let authorizationEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
        static let tokenEndpoint = "https://oauth2.googleapis.com/token"
        static let calendarEndpoint = "https://www.googleapis.com/calendar/v3"
    }
    
    // MARK: - Gemini API
    
    enum Gemini {
        static let apiKey = "AIzaSyDpf_U3pbBEpER_ZGU6H8dBus9n696m_2Y"
        static let model = "gemini-1.5-flash"
        static let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    }
    
    // MARK: - Weather
    
    enum Weather {
        static let fallbackLatitude = 34.07845
        static let fallbackLongitude = -118.25317
        static let useDynamicLocation = true
    }
    
    // MARK: - Background Refresh
    
    enum BackgroundRefresh {
        static let taskIdentifier = "Theo.Schedule-Summary-Widget-Nov-26-2025.refresh"
        static let refreshIntervalSeconds: TimeInterval = 1800 // 30 minutes
    }
    
    // MARK: - Storage
    
    enum Storage {
        static let todaySummaryFile = "todaySummary.txt"
        static let weekSummaryFile = "weekSummary.txt"
        static let weatherFile = "weather.json"
        static let clientsFile = "clients.json"
        static let eventsFile = "events.json"
        static let authTokenFile = "googleAuthToken.json"
        static let lastRefreshFile = "lastRefresh.txt"
        
        static let expirationIntervalSeconds: TimeInterval = 7200 // 2 hours
    }
    
    // MARK: - Summary Character Limits
    
    enum CharacterLimits {
        static let todaySummary = 320
        static let weekMedium = 280
        static let weekLarge = 460
    }
    
    // MARK: - Design
    
    enum Design {
        static let primaryFont = "HelveticaNeue"
        static let boldFont = "HelveticaNeue-Bold"
        static let mediumFont = "HelveticaNeue-Medium"
        
        static let primaryTextColor = "#000000"
        static let secondaryTextColor = "#666666"
        static let tertiaryTextColor = "#999999"
        static let backgroundColor = "#FFFFFF"
        static let dividerColor = "#E5E5E5"
        static let surfaceColor = "#F8F8F8"
    }
    
    // MARK: - Deep Links
    
    enum DeepLinks {
        static let scheme = "amfschedule"
        static let today = "amfschedule://today"
        static let week = "amfschedule://week"
        static let settings = "amfschedule://settings"
    }
    
    // MARK: - Date Formatting
    
    enum DateFormat {
        static let widgetHeader = "EEE dd MMM yyyy" // Tue 02 Dec 2025
        static let fullDate = "EEEE, MMMM d"
        static let shortDay = "EEE"
        static let time12Hour = "h:mm a"
        static let weekStartsOnMonday = true
    }
    
    // MARK: - Debug
    
    #if DEBUG
    static let debugLoggingEnabled = true
    #else
    static let debugLoggingEnabled = false
    #endif
}

// MARK: - Calendar IDs

enum CalendarIds {
    static let theo = "theo@allmyfriendsinc.com"
    static let adam = "mixedmanagement.com_srjbj5qn2pqr58rngcu88aruf0@group.calendar.google.com"
    static let hudson = "c_160f7987c0107a7996dc0ad5f1c3ccbce7bece10b7828e6da5dff2bb6279f2b6@group.calendar.google.com"
    static let tom = "c_781d3afd4ef46456a9cb97c290fdeea3e12ab6f9b0877b715428c40138dd2e4e@group.calendar.google.com"
    static let ruby = "c_0299ce218cb9a83dcb3ae64b3c349d0595c50f8449e8ef8be63128d34bef05e7@group.calendar.google.com"
    static let conall = "c_e0137e9b47187e28b634ae2e074bdcc5b8df6bdf0c54cd0f4f1379ea58578fed@group.calendar.google.com"
    static let jackTheo = "JACK × THEO" // iCloud calendar name
}

