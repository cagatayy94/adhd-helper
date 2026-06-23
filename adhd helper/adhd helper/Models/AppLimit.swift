import Foundation
import FamilyControls

struct AppLimit: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var selection: FamilyActivitySelection
    var threshold: String // "1m", "15m", "30m", "1h", "2h", "3h"
    var isActive: Bool = true
}
