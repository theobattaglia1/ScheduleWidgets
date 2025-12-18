#if canImport(UIKit)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif
//
//  ContentView.swift
//  AMF Schedule
//
//  Main app view with manual refresh, Google Calendar authentication, and deep link routing
//

import SwiftUI
import Combine
import AuthenticationServices
import EventKit

struct ContentView: View {
    @EnvironmentObject var viewModel: ScheduleViewModel
    @EnvironmentObject var router: AppRouter
    @State private var showingCalendarSettings = false
    @State private var showingWidgetStudio = false
    
    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            ZStack {
                // Liquid Glass Background - subtle gradient
                liquidGlassBackground
                
                // Main content based on selected view
                mainContentView
                
                // Toast overlay
                if let toast = router.toastMessage {
                    VStack {
                        Spacer()
                        ToastView(message: toast)
                            .padding(.bottom, 80)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(), value: router.toastMessage)
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            #if os(iOS)
            .navigationBarHidden(router.selectedView == .today && router.navigationPath.isEmpty)
            #endif
            .onAppear {
                viewModel.loadCachedData()
            }
            .sheet(isPresented: $showingCalendarSettings) {
                CalendarSettingsView()
                    .onDisappear {
                        // Refresh after settings change
                        Task {
                            await viewModel.refresh()
                        }
                    }
            }
            #if os(iOS)
            .sheet(isPresented: $showingWidgetStudio) {
                WidgetStudioView()
            }
            #endif
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .eventDetail(let eventId, let date):
                    EventDetailScreen(eventId: eventId, date: date)
                        .environmentObject(viewModel)
                        .environmentObject(router)
                }
            }
        }
    }
    
    // MARK: - Main Content View
    
    @ViewBuilder
    private var mainContentView: some View {
        switch router.selectedView {
        case .today:
            homeView
        case .fiveDay:
            FiveDayScreen(anchor: router.selectedDate)
                .environmentObject(viewModel)
                .environmentObject(router)
        case .nextWeek:
            NextWeekScreen(anchor: router.selectedDate)
                .environmentObject(viewModel)
                .environmentObject(router)
        }
    }
    
    // MARK: - Home View (Original ContentView content)
    
    private var homeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerView
                
                // View type picker (for navigation)
                viewTypePicker
                
                // Authentication Status
                authenticationSection
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    errorMessageView(errorMessage)
                }
                
                // Today Summary
                if viewModel.isAuthenticated {
                    todaySummarySection
                    
                    // Week Summary
                    weekSummarySection
                    
                    // Widget Studio
                    widgetStudioSection
                    
                    // Calendar Status
                    calendarStatusSection
                    
                    // Weather Status
                    weatherStatusSection
                }
                
                Spacer(minLength: 40)
            }
            .padding(20)
        }
    }
    
    // MARK: - View Type Picker
    
    private var viewTypePicker: some View {
        HStack(spacing: 8) {
            ForEach(AppScheduleViewType.allCases) { viewType in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        router.selectedView = viewType
                        if viewType == .nextWeek {
                            router.goToNextWeek()
                        } else if viewType == .fiveDay {
                            router.goToFiveDay()
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewType.iconName)
                            .font(.system(size: 12))
                        Text(viewType.displayName)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(router.selectedView == viewType ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(router.selectedView == viewType ? Color.blue : Color.clear)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Liquid Glass Background
    
    private var liquidGlassBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "F0F4F8"),
                    Color(hex: "E8EDF2"),
                    Color(hex: "F5F7FA")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle animated blobs for depth
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.4
                        )
                    )
                    .frame(width: geo.size.width * 0.8, height: geo.size.width * 0.8)
                    .offset(x: -geo.size.width * 0.2, y: -geo.size.height * 0.1)
                    .blur(radius: 60)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.06), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.3
                        )
                    )
                    .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                    .offset(x: geo.size.width * 0.5, y: geo.size.height * 0.3)
                    .blur(radius: 50)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.05), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.35
                        )
                    )
                    .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.7)
                    .offset(x: geo.size.width * 0.1, y: geo.size.height * 0.6)
                    .blur(radius: 55)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AMF SCHEDULE")
                .font(.custom("HelveticaNeue-Bold", size: 11))
                .foregroundStyle(.secondary)
                .tracking(2)
            
            Text(formattedDate)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            // Last refresh
            if let lastRefresh = viewModel.lastRefresh {
                Text("Updated \(lastRefresh.formatted(.relative(presentation: .named)))")
                    .font(.custom("HelveticaNeue", size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Authentication Section
    
    private var authenticationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("GOOGLE CALENDAR")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isAuthenticated ? Color.green : Color.red.opacity(0.8))
                        .frame(width: 8, height: 8)
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                        }
                        .shadow(color: viewModel.isAuthenticated ? .green.opacity(0.5) : .red.opacity(0.3), radius: 4)
                    
                    Text(viewModel.isAuthenticated ? "Connected" : "Not connected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            if viewModel.isAuthenticated {
                // Sign out + Refresh buttons
                HStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await viewModel.refresh()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Refresh")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "1A1A1A"), Color(hex: "2D2D2D")],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        viewModel.signOut()
                    }) {
                        Text("Sign Out")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // Sign in button
                Button(action: {
                    viewModel.signIn()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 15, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                        Text("Connect Google Calendar")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "1A1A1A"), Color(hex: "2D2D2D")],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            }
            
            // EventKit Status
            HStack {
                Text("ICLOUD CALENDAR")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.eventKitAuthorized ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                        }
                        .shadow(color: viewModel.eventKitAuthorized ? .green.opacity(0.5) : .orange.opacity(0.4), radius: 4)
                    
                    Text(viewModel.eventKitAuthorized ? "Connected" : "Needs access")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 10)
            
            // iCloud Calendar section
            if viewModel.eventKitAuthorized {
                // Settings button to choose calendars
                Button(action: {
                    showingCalendarSettings = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Choose Calendars")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    Task {
                        await viewModel.requestEventKitAccess()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 14, weight: .medium))
                        Text("Connect iCloud Calendars")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .glassCard()
    }
    
    // MARK: - Today Summary Section
    
    private var todaySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("TODAY", systemImage: "sun.max.fill")
                    .font(.custom("HelveticaNeue-Bold", size: 10))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                    .labelStyle(.titleOnly)
                
                Spacer()
                
                if let weather = viewModel.weather {
                    HStack(spacing: 6) {
                        Image(systemName: weather.symbolName)
                            .font(.system(size: 14, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.blue)
                        Text(weather.temperatureFormatted)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.primary)
                }
            }
            
            markdownText(viewModel.todaySummary?.summary ?? "Loading...", fontSize: 15)
            
            if let eventCount = viewModel.todaySummary?.eventCount, eventCount > 0 {
                Text("\(eventCount) events")
                    .font(.custom("HelveticaNeue", size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
    
    // MARK: - Week Summary Section
    
    private var weekSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WEEK AHEAD")
                .font(.custom("HelveticaNeue-Bold", size: 10))
                .foregroundStyle(.secondary)
                .tracking(1)
            
            markdownText(viewModel.weekSummary?.summaryLarge ?? "Loading...", fontSize: 15)
            
            if let eventCount = viewModel.weekSummary?.eventCount, eventCount > 0 {
                Text("\(eventCount) events this week")
                    .font(.custom("HelveticaNeue", size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
    
    // MARK: - Markdown Helper
    
    @ViewBuilder
    private func markdownText(_ text: String, fontSize: CGFloat) -> some View {
        if let attributed = try? AttributedString(markdown: text) {
            Text(attributed)
                .font(.system(size: fontSize, weight: .regular, design: .default))
                .foregroundStyle(.primary)
                .lineSpacing(5)
        } else {
            Text(text)
                .font(.system(size: fontSize, weight: .regular, design: .default))
                .foregroundStyle(.primary)
                .lineSpacing(5)
        }
    }
    
    // MARK: - Error Message
    
    private func errorMessageView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Error")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
            }
            
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            
            Button(action: {
                viewModel.errorMessage = nil
            }) {
                Text("Dismiss")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.orange.opacity(0.1))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        }
    }
    
    // MARK: - Weather Status Section
    
    private var weatherStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WEATHER")
                .font(.custom("HelveticaNeue-Bold", size: 10))
                .foregroundStyle(.secondary)
                .tracking(1)
            
            HStack {
                Text(viewModel.weatherStatus)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.testWeather()
                    }
                }) {
                    Text("Test")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            
            if viewModel.weatherStatus.contains("placeholder") || viewModel.weatherStatus.contains("not working") {
                Text("To fix: Go to Apple Developer Portal → Identifiers → Your App IDs → Enable WeatherKit capability")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .glassCard()
    }
    
    // MARK: - Widget Studio Section
    
    private var widgetStudioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WIDGET APPEARANCE")
                .font(.custom("HelveticaNeue-Bold", size: 10))
                .foregroundStyle(.secondary)
                .tracking(1)
            
            Button {
                showingWidgetStudio = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Widget Studio")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        
                        Text("Customize colors, themes & photo backgrounds")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .glassCard()
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Calendar Status Section
    
    private var calendarStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CALENDARS")
                .font(.custom("HelveticaNeue-Bold", size: 10))
                .foregroundStyle(.secondary)
                .tracking(1)
            
            ForEach(ClientCalendars.all, id: \.id) { calendar in
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(calendar.source == .google ? Color.blue : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(calendar.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Text(calendar.source == .google ? "Google" : "iCloud")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(.vertical, 4)
                
                if calendar.id != ClientCalendars.all.last?.id {
                    Divider()
                        .opacity(0.5)
                }
            }
        }
        .padding(16)
        .glassCard()
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.primary)
                
                Text("Refreshing...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
    }
}

// MARK: - Glass Card Modifier

extension View {
    func glassCard() -> some View {
        self
            .background {
                ZStack {
                    // Base glass material
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Inner highlight gradient for depth
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.overlay)
                }
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                .shadow(color: .white.opacity(0.8), radius: 2, x: -1, y: -1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            }
    }
}

// MARK: - View Model

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var todaySummary: TodaySummary?
    @Published var weekSummary: WeekSummary?
    @Published var weather: WeatherData?
    @Published var events: [ScheduleEvent]?
    @Published var weatherStatus: String = "Not fetched"
    @Published var lastRefresh: Date?
    @Published var isLoading = false
    @Published var isAuthenticated = false
    @Published var eventKitAuthorized = false
    @Published var errorMessage: String?
    
    private let googleAPI = GoogleCalendarAPI.shared
    let calendarService = CalendarService.shared  // Exposed for calendar list access
    private let weatherService = WeatherService.shared
    private let geminiSummarizer = GeminiSummarizer.shared
    private let store = AppGroupStore.shared
    @available(iOSApplicationExtension, unavailable)
    private let backgroundScheduler = BackgroundScheduler.shared
    
    init() {
        print("🟢 [ViewModel] INIT CALLED")
        updateAuthStatus()
        print("🟢 [ViewModel] INIT COMPLETE")
    }
    
    func updateAuthStatus() {
        isAuthenticated = googleAPI.isAuthenticated
        
        let ekStatus = EKEventStore.authorizationStatus(for: .event)
        print("🔍 [ViewModel] EKEventStore status: \(ekStatus.rawValue)")
        print("🔍 [ViewModel] calendarService.isEventKitAuthorized: \(calendarService.isEventKitAuthorized)")
        
        eventKitAuthorized = calendarService.isEventKitAuthorized
        print("🔍 [ViewModel] eventKitAuthorized set to: \(eventKitAuthorized)")
    }
    
    func loadCachedData() {
        todaySummary = store.loadTodaySummary()
        weekSummary = store.loadWeekSummary()
        weather = store.loadWeather()
        events = store.loadEvents()
        lastRefresh = store.loadLastRefreshTime()
        updateAuthStatus()
    }
    
    func signIn() {
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        Task {
            do {
                try await googleAPI.authenticate(from: window)
                updateAuthStatus()
                await refresh()
            } catch {
                print("Sign in error: \(error)")
            }
        }
        #elseif os(macOS)
        // macOS: Get the key window for authentication
        let anchor: ASPresentationAnchor = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first ?? NSWindow()
        
        Task {
            do {
                try await googleAPI.authenticate(from: anchor)
                updateAuthStatus()
                await refresh()
            } catch {
                print("Sign in error: \(error)")
            }
        }
        #endif
    }
    
    func signOut() {
        googleAPI.signOut()
        updateAuthStatus()
        todaySummary = nil
        weekSummary = nil
        store.clearAll()
    }
    
    func requestEventKitAccess() async {
        print("📅 [ViewModel] requestEventKitAccess() called")
        
        let status = EKEventStore.authorizationStatus(for: .event)
        print("📅 [ViewModel] Current status: \(status.rawValue)")
        
        // If already authorized, just refresh
        if calendarService.isEventKitAuthorized {
            print("📅 [ViewModel] Already authorized, refreshing...")
            eventKitAuthorized = true
            await refresh()
            return
        }
        
        // Create fresh store and request
        let store = EKEventStore()
        
        if #available(iOS 17.0, *) {
            print("📅 [ViewModel] Requesting full access (iOS 17+)...")
            do {
                let granted = try await store.requestFullAccessToEvents()
                print("📅 [ViewModel] Result: \(granted)")
                eventKitAuthorized = granted
                if granted {
                    await refresh()
                }
            } catch {
                print("📅 [ViewModel] Error: \(error)")
                errorMessage = error.localizedDescription
            }
        } else {
            print("📅 [ViewModel] Requesting access (legacy)...")
            let granted = await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
            print("📅 [ViewModel] Result: \(granted)")
            eventKitAuthorized = granted
            if granted {
                await refresh()
            }
        }
    }
    
    func refresh() async {
        isLoading = true
        errorMessage = nil
        weatherStatus = "Fetching..."
        
        do {
            print("🔄 Starting refresh...")
            #if targetEnvironment(macCatalyst) || os(macOS)
            // macOS: Always perform full refresh
            try await backgroundScheduler.performFullRefresh()
            print("✅ Refresh completed, loading cached data...")
            loadCachedData()
            #else
            // iOS
            if #available(iOSApplicationExtension, *) {
                // In widget extension, just load cached data
                loadCachedData()
            } else {
                try await backgroundScheduler.performFullRefresh()
                print("✅ Refresh completed, loading cached data...")
                loadCachedData()
            }
            #endif
            
            // Update weather status
            if let w = weather {
                if w.temperature == 72 && w.conditionDescription == "Clear" {
                    weatherStatus = "⚠️ Using placeholder (WeatherKit may not be enabled)"
                } else {
                    weatherStatus = "✅ \(w.temperatureFormatted)° \(w.conditionDescription)"
                }
            } else {
                weatherStatus = "❌ No weather data"
            }
            
            print("✅ Cached data loaded")
        } catch {
            print("❌ Refresh error: \(error)")
            errorMessage = "Failed to refresh: \(error.localizedDescription)"
            weatherStatus = "❌ Error: \(error.localizedDescription)"
        }
        
        isLoading = false
        print("✅ Loading state cleared")
    }
    
    func testWeather() async {
        weatherStatus = "Testing WeatherKit..."
        do {
            let weather = try await weatherService.fetchWeather()
            if weather.temperature == 72 && weather.conditionDescription == "Clear" {
                weatherStatus = "⚠️ Got placeholder - WeatherKit not working"
            } else {
                weatherStatus = "✅ WeatherKit works! \(weather.temperatureFormatted)° \(weather.conditionDescription)"
                self.weather = weather
            }
        } catch {
            weatherStatus = "❌ WeatherKit error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Color Helpers

private extension Color {
    /// Initialize Color from hex string (for main app target)
    /// Note: Widget extension has its own definition in AMFScheduleWidget.swift
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

