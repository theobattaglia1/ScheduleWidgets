//
//  AMFScheduleWidgetBundle.swift
//  AMFScheduleWidget
//
//  Widget bundle containing all schedule widgets for iPhone, iPad, and Mac
//
//  Widget Types:
//  - AMFScheduleWidget: Main configurable widget (all platforms)
//  - AMFLockScreenWidget: Lock screen accessories (iOS)
//  - AMFDayboardWidget: iPad Extra Large dashboard
//  - AMFAmbientAgendaWidget: Mac desktop ambient agenda
//  - AMFNextUpWidget: Mac notification center quick glance
//  - AMFInteractiveScheduleWidget: Widget with interactive controls
//

import WidgetKit
import SwiftUI

// This bundle is for iOS/iPad only - macOS has its own bundle in AMFScheduleWidgetMacBundle.swift
#if !os(macOS) && !targetEnvironment(macCatalyst)
@main
struct AMFScheduleWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Main schedule widget - all platforms, all sizes
        // Note: AMFScheduleWidget is defined in AMFScheduleWidget.swift
        AMFScheduleWidget()
        
        #if os(iOS) && !targetEnvironment(macCatalyst)
        // Lock screen widgets - iPhone and iPad only (not Mac)
        AMFLockScreenWidget()
        
        // iPad-specific Dayboard widget
        AMFDayboardWidget()
        #endif
        
        // Note: Interactive widget and Mac-specific widgets are in AMFScheduleWidgetMacBundle
    }
}
#endif
