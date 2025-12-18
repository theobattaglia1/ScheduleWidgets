//
//  AppRouter.swift
//  AMF Schedule
//
//  Navigation router for deep link handling and view state management
//

import SwiftUI
import Combine

// MARK: - Schedule View Type (App-side)

/// View types for main app navigation (mirrors ScheduleViewType from widget intent)
enum AppScheduleViewType: String, CaseIterable, Identifiable {
    case today
    case fiveDay
    case nextWeek
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .fiveDay: return "5-Day Outlook"
        case .nextWeek: return "Next Week"
        }
    }
    
    var iconName: String {
        switch self {
        case .today: return "sun.max"
        case .fiveDay: return "calendar"
        case .nextWeek: return "calendar.badge.clock"
        }
    }
}

// MARK: - Navigation Destination

/// Possible navigation destinations in the app
enum NavigationDestination: Hashable {
    case eventDetail(eventId: String, date: Date?)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .eventDetail(let id, _):
            hasher.combine("eventDetail")
            hasher.combine(id)
        }
    }
    
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.eventDetail(let id1, _), .eventDetail(let id2, _)):
            return id1 == id2
        }
    }
}

// MARK: - Toast Message

/// A toast message to show to the user
struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    
    enum ToastType {
        case info
        case warning
        case error
    }
}

// MARK: - App Router

/// Manages navigation state and deep link handling
@MainActor
final class AppRouter: ObservableObject {
    
    // MARK: - Published State
    
    /// Current selected view type
    @Published var selectedView: AppScheduleViewType = .today
    
    /// Currently selected/focused date
    @Published var selectedDate: Date = Date()
    
    /// Selected event ID for navigation to detail view
    @Published var selectedEventID: String?
    
    /// Navigation path for NavigationStack
    @Published var navigationPath = NavigationPath()
    
    /// Toast message to display
    @Published var toastMessage: ToastMessage?
    
    // MARK: - Private State
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Auto-dismiss toast after 3 seconds
        $toastMessage
            .compactMap { $0 }
            .delay(for: .seconds(3), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.toastMessage = nil
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Deep Link Handling
    
    /// Handles an incoming deep link URL
    func handleDeepLink(_ url: URL) {
        guard let destination = DeepLinkRoute.parse(url) else {
            print("⚠️ [AppRouter] Could not parse deep link: \(url)")
            return
        }
        
        print("✅ [AppRouter] Handling deep link: \(destination)")
        
        navigate(to: destination)
    }
    
    /// Navigates to a deep link destination
    func navigate(to destination: DeepLinkDestination) {
        switch destination {
        case .today(let date):
            selectedView = .today
            if let date = date {
                selectedDate = date
            } else {
                selectedDate = Date()
            }
            // Clear any navigation stack
            navigationPath = NavigationPath()
            
        case .fiveDay(let anchor):
            selectedView = .fiveDay
            if let anchor = anchor {
                selectedDate = anchor
            } else {
                selectedDate = Date()
            }
            navigationPath = NavigationPath()
            
        case .nextWeek(let anchor):
            selectedView = .nextWeek
            if let anchor = anchor {
                selectedDate = anchor
            } else {
                // Default to next Monday
                selectedDate = getNextMonday()
            }
            navigationPath = NavigationPath()
            
        case .event(let id, let date):
            // First, set the appropriate view and date
            if let date = date {
                selectedDate = date
                // Determine which view based on the date
                if Calendar.current.isDateInToday(date) {
                    selectedView = .today
                } else {
                    selectedView = .fiveDay
                }
            }
            
            // Then navigate to the event detail
            selectedEventID = id
            navigationPath.append(NavigationDestination.eventDetail(eventId: id, date: date))
        }
    }
    
    // MARK: - Navigation Helpers
    
    /// Navigates to today's view
    func goToToday() {
        selectedView = .today
        selectedDate = Date()
        navigationPath = NavigationPath()
    }
    
    /// Navigates to 5-day outlook
    func goToFiveDay() {
        selectedView = .fiveDay
        selectedDate = Date()
        navigationPath = NavigationPath()
    }
    
    /// Navigates to next week view
    func goToNextWeek() {
        selectedView = .nextWeek
        selectedDate = getNextMonday()
        navigationPath = NavigationPath()
    }
    
    /// Navigates to a specific event
    func goToEvent(id: String, date: Date? = nil) {
        navigate(to: .event(id: id, date: date))
    }
    
    /// Shows a toast message
    func showToast(_ message: String, type: ToastMessage.ToastType = .info) {
        toastMessage = ToastMessage(message: message, type: type)
    }
    
    /// Shows event not found error
    func showEventNotFound() {
        showToast("Event not found", type: .warning)
    }
    
    // MARK: - Date Helpers
    
    private func getNextMonday() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        
        var nextMonday = calendar.startOfDay(for: Date())
        
        // Find the next Monday
        while calendar.component(.weekday, from: nextMonday) != 2 {
            nextMonday = calendar.date(byAdding: .day, value: 1, to: nextMonday)!
        }
        
        // If today IS Monday, get next week's Monday
        if calendar.component(.weekday, from: Date()) == 2 {
            nextMonday = calendar.date(byAdding: .day, value: 7, to: nextMonday)!
        }
        
        return nextMonday
    }
}

// MARK: - Environment Key

struct AppRouterKey: EnvironmentKey {
    static let defaultValue: AppRouter = AppRouter()
}

extension EnvironmentValues {
    var appRouter: AppRouter {
        get { self[AppRouterKey.self] }
        set { self[AppRouterKey.self] = newValue }
    }
}
