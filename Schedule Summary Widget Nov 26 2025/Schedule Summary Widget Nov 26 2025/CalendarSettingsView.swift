//
//  CalendarSettingsView.swift
//  AMF Schedule
//
//  Calendar selection settings
//

import SwiftUI
import EventKit
import Combine

struct CalendarSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CalendarSettingsViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // Google Calendars Section
                Section {
                    ForEach(viewModel.googleCalendars, id: \.id) { calendar in
                        CalendarToggleRow(
                            name: calendar.name,
                            source: "Google",
                            color: calendarColor(for: calendar.name),
                            isEnabled: viewModel.isCalendarEnabled(calendar.name),
                            onToggle: { enabled in
                                viewModel.setCalendarEnabled(calendar.name, enabled: enabled)
                            }
                        )
                    }
                } header: {
                    Label("Google Calendars", systemImage: "g.circle.fill")
                }
                
                // iCloud Calendars Section
                Section {
                    if viewModel.iCloudCalendars.isEmpty {
                        Text("No iCloud-only calendars found")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(viewModel.iCloudCalendars, id: \.self) { calendarName in
                            CalendarToggleRow(
                                name: calendarName,
                                source: "iCloud",
                                color: calendarColor(for: calendarName),
                                isEnabled: viewModel.isCalendarEnabled(calendarName),
                                onToggle: { enabled in
                                    viewModel.setCalendarEnabled(calendarName, enabled: enabled)
                                }
                            )
                        }
                    }
                } header: {
                    Label("iCloud Calendars", systemImage: "icloud.fill")
                } footer: {
                    Text("These are calendars stored in iCloud or on your device (not synced from Google).")
                }
            }
#if os(iOS) || os(tvOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .navigationTitle("Calendar Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // Calendar color matching the widget colors
    private func calendarColor(for name: String) -> Color {
        switch name.lowercased() {
        case "theo": return Color(red: 0, green: 122/255, blue: 255/255) // Blue
        case "adam": return Color(red: 255/255, green: 149/255, blue: 0) // Orange
        case "hudson": return Color(red: 52/255, green: 199/255, blue: 89/255) // Green
        case "tom": return Color(red: 255/255, green: 59/255, blue: 48/255) // Red
        case "ruby": return Color(red: 175/255, green: 82/255, blue: 222/255) // Purple
        case "conall": return Color(red: 255/255, green: 45/255, blue: 85/255) // Pink
        case "leon": return Color(red: 88/255, green: 86/255, blue: 214/255) // Indigo
        case "jack × theo", "jack x theo": return Color(red: 0, green: 199/255, blue: 190/255) // Teal
        default: return Color(red: 142/255, green: 142/255, blue: 147/255) // Gray
        }
    }
}

// MARK: - Calendar Toggle Row

struct CalendarToggleRow: View {
    let name: String
    let source: String
    let color: Color
    let isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                
                Text(source)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
        }
    }
}

// MARK: - View Model

@MainActor
class CalendarSettingsViewModel: ObservableObject {
    @Published var googleCalendars: [ClientCalendar] = []
    @Published var iCloudCalendars: [String] = []
    @Published var enabledCalendars: Set<String> = []
    
    private let store = AppGroupStore.shared
    private let eventStore = EKEventStore()
    
    init() {
        loadCalendars()
        loadPreferences()
    }
    
    private func loadCalendars() {
        // Load configured Google calendars (these are pre-defined)
        googleCalendars = ClientCalendars.googleCalendars
        
        // Load iCloud calendars from device - EXCLUDE Google calendars
        // Google calendars synced to iPhone appear with source type containing "google" or "gmail"
        let allCalendars = eventStore.calendars(for: .event)
        
        // Get the names of our configured Google calendars to exclude them
        let googleCalendarNames = Set(ClientCalendars.googleCalendars.map { $0.name.lowercased() })
        
        iCloudCalendars = allCalendars
            .filter { calendar in
                // Exclude calendars from Google sources
                let sourceName = calendar.source.title.lowercased()
                let isGoogleSource = sourceName.contains("google") || 
                                     sourceName.contains("gmail") ||
                                     sourceName.contains("@gmail") ||
                                     sourceName.contains("@google")
                
                // Exclude if it matches one of our configured Google calendar names
                let isConfiguredGoogle = googleCalendarNames.contains(calendar.title.lowercased())
                
                // Only include if it's NOT a Google source and NOT a configured Google calendar
                return !isGoogleSource && !isConfiguredGoogle
            }
            .map { $0.title }
            .sorted()
        
        print("📅 [Settings] Found \(iCloudCalendars.count) iCloud-only calendars: \(iCloudCalendars)")
        print("📅 [Settings] Google calendars: \(googleCalendars.map { $0.name })")
    }
    
    private func loadPreferences() {
        // Load saved preferences, default to all enabled
        if let saved = store.loadEnabledCalendars() {
            enabledCalendars = saved
        } else {
            // Default: enable all Google calendars (by name for consistency) + JACK × THEO
            enabledCalendars = Set(googleCalendars.map { $0.name })
            enabledCalendars.insert("JACK × THEO")
        }
        print("📅 [Settings] Enabled calendars: \(enabledCalendars)")
    }
    
    func isCalendarEnabled(_ id: String) -> Bool {
        // Check by both name and the id itself for flexibility
        enabledCalendars.contains(id)
    }
    
    func setCalendarEnabled(_ id: String, enabled: Bool) {
        if enabled {
            enabledCalendars.insert(id)
        } else {
            enabledCalendars.remove(id)
        }
        print("📅 [Settings] Toggled '\(id)' to \(enabled)")
    }
    
    func save() {
        store.saveEnabledCalendars(enabledCalendars)
        print("📅 [Settings] Saved \(enabledCalendars.count) enabled calendars")
    }
}

#Preview {
    CalendarSettingsView()
}

