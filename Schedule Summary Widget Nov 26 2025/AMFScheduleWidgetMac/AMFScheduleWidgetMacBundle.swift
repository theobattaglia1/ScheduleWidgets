//
//  AMFScheduleWidgetMacBundle.swift
//  AMFScheduleWidgetMAC
//
//  Native macOS Widget Extension Bundle
//  This runs as a true macOS widget (not Catalyst)
//

import WidgetKit
import SwiftUI

#if os(macOS)
@main
struct AMFScheduleWidgetMACBundle: WidgetBundle {
    var body: some Widget {
        // Mac-specific widgets only
        AMFAmbientAgendaWidget()
        AMFNextUpWidget()
        AMFInteractiveScheduleWidget()
    }
}
#endif

