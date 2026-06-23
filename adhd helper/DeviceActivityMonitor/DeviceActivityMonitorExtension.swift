//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitor
//

import DeviceActivity
import ManagedSettings
import Foundation
import FamilyControls

// Struct must match the one defined in the main app to decode the stored limits
struct AppLimit: Identifiable, Codable {
    var id = UUID()
    var title: String
    var selection: FamilyActivitySelection
    var threshold: String
    var isActive: Bool
}

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let appGroupSuiteName = "group.com.caca.adhd-helper"
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Retrieve limits from the shared App Group UserDefaults
        guard let defaults = UserDefaults(suiteName: appGroupSuiteName),
              let data = defaults.data(forKey: "ADHDAppLimits"),
              let limits = try? JSONDecoder().decode([AppLimit].self, from: data) else {
            return
        }
        
        // Find the limit associated with this activity event (matched by limit ID)
        guard let limit = limits.first(where: { $0.id.uuidString == activity.rawValue }) else {
            return
        }
        
        // Apply native iOS Shield in an isolated named store (so other limits don't overlap)
        let store = ManagedSettingsStore(named: .init(activity.rawValue))
        store.shield.applications = limit.selection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(limit.selection.categoryTokens)
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        let store = ManagedSettingsStore(named: .init(activity.rawValue))
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
}
