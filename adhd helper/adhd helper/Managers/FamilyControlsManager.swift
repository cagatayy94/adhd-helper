import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings
import Combine

@MainActor
class FamilyControlsManager: ObservableObject {
    static let shared = FamilyControlsManager()
    
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    
    var isAuthorized: Bool {
        authorizationStatus == .approved
    }
    
    init() {
        #if targetEnvironment(simulator)
        self.authorizationStatus = .approved
        #else
        self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        #endif
    }
    
    func requestAuthorization() async {
        #if targetEnvironment(simulator)
        self.authorizationStatus = .approved
        #else
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        } catch {
            print("Failed to request Family Controls authorization: \(error.localizedDescription)")
        }
        #endif
    }
    
    func checkStatus() {
        #if targetEnvironment(simulator)
        self.authorizationStatus = .approved
        #else
        self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        #endif
    }
    
    func startMonitoring(limit: AppLimit) {
        guard limit.isActive else { return }
        
        let center = DeviceActivityCenter()
        
        // Schedule: daily monitoring starting from current time to ensure it is active immediately today
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: Date())
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let minutes = thresholdToMinutes(limit.threshold)
        let threshold = DateComponents(minute: minutes)
        
        let event = DeviceActivityEvent(
            applications: limit.selection.applicationTokens,
            categories: limit.selection.categoryTokens,
            webDomains: limit.selection.webDomainTokens,
            threshold: threshold
        )
        
        let activityName = DeviceActivityName(limit.id.uuidString)
        let eventName = DeviceActivityEvent.Name(limit.id.uuidString)
        
        do {
            center.stopMonitoring([activityName])
            try center.startMonitoring(activityName, during: schedule, events: [eventName: event])
            print("Successfully started monitoring for limit \(limit.title) (threshold: \(minutes)m)")
        } catch {
            print("Error starting monitoring: \(error)")
        }
    }
    
    func stopMonitoring(limit: AppLimit) {
        let center = DeviceActivityCenter()
        let activityName = DeviceActivityName(limit.id.uuidString)
        center.stopMonitoring([activityName])
        print("Stopped monitoring for limit \(limit.title)")
    }
    
    private func thresholdToMinutes(_ threshold: String) -> Int {
        switch threshold {
        case "1m": return 1
        case "15m": return 15
        case "30m": return 30
        case "1h": return 60
        case "2h": return 120
        case "3h": return 180
        default: return 30
        }
    }
}
