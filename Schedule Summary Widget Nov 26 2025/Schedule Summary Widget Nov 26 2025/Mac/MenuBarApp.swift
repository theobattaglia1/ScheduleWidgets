//
//  MenuBarApp.swift
//  Schedule Summary Widget
//
//  Mac Menu Bar Companion App
//  Shows next event, countdown, and provides quick actions
//  - Next event display in menu bar
//  - Dropdown with today's schedule
//  - Quick Add event
//  - Person filters
//  - Join meeting links
//

#if os(macOS)
import SwiftUI
import AppKit
import Combine

// MARK: - Menu Bar Manager

@MainActor
class MenuBarManager: ObservableObject {
    static let shared = MenuBarManager()
    
    @Published var nextEvent: ScheduleEvent?
    @Published var todayEvents: [ScheduleEvent] = []
    @Published var isLoading = false
    @Published var lastRefresh: Date?
    
    private let store = AppGroupStore.shared
    
    private init() {
        loadData()
    }
    
    func loadData() {
        isLoading = true
        
        if let events = store.loadEvents() {
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            
            todayEvents = events
                .filter { $0.startDate >= today && $0.startDate < tomorrow }
                .sorted { $0.startDate < $1.startDate }
            
            nextEvent = todayEvents.first { !$0.isPast }
        }
        
        lastRefresh = store.loadLastRefreshTime()
        isLoading = false
    }
    
    func refresh() async {
        loadData()
    }
    
    var menuBarTitle: String {
        guard let event = nextEvent else {
            return "✓ Clear"
        }
        
        let timeUntil = event.startDate.timeIntervalSince(Date())
        let minutes = Int(timeUntil / 60)
        
        if minutes < 0 {
            return "🔴 \(event.clientName) Now"
        } else if minutes < 60 {
            return "\(event.clientName) \(event.formattedTime) (\(minutes)m)"
        } else {
            let hours = minutes / 60
            return "\(event.clientName) \(event.formattedTime) (\(hours)h)"
        }
    }
}

// MARK: - Menu Bar View

struct MenuBarContentView: View {
    @ObservedObject var manager = MenuBarManager.shared
    @State private var selectedPerson: String? = nil
    @State private var showQuickAdd = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
                .padding(.vertical, 8)
            
            // Today's events
            eventsSection
            
            Divider()
                .padding(.vertical, 8)
            
            // Actions
            actionsSection
        }
        .padding(12)
        .frame(width: 320)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TODAY")
                    .font(.custom("HelveticaNeue-Bold", size: 10))
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Spacer()
                
                Text(formattedDate)
                    .font(.custom("HelveticaNeue", size: 11))
                    .foregroundColor(.secondary)
            }
            
            // Next event highlight
            if let next = manager.nextEvent {
                HStack(spacing: 12) {
                    // Person badge
                    Text(initial(for: next.clientName))
                        .font(.custom("HelveticaNeue-Bold", size: 14))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(color(for: next.clientName))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(next.title)
                            .font(.custom("HelveticaNeue-Medium", size: 13))
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Text(next.formattedTime)
                                .font(.custom("HelveticaNeue", size: 11))
                                .foregroundColor(.secondary)
                            
                            if next.isHappeningNow {
                                Text("NOW")
                                    .font(.custom("HelveticaNeue-Bold", size: 8))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(3)
                            } else {
                                Text("in \(timeUntil(next.startDate))")
                                    .font(.custom("HelveticaNeue", size: 11))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Join button if there's a meeting link
                    if let location = next.location, location.contains("http") {
                        Button("Join") {
                            if let url = URL(string: location) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(10)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(10)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All clear for today!")
                        .font(.custom("HelveticaNeue", size: 12))
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.08))
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Events Section
    
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Person filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(uniquePeople, id: \.self) { person in
                        Button {
                            if selectedPerson == person {
                                selectedPerson = nil
                            } else {
                                selectedPerson = person
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(color(for: person))
                                    .frame(width: 8, height: 8)
                                Text(person)
                                    .font(.custom("HelveticaNeue", size: 10))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedPerson == person ? color(for: person).opacity(0.2) : Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if selectedPerson != nil {
                        Button {
                            selectedPerson = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Events list
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(filteredEvents) { event in
                        MenuBarEventRow(event: event)
                    }
                    
                    if filteredEvents.isEmpty {
                        Text(selectedPerson != nil ? "No events for \(selectedPerson!)" : "No events today")
                            .font(.custom("HelveticaNeue", size: 11))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 20)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    showQuickAdd = true
                } label: {
                    Label("Quick Add", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button {
                    Task {
                        await manager.refresh()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button {
                    // Open main app
                    if let url = URL(string: "amfschedule://") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Open App", systemImage: "arrow.up.forward.square")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Last refresh indicator
            if let lastRefresh = manager.lastRefresh {
                Text("Updated \(lastRefresh.formatted(date: .omitted, time: .shortened))")
                    .font(.custom("HelveticaNeue", size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    private var uniquePeople: [String] {
        let priority = ["Theo", "Adam", "Hudson", "Tom", "Ruby", "Conall", "Leon"]
        let people = Set(manager.todayEvents.map { $0.clientName })
        return people.sorted { p1, p2 in
            let idx1 = priority.firstIndex(of: p1) ?? 999
            let idx2 = priority.firstIndex(of: p2) ?? 999
            return idx1 < idx2
        }
    }
    
    private var filteredEvents: [ScheduleEvent] {
        if let person = selectedPerson {
            return manager.todayEvents.filter { $0.clientName == person }
        }
        return manager.todayEvents
    }
    
    private func timeUntil(_ date: Date) -> String {
        let minutes = Int(date.timeIntervalSince(Date()) / 60)
        if minutes < 0 { return "now" }
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }
    
    private func initial(for name: String) -> String {
        switch name.lowercased() {
        case "theo": return "T"
        case "adam": return "A"
        case "hudson": return "H"
        case "tom": return "TM"
        case "ruby": return "R"
        case "conall": return "C"
        case "leon": return "L"
        case "jack × theo", "jack x theo": return "J×T"
        default: return String(name.prefix(1)).uppercased()
        }
    }
    
    private func color(for name: String) -> Color {
        switch name.lowercased() {
        case "theo": return Color(red: 0, green: 122/255, blue: 1)
        case "adam": return Color(red: 1, green: 149/255, blue: 0)
        case "hudson": return Color(red: 52/255, green: 199/255, blue: 89/255)
        case "tom": return Color(red: 1, green: 59/255, blue: 48/255)
        case "ruby": return Color(red: 175/255, green: 82/255, blue: 222/255)
        case "conall": return Color(red: 1, green: 45/255, blue: 85/255)
        case "leon": return Color(red: 88/255, green: 86/255, blue: 214/255)
        case "jack × theo", "jack x theo": return Color(red: 0, green: 199/255, blue: 190/255)
        default: return Color(red: 142/255, green: 142/255, blue: 147/255)
        }
    }
}

// MARK: - Menu Bar Event Row

struct MenuBarEventRow: View {
    let event: ScheduleEvent
    
    var body: some View {
        HStack(spacing: 8) {
            // Time
            Text(event.isAllDay ? "All day" : event.formattedTime)
                .font(.custom("HelveticaNeue", size: 10))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            // Color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(color(for: event.clientName))
                .frame(width: 3, height: 18)
            
            // Title
            Text(event.title)
                .font(.custom("HelveticaNeue", size: 11))
                .foregroundColor(event.isPast ? .secondary : .primary)
                .lineLimit(1)
            
            Spacer()
            
            // Status indicators
            if event.isHappeningNow {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
            }
            
            // Client badge
            Text(event.clientName)
                .font(.custom("HelveticaNeue", size: 9))
                .foregroundColor(color(for: event.clientName))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(event.isHappeningNow ? Color.red.opacity(0.05) : Color.clear)
        .cornerRadius(6)
        .opacity(event.isPast ? 0.5 : 1)
    }
    
    private func color(for name: String) -> Color {
        switch name.lowercased() {
        case "theo": return Color(red: 0, green: 122/255, blue: 1)
        case "adam": return Color(red: 1, green: 149/255, blue: 0)
        case "hudson": return Color(red: 52/255, green: 199/255, blue: 89/255)
        case "tom": return Color(red: 1, green: 59/255, blue: 48/255)
        case "ruby": return Color(red: 175/255, green: 82/255, blue: 222/255)
        case "conall": return Color(red: 1, green: 45/255, blue: 85/255)
        case "leon": return Color(red: 88/255, green: 86/255, blue: 214/255)
        case "jack × theo", "jack x theo": return Color(red: 0, green: 199/255, blue: 190/255)
        default: return Color(red: 142/255, green: 142/255, blue: 147/255)
        }
    }
}

// MARK: - Quick Add Sheet

struct QuickAddView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var selectedPerson = "Theo"
    @State private var startTime = Date()
    @State private var duration = 60 // minutes
    
    let people = ["Theo", "Adam", "Hudson", "Tom", "Ruby", "Conall", "Leon"]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Add Event")
                .font(.headline)
            
            TextField("Event title", text: $title)
                .textFieldStyle(.roundedBorder)
            
            Picker("Person", selection: $selectedPerson) {
                ForEach(people, id: \.self) { person in
                    Text(person).tag(person)
                }
            }
            .pickerStyle(.segmented)
            
            DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
            
            Picker("Duration", selection: $duration) {
                Text("30 min").tag(30)
                Text("1 hour").tag(60)
                Text("1.5 hours").tag(90)
                Text("2 hours").tag(120)
            }
            .pickerStyle(.segmented)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add Event") {
                    addEvent()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
    
    private func addEvent() {
        // This would integrate with your calendar service
        // For now, just log the intent
        print("Would add: \(title) for \(selectedPerson) at \(startTime) for \(duration) minutes")
    }
}

#endif

