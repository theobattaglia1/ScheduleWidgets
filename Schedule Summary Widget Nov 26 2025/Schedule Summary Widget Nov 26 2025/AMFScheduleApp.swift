//
//  AMFScheduleApp.swift
//  AMF Schedule
//
//  Main app entry point with background task registration and deep link handling
//

#if os(iOS)
import SwiftUI
import BackgroundTasks
import EventKit
import UIKit

@main
struct AMFScheduleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var router = AppRouter()
    @StateObject private var viewModel = ScheduleViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(viewModel)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("📱 App became active - checking if refresh needed")
                Task {
                    await refreshIfStale()
                }
            case .background:
                print("📱 App entered background - scheduling refresh")
                BackgroundScheduler.shared.scheduleAppRefresh()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
    
    /// Handle incoming deep link URLs
    private func handleDeepLink(_ url: URL) {
        print("🔗 [App] Received deep link: \(url)")
        router.handleDeepLink(url)
    }
    
    /// Always refresh when app opens (most reliable approach)
    private func refreshIfStale() async {
        let store = AppGroupStore.shared
        
        // Check how old the data is
        if let lastRefresh = store.loadLastRefreshTime() {
            let age = Date().timeIntervalSince(lastRefresh)
            let ageMinutes = Int(age / 60)
            print("📱 Data is \(ageMinutes) minutes old")
        } else {
            print("📱 No previous refresh recorded")
        }
        
        // Always refresh when app opens - most reliable approach
        print("📱 Auto-refreshing on app open...")
        do {
            try await BackgroundScheduler.shared.performFullRefresh()
            print("📱 ✅ Auto-refresh completed")
            // Reload cached data in view model
            await MainActor.run {
                viewModel.loadCachedData()
            }
        } catch {
            print("📱 ⚠️ Auto-refresh failed: \(error)")
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register background tasks
        BackgroundScheduler.shared.registerBackgroundTasks()
        
        // Schedule initial refresh
        BackgroundScheduler.shared.scheduleAppRefresh()
        
        // Request location permission for weather
        WeatherService.shared.requestLocationPermission()
        
        // Request calendar access IMMEDIATELY on launch
        // This helps ensure iOS shows the permission dialog
        requestCalendarAccessOnLaunch()
        
        return true
    }
    
    private func requestCalendarAccessOnLaunch() {
        let store = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .event)
        
        print("🚀 [AppDelegate] Calendar status on launch: \(status.rawValue)")
        
        // Only request if not determined - this is when iOS will show the dialog
        if status == .notDetermined {
            print("🚀 [AppDelegate] Status is notDetermined - requesting access NOW")
            
            if #available(iOS 17.0, *) {
                store.requestFullAccessToEvents { granted, error in
                    print("🚀 [AppDelegate] Permission result: granted=\(granted), error=\(String(describing: error))")
                }
            } else {
                store.requestAccess(to: .event) { granted, error in
                    print("🚀 [AppDelegate] Permission result: granted=\(granted), error=\(String(describing: error))")
                }
            }
        } else {
            print("🚀 [AppDelegate] Status is \(status.rawValue) - not requesting (already determined)")
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Refresh data if stale when app becomes active
        BackgroundScheduler.shared.handleAppBecameActive()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Schedule background refresh
        BackgroundScheduler.shared.handleAppEnteredBackground()
    }
}
#elseif os(macOS)
import SwiftUI
import EventKit

@main
struct AMFScheduleApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var router = AppRouter()
    @StateObject private var viewModel = ScheduleViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(viewModel)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onAppear {
                    // Refresh data when app opens
                    Task {
                        await refreshIfStale()
                    }
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("🖥️ App became active - refreshing data")
                Task {
                    await refreshIfStale()
                }
            case .background, .inactive:
                break
            @unknown default:
                break
            }
        }
        .commands {
            // Add menu commands if needed
        }
    }
    
    /// Handle incoming deep link URLs
    private func handleDeepLink(_ url: URL) {
        print("🔗 [App] Received deep link: \(url)")
        router.handleDeepLink(url)
    }
    
    /// Refresh data when app opens or becomes active
    private func refreshIfStale() async {
        let store = AppGroupStore.shared
        
        // Check how old the data is
        if let lastRefresh = store.loadLastRefreshTime() {
            let age = Date().timeIntervalSince(lastRefresh)
            let ageMinutes = Int(age / 60)
            print("🖥️ Data is \(ageMinutes) minutes old")
        } else {
            print("🖥️ No previous refresh recorded")
        }
        
        // Always refresh when app opens - most reliable approach
        print("🖥️ Auto-refreshing on app open...")
        do {
            try await BackgroundScheduler.shared.performFullRefresh()
            print("🖥️ ✅ Auto-refresh completed")
            // Reload cached data in view model
            await MainActor.run {
                viewModel.loadCachedData()
            }
        } catch {
            print("🖥️ ⚠️ Auto-refresh failed: \(error)")
        }
    }
}
#endif // os(iOS)

